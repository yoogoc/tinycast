import AppKit

@MainActor
final class TextTransformCoordinator {
    private let paletteCoordinator: PaletteCoordinator

    init(paletteCoordinator: PaletteCoordinator) {
        self.paletteCoordinator = paletteCoordinator
    }

    func copyResult(_ result: TextTransformResult) {
        guard let text = result.copyText else { return }
        paletteCoordinator.hidePalette(restoreFocus: false)
        Paster.copyPlainText(text)
    }
}
