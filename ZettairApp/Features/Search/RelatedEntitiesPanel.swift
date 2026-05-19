import SwiftUI
import ZettairKit

struct RelatedEntitiesPanel: View {
    let block: RelatedBlock
    let onTap: (RelatedItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "link.circle.fill").foregroundStyle(.secondary)
                Text(header).font(.subheadline.weight(.semibold))
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(block.items) { item in
                    Button(action: {
                        Haptics.tap()
                        onTap(item)
                    }) {
                        HStack {
                            Text(item.title).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if item != block.items.last {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var header: String {
        switch block.sourceClass {
        case "human":        return "Related people"
        case "place":        return "Related places"
        case "organisation": return "Related organisations"
        case "work":         return "Related works"
        case "event":        return "Related events"
        default:             return "Related"
        }
    }
}
