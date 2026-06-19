import SwiftUI

struct PersistedColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    init(color: Color) {
        let c = color.platformRGBA
        self.red = c.r
        self.green = c.g
        self.blue = c.b
        self.alpha = c.a
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct PersistedClockStyle: Codable, Equatable {
    var family: ClockFontFamily
    var weight: ClockWeight
    var fontSize: CGFloat
    var tracking: CGFloat
    var stretchY: CGFloat
    var format: ClockFormat
    var color: PersistedColor
    var separator: SeparatorStyle
    var material: DigitMaterial
    var animation: DigitAnimation
    var numeralStyle: NumeralStyle

    init(
        family: ClockFontFamily,
        weight: ClockWeight,
        fontSize: CGFloat,
        tracking: CGFloat,
        stretchY: CGFloat,
        format: ClockFormat,
        color: PersistedColor,
        separator: SeparatorStyle,
        material: DigitMaterial,
        animation: DigitAnimation,
        numeralStyle: NumeralStyle
    ) {
        self.family = family; self.weight = weight; self.fontSize = fontSize
        self.tracking = tracking; self.stretchY = stretchY; self.format = format
        self.color = color; self.separator = separator
        self.material = material; self.animation = animation
        self.numeralStyle = numeralStyle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        family = try c.decode(ClockFontFamily.self, forKey: .family)
        weight = try c.decode(ClockWeight.self, forKey: .weight)
        fontSize = try c.decode(CGFloat.self, forKey: .fontSize)
        tracking = try c.decode(CGFloat.self, forKey: .tracking)
        stretchY = (try? c.decode(CGFloat.self, forKey: .stretchY)) ?? 1.0
        format = try c.decode(ClockFormat.self, forKey: .format)
        color = try c.decode(PersistedColor.self, forKey: .color)
        separator = try c.decode(SeparatorStyle.self, forKey: .separator)
        material = (try? c.decode(DigitMaterial.self, forKey: .material)) ?? .solid
        animation = (try? c.decode(DigitAnimation.self, forKey: .animation)) ?? .roll
        numeralStyle = (try? c.decode(NumeralStyle.self, forKey: .numeralStyle)) ?? .font
    }
}

struct PersistedTransform: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat
    var rotationDegrees: Double
    var opacity: Double
    var zIndex: Double

    enum CodingKeys: String, CodingKey {
        case x, y, scaleX, scaleY, scale, rotationDegrees, opacity, zIndex
    }

    init(x: CGFloat, y: CGFloat, scaleX: CGFloat, scaleY: CGFloat,
         rotationDegrees: Double, opacity: Double, zIndex: Double) {
        self.x = x; self.y = y
        self.scaleX = scaleX; self.scaleY = scaleY
        self.rotationDegrees = rotationDegrees
        self.opacity = opacity; self.zIndex = zIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        x = try c.decode(CGFloat.self, forKey: .x)
        y = try c.decode(CGFloat.self, forKey: .y)
        let legacy = (try? c.decode(CGFloat.self, forKey: .scale)) ?? 1.0
        scaleX = (try? c.decode(CGFloat.self, forKey: .scaleX)) ?? legacy
        scaleY = (try? c.decode(CGFloat.self, forKey: .scaleY)) ?? legacy
        rotationDegrees = try c.decode(Double.self, forKey: .rotationDegrees)
        opacity = try c.decode(Double.self, forKey: .opacity)
        zIndex = try c.decode(Double.self, forKey: .zIndex)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(scaleX, forKey: .scaleX)
        try c.encode(scaleY, forKey: .scaleY)
        try c.encode(rotationDegrees, forKey: .rotationDegrees)
        try c.encode(opacity, forKey: .opacity)
        try c.encode(zIndex, forKey: .zIndex)
    }
}

struct PersistedWidgetSettings: Codable, Equatable {
    var accentColor: PersistedColor
    var timerDurationSeconds: Int
    var timerRemaining: Int
    var timerRunning: Bool
    var calendarYear: Int?
    var calendarMonth: Int?
    var showsCalendarEvents: Bool
    var timeZoneIdentifier: String
    var worldClockTitle: String
    var dDayTitle: String
    var dDayDate: Date

