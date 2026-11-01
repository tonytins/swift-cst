# CST Language Support for VS Code

This extension adds basic syntax highlighting for Caret-Separated Text (`.cst`)
files.

It highlights entry keys, caret-delimited values, `%s` and `%d` variable
placeholders, and CST comments. It does not validate files or provide
completion.

## Try it locally

1. Open `addons/vscode` as a folder in VS Code.
2. Press F5 to launch an Extension Development Host.
3. Open a `.cst` file in the new window.

The extension uses a TextMate grammar. Multiline values and comments are
highlighted lexically. The grammar does not implement the parser's
malformed-entry recovery.
