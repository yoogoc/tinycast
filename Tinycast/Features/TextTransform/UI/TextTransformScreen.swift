import SwiftUI

struct TextTransformScreen: PaletteScreen {
    let core: AppCore
    let vm: PaletteState
    let openActions: () -> Void

    var rows: [TextTransformResult] {
        guard !vm.query.isEmpty else { return [] }
        return TextTransform.allCases.map { TextTransformEngine.evaluate(vm.query, using: $0) }
    }

    var primaryActionTitle: String { "Copy Result" }

    private func result(at selection: Int) -> TextTransformResult? {
        let rows = rows
        return rows.indices.contains(selection) ? rows[selection] : nil
    }

    func hasPrimaryAction(at selection: Int) -> Bool {
        result(at: selection)?.copyText != nil
    }

    func actions(at selection: Int) -> PopoverMenuContent? {
        guard let result = result(at: selection), result.copyText != nil else { return nil }
        return PopoverMenuContent(
            header: result.transform.name,
            items: [
                PopoverMenuItem(
                    title: "Copy Result", systemImage: "doc.on.doc", shortcut: "↵"
                ) {
                    core.textTransformCoordinator.copyResult(result)
                }
            ])
    }

    func activate(at selection: Int) {
        guard let result = result(at: selection) else { return }
        core.textTransformCoordinator.copyResult(result)
    }

    func secondary(at selection: Int) -> Bool { false }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(content(selection: selection, scroll: scroll))
    }

    @ViewBuilder
    private func content(selection: Int, scroll: ScrollIntent) -> some View {
        let rows = rows
        if rows.isEmpty {
            EmptyResults(text: "Type or paste text to transform")
        } else {
            TextTransformList(
                results: rows,
                selectedID: rows.indices.contains(selection) ? rows[selection].id : nil,
                scroll: scroll,
                onSelect: { result in
                    if let index = rows.firstIndex(of: result) { vm.selection = index }
                },
                onActivate: { activate(at: vm.selection) },
                onActions: { result in
                    guard result.copyText != nil else { return }
                    if let index = rows.firstIndex(of: result) { vm.selection = index }
                    openActions()
                })
        }
    }
}
