import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case korean = "ko"
    case english = "en"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .korean:  return "한국어"
        case .english: return "English"
        }
    }
}

enum LKey {
    // Header / general
    case style, clock, photo, closePanel, language

    // Timer
    case timer, hourSuffix, minuteSuffix, secondSuffix
    case start, pause, reset
    case timerStyle, styleDigital, styleDisk, diskColor

    // Alarm
    case alarmSound, off, volume, preview, addMP3, deleteCustomSound

    // Clock style
    case clockStyle, format, font, weight, separator, material, transition
    case size, stretchY, tracking, color
    case numeralStyle, numeralSegment

    // Transform
    case arrange, width, height, rotation, opacity

    // Photo
    case photoShape, corner, shadow

    // Layer
    case layer, behindClock, frontClock, toBack, toFront, delete

    // Hints
    case selectHint

    // Background modes / theme
    case bgMode, transparent, translucent, glassOutline, autoTheme

    // Add menu / weather / widgets
    case add, weather, sticker, widget

    // Toolbar
    case addPhoto, background, removeBgImage, bgColor
    case pinOn, pinOff, closeStylePanel, openStylePanel
    case focus, hideUI, showUI

    // Panel titles
    case addAlarmTitle, choosePhotoTitle, chooseBgTitle

    var pair: (ko: String, en: String) {
        switch self {
        case .style:            return ("스타일", "Style")
        case .clock:            return ("시계", "Clock")
        case .photo:            return ("사진", "Photo")
        case .closePanel:       return ("패널 닫기", "Close panel")
        case .language:         return ("언어", "Language")

        case .timer:            return ("타이머", "Timer")
        case .hourSuffix:       return ("시", "H")
        case .minuteSuffix:     return ("분", "M")
        case .secondSuffix:     return ("초", "S")
        case .start:            return ("시작", "Start")
        case .pause:            return ("일시정지", "Pause")
        case .reset:            return ("리셋", "Reset")
        case .timerStyle:       return ("타이머 스타일", "Timer Style")
        case .styleDigital:     return ("디지털", "Digital")
        case .styleDisk:        return ("디스크", "Disk")
        case .diskColor:        return ("디스크 색상", "Disk Color")

        case .alarmSound:       return ("알람 사운드", "Alarm Sound")
        case .off:              return ("끄기", "Off")
        case .volume:           return ("볼륨", "Volume")
        case .preview:          return ("미리듣기", "Preview")
        case .addMP3:           return ("MP3 추가", "Add MP3")
        case .deleteCustomSound:return ("선택된 사용자 사운드 삭제", "Delete selected sound")

        case .numeralStyle:     return ("숫자 모양", "Numerals")
        case .numeralSegment:   return ("세그먼트", "Segment")

        case .clockStyle:       return ("시계 스타일", "Clock Style")
        case .format:           return ("형식", "Format")
        case .font:             return ("폰트", "Font")
        case .weight:           return ("두께", "Weight")
        case .separator:        return ("분리자", "Separator")
        case .material:         return ("재질", "Material")
        case .transition:       return ("전환", "Transition")
        case .size:             return ("크기", "Size")
        case .stretchY:         return ("세로 늘이기", "Stretch")
        case .tracking:         return ("자간", "Tracking")
        case .color:            return ("색상", "Color")

        case .arrange:          return ("배치", "Arrange")
        case .width:            return ("가로 크기", "Width")
        case .height:           return ("세로 크기", "Height")
        case .rotation:         return ("회전", "Rotation")
        case .opacity:          return ("불투명도", "Opacity")

        case .photoShape:       return ("사진 모양", "Photo Shape")
        case .corner:           return ("모서리", "Corner")
        case .shadow:           return ("그림자", "Shadow")

        case .layer:            return ("레이어", "Layer")
        case .behindClock:      return ("시계 뒤", "Behind Clock")
        case .frontClock:       return ("시계 앞", "Front of Clock")
        case .toBack:           return ("맨 뒤", "To Back")
        case .toFront:          return ("맨 앞", "To Front")
        case .delete:           return ("삭제", "Delete")

        case .selectHint:
            return ("캔버스의 사진이나 시계를 선택하면\n속성을 편집할 수 있습니다.",
                    "Select a photo or clock on the\ncanvas to edit its properties.")

        case .bgMode:           return ("배경 모드", "Background")
        case .transparent:      return ("투명", "Transparent")
        case .translucent:      return ("반투명", "Translucent")
        case .glassOutline:     return ("글래스 윤곽선", "Glass Outline")
        case .autoTheme:        return ("시간별 자동 테마", "Time-based Theme")

        case .add:              return ("추가", "Add")
        case .weather:          return ("날씨", "Weather")
        case .sticker:          return ("스티커", "Sticker")
        case .widget:           return ("위젯", "Widget")

        case .addPhoto:         return ("사진 추가", "Add Photo")
        case .background:       return ("배경", "Background")
        case .removeBgImage:    return ("배경 이미지 제거", "Remove background image")
        case .bgColor:          return ("배경 색상", "Background color")
        case .pinOn:            return ("모든 앱 위에 고정 됨 — 다시 누르면 해제", "Pinned above all apps — tap to unpin")
        case .pinOff:           return ("모든 앱 위에 고정", "Keep above all apps")
        case .closeStylePanel:  return ("스타일 패널 닫기", "Close style panel")
        case .openStylePanel:   return ("스타일 패널 열기", "Open style panel")
        case .focus:            return ("집중", "Focus")
        case .hideUI:           return ("전체 UI 숨기기 (ESC로 토글)", "Hide all UI (toggle with ESC)")
        case .showUI:           return ("UI 다시 보기 (ESC)", "Show UI (ESC)")

        case .addAlarmTitle:    return ("알람 사운드 추가", "Add alarm sound")
        case .choosePhotoTitle: return ("사진 선택", "Choose photo")
        case .chooseBgTitle:    return ("배경 이미지 선택", "Choose background image")
        }
    }
}

