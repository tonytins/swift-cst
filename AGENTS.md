# Project Guidelines

## Project structure

SwiftCST is a general-purpose Swift library for Caret-Separated Text (`.cst`), the
format The Sims Online (TSO) used for its interface text. It has two layers, and text
lookups run through them in this order: `UIText`, then the CST core.

- **CST core** (`CST`, `CSTTable`) reads a document from a `String`. It is public so
  anyone can write their own wrapper, and it must not assume TSO's file layout. It owns
  comments, keys, values, and malformed entries.
- **`UIText`** mimics how TSO loads its text, and it may be TSO-specific. It owns file
  names, language directories, and text encodings. It should use only the core's public
  API.

`Sources/SwiftCST` holds the library, `Tests/SwiftCSTTests` covers its behavior, and
`addons` holds editor support. [doc/README.md](doc/README.md) documents usage,
[doc/CST.md](doc/CST.md) specifies the format, and [doc/changelog.md](doc/changelog.md)
records each release.

## Build and test

- Build with `swift build`.
- Run the test suite with `swift test`.
- Format with `./format.sh`, which also lints.
- For a change to the public API or to lookup results, also call the library from a
  small scratch package outside the repository.
- CI builds and tests on macOS only. Report what you could not run, such as macOS from
  Linux or anything on Windows.

## Swift and CST

- See [the Swift guidelines](.agents/swift-guidelines/SKILL.md) for general conventions,
  including how to choose the tools version and handle Apple availability.
- Match the package's Swift 6 language mode and existing naming and formatting.
- Keep public APIs clear at the call site, and document all public behavior.
- Reading a table never fails. Report a malformed entry and keep the rest of the table.
- Never return another entry's text. A wrong value is worse than a missing one.
- Hand values back untouched unless asked to fill their placeholders, because some
  tables hold data rather than text for players.
- Add focused tests when behavior changes, and record changes callers would notice in the
  changelog.

## Format rules

[The CST specification](doc/CST.md) is the reference for how real files behave, and it
labels how sure each rule is. Change it along with any change to how files are read. Tests
read its example directly, so the page and the code can't drift apart.

Hand-written samples tend to hold only the shapes their author already knows about, so check
parser changes against real tables when you have them. `TSO_GAME_DIR`, `TSO_CLASSIC_DIR`, and
`TSO_BETA_DIR` point to local installs when they are set, and `swift test` then reads every
table in them. Do not commit files from a game install.

See [REVIEW.md](REVIEW.md) for the project's review checklist.

## Personal Configuration

Keep personal preferences and machine-specific guidance in git-ignored `*.local` files or
directories (such as `AGENTS.local.md`), rather than in shared project instructions. Check
for relevant local guidance before environment-specific work. You can create or update
these files for details such as:

- Coding preferences
- Local build and development environment
- Personal shortcuts or workflows
