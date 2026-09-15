import SwiftUI

struct TextTransformList: View {
    @Environment(\.metrics) private var metrics
    let results: [TextTransformResult]
    let selectedID: TextTransformResult.ID?
    let scroll: ScrollIntent
    let onSelect: (TextTransformResult) -> Void
    let onActivate: () -> Void
    let onActions: (TextTransformResult) -> Void

    private var firstRowSelected: Bool {
        selectedID != nil && selectedID == results.first?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        if index == 0
                            || results[index - 1].transform.category != result.transform.category
                        {
                            SectionHeader(
                                title: result.transform.category.rawValue, isFirst: index == 0)
                        }
                        ResultRow(result: result, selected: result.id == selectedID)
                            .selectionFrame(result.id == selectedID)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(result) }
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    onSelect(result)
                                    onActivate()
                                })
                            .onRightClick { onActions(result) }
                    }
                }
                .padding(.horizontal, metrics.spacing.md)
                .padding(.top, metrics.spacing.xs)
                .padding(.bottom, metrics.spacing.md)
                .hideNativeScrollers()
                .scrollOriginAnchor()
            }
            .edgeDissolve()
            .thinScrollbar()
            .scrollFollowsSelection(
                scroll, row: selectedID, atOrigin: firstRowSelected, proxy: proxy)
        }
    }

    private struct ResultRow: View {
        @Environment(\.metrics) private var metrics
        let result: TextTransformResult
        let selected: Bool
        @State private var hovered = false

        private var fill: Color {
            if selected { return Theme.Colors.selection }
            if hovered { return Theme.Colors.rowHover }
            return .clear
        }

        private var display: String {
            switch result.payload {
            case .value(let text):
                return text.isEmpty
                    ? "Empty text"
                    : text.replacingOccurrences(of: "\n", with: " ")
                        .replacingOccurrences(of: "\r", with: " ")
            case .error(let message): return message
            }
        }

        private var isError: Bool {
            if case .error = result.payload { return true }
            return false
        }

        var body: some View {
            HStack(spacing: metrics.spacing.lg) {
                RoundedRectangle(cornerRadius: metrics.radius.thumbnail, style: .continuous)
                    .fill(Theme.Colors.controlSurface)
                    .frame(width: metrics.size.rowIcon, height: metrics.size.rowIcon)
                    .overlay(
                        SymbolImage(
                            name: result.transform.sfSymbol, size: metrics.size.rowIcon * 0.5
                        )
                            .foregroundStyle(.secondary)
                    )
                Text(result.transform.name)
                    .font(metrics.typography.rowTitle)
                    .lineLimit(1)
                Spacer(minLength: metrics.spacing.xl)
                Text(display)
                    .font(metrics.typography.code)
                    .foregroundStyle(isError ? Theme.Colors.destructive : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, metrics.spacing.md)
            .padding(.vertical, metrics.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: metrics.radius.row, style: .continuous)
                    .fill(fill)
            )
            .armedHover($hovered)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(result.transform.name)
            .accessibilityValue(display)
            .accessibilityAddTraits(selected ? .isSelected : [])
        }
    }
}