    init(settings: WidgetSettings) {
        accentColor = PersistedColor(color: settings.accentColor)
        timerDurationSeconds = settings.timerDurationSeconds
        timerRemaining = settings.timerRemaining
        timerRunning = settings.timerRunning
        calendarYear = settings.calendarYear
        calendarMonth = settings.calendarMonth
        showsCalendarEvents = settings.showsCalendarEvents
        timeZoneIdentifier = settings.timeZoneIdentifier
        worldClockTitle = settings.worldClockTitle
        dDayTitle = settings.dDayTitle
        dDayDate = settings.dDayDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accentColor = (try? c.decode(PersistedColor.self, forKey: .accentColor))
            ?? PersistedColor(red: 1, green: 1, blue: 1, alpha: 1)
        timerDurationSeconds = (try? c.decode(Int.self, forKey: .timerDurationSeconds)) ?? 5 * 60
        timerRemaining = (try? c.decode(Int.self, forKey: .timerRemaining)) ?? timerDurationSeconds
        timerRunning = (try? c.decode(Bool.self, forKey: .timerRunning)) ?? false
        calendarYear = try? c.decodeIfPresent(Int.self, forKey: .calendarYear)
        calendarMonth = try? c.decodeIfPresent(Int.self, forKey: .calendarMonth)
        showsCalendarEvents = (try? c.decode(Bool.self, forKey: .showsCalendarEvents)) ?? false
        timeZoneIdentifier = (try? c.decode(String.self, forKey: .timeZoneIdentifier)) ?? TimeZone.current.identifier
        worldClockTitle = (try? c.decode(String.self, forKey: .worldClockTitle)) ?? ""
        dDayTitle = (try? c.decode(String.self, forKey: .dDayTitle)) ?? "D-Day"
        dDayDate = (try? c.decode(Date.self, forKey: .dDayDate))
            ?? (Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now)
    }

    var settings: WidgetSettings {
        WidgetSettings(
            accentColor: accentColor.color,
            timerDurationSeconds: timerDurationSeconds,
            timerRemaining: timerRemaining,
            timerRunning: timerRunning,
            calendarYear: calendarYear,
            calendarMonth: calendarMonth,
            showsCalendarEvents: showsCalendarEvents,
            timeZoneIdentifier: timeZoneIdentifier,
            worldClockTitle: worldClockTitle,
            dDayTitle: dDayTitle,
            dDayDate: dDayDate
        )
    }
}

enum PersistedItemKind: String, Codable {
    case clock
    case photo
    case weather
    case widget
    case html
}

struct PersistedHTMLWidgetSettings: Codable, Equatable {
    var resourceID: UUID
    var entryFileName: String
    var displayName: String
    var allowsNetwork: Bool

    init(settings: HTMLWidgetSettings) {
        resourceID = settings.resourceID
        entryFileName = settings.entryFileName
        displayName = settings.displayName
        allowsNetwork = settings.allowsNetwork
    }

    var settings: HTMLWidgetSettings {
        HTMLWidgetSettings(
            resourceID: resourceID,
            entryFileName: entryFileName,
            displayName: displayName,
            allowsNetwork: allowsNetwork
        )
    }
}

struct PersistedClickRippleSettings: Codable, Equatable {
    var enabled: Bool
    var intensity: Double
    var radius: CGFloat
    var duration: Double

    init(settings: ClickRippleSettings) {
        enabled = settings.enabled
        intensity = settings.intensity
        radius = settings.radius
        duration = settings.duration
    }

    var settings: ClickRippleSettings {
        ClickRippleSettings(
            enabled: enabled,
            intensity: intensity,
            radius: radius,
            duration: duration
        )
    }
}

struct PersistedItem: Codable, Equatable {
    var id: UUID
    var kind: PersistedItemKind
    var imageID: UUID?
    var weatherKind: WeatherKind?
    var widgetKind: WidgetKind?
    var htmlSettings: PersistedHTMLWidgetSettings?
    var transform: PersistedTransform
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var widgetSettings: PersistedWidgetSettings?

    static func from(_ item: CanvasItem) -> PersistedItem {
        let imgID: UUID? = {
            if case let .photo(id) = item.kind { return id }
            return nil
        }()
        let wKind: WeatherKind? = {
            if case let .weather(k) = item.kind { return k }
            return nil
        }()
        let wgKind: WidgetKind? = {
            if case let .widget(k) = item.kind { return k }
            return nil
        }()
        let htmlSettings: PersistedHTMLWidgetSettings? = {
            if case .html = item.kind { return PersistedHTMLWidgetSettings(settings: item.htmlSettings) }
            return nil
        }()
        let kind: PersistedItemKind = {
            switch item.kind {
            case .clock:   return .clock
            case .photo:   return .photo
            case .weather: return .weather
            case .widget:  return .widget
            case .html:    return .html
            }
        }()
        return PersistedItem(
            id: item.id,
            kind: kind,
            imageID: imgID,
            weatherKind: wKind,
            widgetKind: wgKind,
            htmlSettings: htmlSettings,
            transform: PersistedTransform(
                x: item.transform.position.x,
                y: item.transform.position.y,
                scaleX: item.transform.scaleX,
                scaleY: item.transform.scaleY,
                rotationDegrees: item.transform.rotation.degrees,
                opacity: item.transform.opacity,
                zIndex: item.transform.zIndex
            ),
            width: item.size.width,
            height: item.size.height,
            cornerRadius: item.cornerRadius,
            shadowRadius: item.shadowRadius,
            widgetSettings: PersistedWidgetSettings(settings: item.widgetSettings)
        )
    }

