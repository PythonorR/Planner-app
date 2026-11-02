import SwiftUI

/// A square rotated 45°.
struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// Red filled diamond for an undone due date, outlined diamond for an event, else empty space.
struct Marker: View {
    let hasDue: Bool
    let hasEvent: Bool
    var size: CGFloat = 8

    var body: some View {
        Group {
            if hasDue {
                Diamond().fill(Theme.due)
            } else if hasEvent {
                Diamond().stroke(Theme.fg, lineWidth: 1.2)
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
    }
}

struct Separator: View {
    var body: some View { Rectangle().fill(Theme.line).frame(height: 1) }
}

/// 12 pt bold uppercase group label.
struct SectionLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .scaledFont(12, .bold, relativeTo: .caption)
            .tracking(0.6)
            .foregroundStyle(color)
    }
}

struct Checkbox: View {
    let done: Bool
    let color: Color

    var body: some View {
        ZStack {
            if done {
                Circle().fill(color)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.bg)
            } else {
                Circle().strokeBorder(color, lineWidth: 2)
            }
        }
        .frame(width: 26, height: 26)
    }
}

/// Date number: filled circle when selected, outlined when today.
struct DayNumber: View {
    let day: Date
    let selected: Bool
    let today: Bool
    var size: CGFloat = 30

    var body: some View {
        Text("\(Calendar.current.component(.day, from: day))")
            .scaledFont(15, selected || today ? .bold : .medium)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(selected ? Theme.bg : Theme.fg)
            .frame(width: size, height: size)
            .background {
                if selected {
                    Circle().fill(Theme.fg)
                } else if today {
                    Circle().stroke(Theme.fg, lineWidth: 1.5)
                }
            }
    }
}

/// Vertical stack of task segments, first segment at the bottom.
struct SegmentStack: View {
    let segments: [Segment]
    let width: CGFloat
    let segment: CGFloat
    let height: CGFloat
    var gap: CGFloat = 1
    var emptyLine: CGFloat = 3
    var remainingOpacity: Double = 0.25

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            if segments.isEmpty {
                if emptyLine > 0 {
                    Capsule().fill(Theme.line).frame(width: width, height: emptyLine)
                }
            } else {
                VStack(spacing: gap) {
                    ForEach(Array(segments.reversed().enumerated()), id: \.offset) { _, s in
                        Rectangle()
                            .fill(Theme.subject(s.colorIndex).opacity(s.done ? 1 : remainingOpacity))
                            .frame(width: width, height: segment)
                    }
                }
                .clipShape(Capsule())
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

struct ProgressBar: View {
    let fraction: Double
    var color: Color = Theme.fg
    var height: CGFloat = 3

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule().fill(color).frame(width: g.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct ChevronButtons: View {
    let previousLabel: String
    let nextLabel: String
    let previous: () -> Void
    let next: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: previous) {
                Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel(previousLabel)
            Button(action: next) {
                Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel(nextLabel)
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(Theme.fg)
        .buttonStyle(.plain)
    }
}

/// 56 pt black (white in dark mode) capsule.
struct FilledCapsule: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaledFont(17, .semibold)
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(Theme.fg))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct OutlinedCapsule: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaledFont(17, .semibold)
            .foregroundStyle(Theme.fg)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .overlay(Capsule().stroke(Theme.fg, lineWidth: 1.5))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
