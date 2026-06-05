import Foundation
import CoreLocation
import Combine

/// Fetches the current local weather from OpenWeather based on CoreLocation, and
/// maps it to one of our `WeatherKind` conditions. Drives the "auto" sticker.
@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    enum Status: Equatable { case idle, locating, fetching, ready, denied, failed }

    @Published private(set) var condition: WeatherKind?
    @Published private(set) var status: Status = .idle
    @Published private(set) var lastUpdated: Date?

    private let apiKey = "557ffcb121ddfab0c7f9bb208d9df906"
    private let manager = CLLocationManager()
    private var started = false
    private var refreshTimer: Timer?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Begin (idempotent): request authorization, locate, and refresh every 30 min.
    func start() {
        guard !started else { return }
        started = true
        requestAuthAndLocate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.locateNow() }
        }
    }

    func refresh() { locateNow() }

    private func requestAuthAndLocate() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()   // delegate callback will locate
        case .authorizedAlways, .authorizedWhenInUse:
            locateNow()
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .denied
        }
    }

    private func locateNow() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            status = .locating
            manager.requestLocation()
        case .denied, .restricted:
            status = .denied
        default:
            break
        }
    }

    private func fetchWeather(lat: Double, lon: Double) async {
        var comps = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        comps.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "appid", value: apiKey),
            .init(name: "units", value: "metric")
        ]
        guard let url = comps.url else { status = .failed; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OWResponse.self, from: data)
            if let w = decoded.weather.first {
                condition = Self.map(id: w.id, windSpeed: decoded.wind?.speed ?? 0)
                lastUpdated = Date()
                status = .ready
            } else {
                status = .failed
            }
        } catch {
            status = .failed
        }
    }

    /// Maps an OpenWeather condition id (+ wind speed m/s) to a sticker kind.
    static func map(id: Int, windSpeed: Double) -> WeatherKind {
        switch id {
        case 600..<700: return .snowy
        case 200..<600: return .rainy          // thunderstorm, drizzle, rain
        case 771, 781:  return .windy          // squall, tornado
        case 701..<800: return .cloudy         // mist / fog / haze / dust
        case 800:       return windSpeed >= 8 ? .windy : .sunny
        case 801, 802:  return .partlyCloudy
        case 803, 804:  return .cloudy
        default:        return .cloudy
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: self.locateNow()
            case .denied, .restricted: self.status = .denied
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let coord = loc.coordinate
        Task { @MainActor in
            self.status = .fetching
            await self.fetchWeather(lat: coord.latitude, lon: coord.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.status = .failed }
    }
}

private struct OWResponse: Decodable {
    struct W: Decodable { let id: Int }
    struct Wind: Decodable { let speed: Double? }
    let weather: [W]
    let wind: Wind?
}