    func toCanvasItem() -> CanvasItem {
        let itemKind: ItemKind = {
            switch kind {
            case .clock:   return .clock
            case .photo:   return .photo(imageID: imageID ?? UUID())
            case .weather: return .weather(weatherKind ?? .sunny)
            case .widget:  return .widget(widgetKind ?? .dateDay)
            case .html:    return .html
            }
        }()
        return CanvasItem(
            id: id,
            kind: itemKind,
            transform: Transform(
                position: .init(x: transform.x, y: transform.y),
                scaleX: transform.scaleX,
                scaleY: transform.scaleY,
                rotation: .degrees(transform.rotationDegrees),
                opacity: transform.opacity,
                zIndex: transform.zIndex
            ),
            size: .init(width: width, height: height),
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            widgetSettings: widgetSettings?.settings ?? {
                if case let .widget(kind) = itemKind {
                    return WidgetSettings.defaults(for: kind)
                }
                return WidgetSettings()
            }(),
            htmlSettings: htmlSettings?.settings ?? HTMLWidgetSettings()
        )
    }
}

/// A named, self-contained snapshot of the whole look (clock style, background,
/// item/widget layout, timer style). Referenced photos/background images are copied
/// into the preset's own folder so it survives later edits.
struct Preset: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var state: PersistedState
}

struct PersistedState: Codable {
    var mode: CanvasMode
    var clockStyle: PersistedClockStyle
    var items: [PersistedItem]
    var backgroundColor: PersistedColor
    var backgroundImageID: UUID?
    var timerDuration: Int
    var alarmChoice: AlarmChoice
    var alarmVolume: Float
    var customAlarms: [CustomAlarm]
    var alwaysOnTop: Bool = false
    var timerStyle: TimerStyle = .digital
    var timerDiskColor: PersistedColor = PersistedColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1)
    var language: AppLanguage = .korean
    var backgroundMode: BackgroundMode = .color
    var autoTheme: Bool = false
    var backgroundOpacity: Double = 0.65
    var rippleSettings: PersistedClickRippleSettings = PersistedClickRippleSettings(settings: ClickRippleSettings())

    enum CodingKeys: CodingKey {
        case mode, clockStyle, items, backgroundColor, backgroundImageID
        case timerDuration, alarmChoice, alarmVolume, customAlarms, alwaysOnTop
        case timerStyle, timerDiskColor, language
        case backgroundMode, autoTheme, backgroundOpacity, rippleSettings
    }

    init(
        mode: CanvasMode,
        clockStyle: PersistedClockStyle,
        items: [PersistedItem],
        backgroundColor: PersistedColor,
        backgroundImageID: UUID?,
        timerDuration: Int,
        alarmChoice: AlarmChoice,
        alarmVolume: Float,
        customAlarms: [CustomAlarm],
        alwaysOnTop: Bool,
        timerStyle: TimerStyle,
        timerDiskColor: PersistedColor,
        language: AppLanguage,
        backgroundMode: BackgroundMode,
        autoTheme: Bool,
        backgroundOpacity: Double,
        rippleSettings: PersistedClickRippleSettings
    ) {
        self.mode = mode; self.clockStyle = clockStyle; self.items = items
        self.backgroundColor = backgroundColor; self.backgroundImageID = backgroundImageID
        self.timerDuration = timerDuration; self.alarmChoice = alarmChoice
        self.alarmVolume = alarmVolume; self.customAlarms = customAlarms
        self.alwaysOnTop = alwaysOnTop
        self.timerStyle = timerStyle; self.timerDiskColor = timerDiskColor
        self.language = language
        self.backgroundMode = backgroundMode; self.autoTheme = autoTheme
        self.backgroundOpacity = backgroundOpacity
        self.rippleSettings = rippleSettings
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decode(CanvasMode.self, forKey: .mode)
        clockStyle = try c.decode(PersistedClockStyle.self, forKey: .clockStyle)
        items = try c.decode([PersistedItem].self, forKey: .items)
        backgroundColor = try c.decode(PersistedColor.self, forKey: .backgroundColor)
        backgroundImageID = try c.decodeIfPresent(UUID.self, forKey: .backgroundImageID)
        timerDuration = try c.decode(Int.self, forKey: .timerDuration)
        alarmChoice = try c.decode(AlarmChoice.self, forKey: .alarmChoice)
        alarmVolume = try c.decode(Float.self, forKey: .alarmVolume)
        customAlarms = try c.decode([CustomAlarm].self, forKey: .customAlarms)
        alwaysOnTop = (try? c.decode(Bool.self, forKey: .alwaysOnTop)) ?? false
        timerStyle = (try? c.decode(TimerStyle.self, forKey: .timerStyle)) ?? .digital
        timerDiskColor = (try? c.decode(PersistedColor.self, forKey: .timerDiskColor))
            ?? PersistedColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1)
        language = (try? c.decode(AppLanguage.self, forKey: .language)) ?? .korean
        backgroundMode = (try? c.decode(BackgroundMode.self, forKey: .backgroundMode)) ?? .color
        autoTheme = (try? c.decode(Bool.self, forKey: .autoTheme)) ?? false
        backgroundOpacity = (try? c.decode(Double.self, forKey: .backgroundOpacity)) ?? 0.65
        rippleSettings = (try? c.decode(PersistedClickRippleSettings.self, forKey: .rippleSettings))
            ?? PersistedClickRippleSettings(settings: ClickRippleSettings())
    }
}
