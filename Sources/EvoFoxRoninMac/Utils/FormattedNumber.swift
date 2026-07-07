import Foundation

func formattedNumber(_ value: Int, locale: Locale = .current) -> String {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = true
    return formatter.string(from: NSNumber(value: value)) ?? String(value)
}

func formattedRGB(_ red: Double, _ green: Double, _ blue: Double, locale: Locale = .current) -> String {
    let r = formattedNumber(Int(red * 255), locale: locale)
    let g = formattedNumber(Int(green * 255), locale: locale)
    let b = formattedNumber(Int(blue * 255), locale: locale)
    return "Red \(r), Green \(g), Blue \(b)"
}
