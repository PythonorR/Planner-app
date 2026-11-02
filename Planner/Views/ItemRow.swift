import SwiftUI

/// One task / due / event row. Tap = edit, long-press = Delete.
struct ItemRow: View {
    let item: Item
    let subject: Subject?
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var tint: Color { item.kind == .due ? Theme.due : Theme.color(for: subject) }

    var body: some View {
        VStack(spacing: 0) {
            Separator()
            HStack(spacing: 6) {
                if item.kind == .event {
                    Diamond()
                        .stroke(Theme.fg, lineWidth: 1.5)
                        .frame(width: 12, height: 12)
                        .frame(width: 44, height: 44)
                } else {
                    Button(action: onToggle) {
                        Checkbox(done: item.done, color: tint)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(weight: .light), trigger: item.done)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .scaledFont(18, .medium)
                        .foregroundStyle(item.done ? Theme.muted : Theme.fg)
                        .strikethrough(item.done, color: Theme.muted)
                        .multilineTextAlignment(.leading)
                    if let detail {
                        Text(detail.text)
                            .scaledFont(13, .medium)
                            .foregroundStyle(detail.color)
                    }
                }
                .padding(.vertical, 8)

                Spacer(minLength: 0)
            }
            .padding(.leading, -9)   // align the 26 pt circle with the section label
            .frame(minHeight: 56)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onEdit)
        .accessibilityActions {
            if item.kind != .event {
                Button(item.done ? "Mark not done" : "Mark done", action: onToggle)
            }
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var detail: (text: String, color: Color)? {
        switch item.kind {
        case .due:
            return (text: "Due" + (item.timeMinutes.map { " · " + Fmt.time($0) } ?? ""), color: Theme.due)
        case .event:
            return item.timeMinutes.map { (text: Fmt.time($0), color: Theme.muted) }
        case .task:
            if !item.done, let from = item.rolledFrom { return (text: "↩ from \(Fmt.monthDay(from))", color: Theme.muted) }
            return nil
        }
    }

    private var accessibilityText: String {
        var parts = [item.title]
        if let subject { parts.append(subject.name) }
        if let detail { parts.append(detail.text.replacingOccurrences(of: "↩ ", with: "moved ")) }
        if item.kind == .event { parts.append("event") } else { parts.append(item.done ? "done" : "not done") }
        return parts.joined(separator: ", ")
    }
}
