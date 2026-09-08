# Text transform

Transform Text is a native palette screen for encoding, token inspection and hashing. The launcher
command opens an empty input field; Tinycast does not read the clipboard. Typing or pasting text
produces grouped result rows, and Return copies the selected row's complete result.

## Invariants

- `Model/` stays pure and imports only Foundation plus Apple's CryptoKit;
  `text-transform-test` compiles the shipped sources.
- URL encoding follows the RFC 3986 component rule: only ASCII letters, digits, `-._~` stay literal.
- URL decoding treats `+` as a literal plus, not a form-encoded space.
- Base64 decoding accepts whitespace, but the decoded bytes must be UTF-8 text.
- JSON Escape returns embeddable string content without surrounding quotes; Unescape accepts either
  that content or a complete quoted JSON string.
- JWT Decode reads exactly three compact segments, renders the JSON header and payload, and never
  claims to verify the signature.
- Hashing treats the input as UTF-8 and emits lowercase MD5, SHA-1, SHA-256 and SHA-512 hex digests.

## Palette integration

`CommandID.textTransform` opens `.textTransform`. `TextTransformScreen.rows` is the exact visible
order from `TextTransform.allCases`, and error rows remain visible but expose no Copy action.

`TextTransformCoordinator` is the feature's action surface. It dismisses the palette and writes the
selected result only after Return or the explicit Copy Result action; opening the screen has no
clipboard side effect.