enum Localization {
    static func string(_ key: LKey, _ lang: AppLanguage) -> String {
        let p = key.pair
        return lang == .korean ? p.ko : p.en
    }
}

// MARK: - Localized display names for picker enums
// rawValue is kept stable for Codable; display(_:) drives on-screen text.

extension CanvasMode {
    func display(_ lang: AppLanguage) -> String {
        switch self {
        case .clock: return Localization.string(.clock, lang)
        case .timer: return Localization.string(.timer, lang)
        }
    }
}

extension DigitMaterial {
    func display(_ lang: AppLanguage) -> String {
        let ko = lang == .korean
        switch self {
        case .solid:       return ko ? "단색" : "Solid"
        case .gradient:    return ko ? "그라데이션" : "Gradient"
        case .glass:       return ko ? "글래스 (배경 비침)" : "Glass (see-through)"
        case .liquidGlass: return ko ? "리퀴드 글래스" : "Liquid Glass"
        case .overlay:     return ko ? "오버레이 (배경과 어우러짐)" : "Overlay (blend)"
        }
    }
}

extension DigitAnimation {
    func display(_ lang: AppLanguage) -> String {
        let ko = lang == .korean
        switch self {
        case .none:      return ko ? "없음" : "None"
        case .fade:      return ko ? "페이드" : "Fade"
        case .roll:      return ko ? "롤" : "Roll"
        case .slideUp:   return ko ? "위로 슬라이드" : "Slide Up"
        case .slideDown: return ko ? "아래로 슬라이드" : "Slide Down"
        case .scale:     return ko ? "스케일" : "Scale"
        case .flip:      return ko ? "플립 (3D)" : "Flip (3D)"
        case .depth:     return ko ? "뎁스" : "Depth"
        case .blur:      return ko ? "블러" : "Blur"
        }
    }
}

extension WeatherKind {
    func displayName(_ lang: AppLanguage) -> String {
        let ko = lang == .korean
        switch self {
        case .sunny:        return ko ? "맑음" : "Sunny"
        case .partlyCloudy: return ko ? "구름 조금" : "Partly Cloudy"
        case .cloudy:       return ko ? "흐림" : "Cloudy"
        case .windy:        return ko ? "바람" : "Windy"
        case .rainy:        return ko ? "비" : "Rainy"
        case .sunshower:    return ko ? "여우비" : "Sun Shower"
        case .snowy:        return ko ? "눈" : "Snowy"
        case .rainbow:      return ko ? "무지개" : "Rainbow"
        case .auto:         return ko ? "자동 (현재 위치)" : "Auto (Current)"
        }
    }
}

extension WidgetKind {
    func displayName(_ lang: AppLanguage) -> String {
        let ko = lang == .korean
        switch self {
        case .dateDay: return ko ? "날짜 · 요일" : "Date · Day"
        }
    }
}

extension BackgroundMode {
    func display(_ lang: AppLanguage) -> String {
        switch self {
        case .color:        return Localization.string(.color, lang)
        case .transparent:  return Localization.string(.transparent, lang)
        case .translucent:  return Localization.string(.translucent, lang)
        case .glassOutline: return Localization.string(.glassOutline, lang)
        }
    }
    var symbol: String {
        switch self {
        case .color:        return "paintpalette"
        case .transparent:  return "square.dashed"
        case .translucent:  return "square.fill.on.square.fill"
        case .glassOutline: return "square.on.square.dashed"
        }
    }
}

extension SeparatorStyle {
    func display(_ lang: AppLanguage) -> String {
        let ko = lang == .korean
        switch self {
        case .colon: return ko ? "콜론  ( : )" : "Colon  ( : )"
        case .dot:   return ko ? "점  ( · )" : "Dot  ( · )"
        case .space: return ko ? "공백" : "Space"
        case .dash:  return ko ? "대시  ( - )" : "Dash  ( - )"
        }
    }
}
