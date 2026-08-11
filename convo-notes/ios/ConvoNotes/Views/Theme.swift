import SwiftUI

extension Color {
    static let brandTeal = Color(red: 13 / 255, green: 148 / 255, blue: 136 / 255)
    static let brandSky = Color(red: 2 / 255, green: 132 / 255, blue: 199 / 255)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandTeal, .brandSky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension PersonCategory {
    /// Each category gets its own avatar colour so the list scans quickly.
    var gradient: LinearGradient {
        switch self {
        case .man:
            return LinearGradient(colors: [.brandTeal, .brandSky],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .woman:
            return LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965),
                                           Color(red: 0.851, green: 0.275, blue: 0.937)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .child:
            return LinearGradient(colors: [Color(red: 0.961, green: 0.620, blue: 0.043),
                                           Color(red: 0.976, green: 0.451, blue: 0.086)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// Circular initials badge used in the list and on the detail screen.
struct AvatarView: View {
    let person: Person
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                .fill(person.category.gradient)
            Text(person.initials)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Small uppercase tag, e.g. FOLLOW UP / ARCHIVED.
struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .kerning(0.4)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .foregroundStyle(color)
    }
}
