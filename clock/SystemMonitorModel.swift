import Foundation
import SwiftUI
import Combine

#if os(macOS)
import Darwin
import IOKit.ps
#endif

struct SystemMonitorSnapshot {
    var cpuText: String = "--"
    var memoryText: String = "--"
    var batteryText: String = "--"
    var networkText: String = "--"

    static let empty = SystemMonitorSnapshot()
}

final class SystemMonitorModel: ObservableObject {
    @Published var snapshot = SystemMonitorSnapshot.empty

    private var timer: Timer?

    #if os(macOS)
    private var previousCPU: CPUTicks?
    private var previousNetwork: NetworkSample?
    #endif

    func start() {
        stop()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.sample()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        #if os(macOS)
        snapshot = SystemMonitorSnapshot(
            cpuText: cpuText(),
            memoryText: memoryText(),
            batteryText: batteryText(),
            networkText: networkText()
        )
        #else
        snapshot = .empty
        #endif
    }
}

#if os(macOS)
private struct CPUTicks {
    var user: UInt64
    var system: UInt64
    var idle: UInt64
    var nice: UInt64

    var active: UInt64 { user + system + nice }
    var total: UInt64 { active + idle }
}

private struct NetworkSample {
    var date: Date
    var received: UInt64
    var sent: UInt64
}

private extension SystemMonitorModel {
    func cpuText() -> String {
        guard let current = readCPUTicks() else { return "--" }
        defer { previousCPU = current }
        guard let previous = previousCPU else { return "--" }

        let totalDelta = current.total > previous.total ? current.total - previous.total : 0
        let activeDelta = current.active > previous.active ? current.active - previous.active : 0
        guard totalDelta > 0 else { return "--" }

        let percent = Double(activeDelta) / Double(totalDelta) * 100
        return String(format: "%.0f%%", min(max(percent, 0), 100))
    }

    func memoryText() -> String {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "--" }

        let pageSize = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        let availablePages = UInt64(stats.free_count + stats.inactive_count)
        let available = min(total, availablePages * pageSize)
        let used = total > available ? total - available : 0
        let percent = total == 0 ? 0 : Double(used) / Double(total) * 100
        return String(format: "%.0f%%", min(max(percent, 0), 100))
    }

    func batteryText() -> String {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        guard let source = sources.first,
              let description = IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as? [String: Any] else {
            return "--"
        }

        let current = description[kIOPSCurrentCapacityKey as String] as? Int
        let max = description[kIOPSMaxCapacityKey as String] as? Int
        let charging = description[kIOPSIsChargingKey as String] as? Bool ?? false
        guard let current, let max, max > 0 else { return "--" }

        let percent = Int(round(Double(current) / Double(max) * 100))
        return charging ? "\(percent)% AC" : "\(percent)%"
    }

    func networkText() -> String {
        guard let current = readNetworkSample() else { return "--" }
        defer { previousNetwork = current }
        guard let previous = previousNetwork else { return "--" }

        let seconds = current.date.timeIntervalSince(previous.date)
        guard seconds > 0 else { return "--" }

        let down = current.received > previous.received ? Double(current.received - previous.received) / seconds : 0
        let up = current.sent > previous.sent ? Double(current.sent - previous.sent) / seconds : 0
        return "D \(formatBytes(down))/s  U \(formatBytes(up))/s"
    }

    func readCPUTicks() -> CPUTicks? {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount = mach_msg_type_number_t(0)
        var cpuCount = natural_t(0)

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &cpuInfo,
            &cpuInfoCount
        )
        guard result == KERN_SUCCESS, let cpuInfo else { return nil }
        defer {
            let size = vm_size_t(Int(cpuInfoCount) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), size)
        }

        var ticks = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        for cpu in 0..<Int(cpuCount) {
            let base = Int(CPU_STATE_MAX) * cpu
            ticks.user += UInt64(cpuInfo[base + Int(CPU_STATE_USER)])
            ticks.system += UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
            ticks.idle += UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)])
            ticks.nice += UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
        }
        return ticks
    }

    func readNetworkSample() -> NetworkSample? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return nil }
        defer { freeifaddrs(first) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var pointer: UnsafeMutablePointer<ifaddrs>? = first

        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let interface = current.pointee
            guard let address = interface.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_LINK),
                  interface.ifa_data != nil else { continue }

            let flags = Int32(interface.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }

            let data = interface.ifa_data.assumingMemoryBound(to: if_data.self).pointee
            received += UInt64(data.ifi_ibytes)
            sent += UInt64(data.ifi_obytes)
        }

        return NetworkSample(date: Date(), received: received, sent: sent)
    }

    func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB", bytes / 1_000_000)
        }
        if bytes >= 1_000 {
            return String(format: "%.0f KB", bytes / 1_000)
        }
        return String(format: "%.0f B", bytes)
    }
}
#endif
