# CST Format

Caret-Separated Text (CST) is the plain-text format The Sims Online (TSO) uses for
its interface text. Maxis never published a specification, so this one is
reconstructed from TSO's files and from the parsers written for them.
[SwiftCST](../README.md) implements it.

CST files are not known to appear in any other game.

## How sure each rule is

No rule here has been checked against the original game while it runs. Each carries
one of these labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Real files do this in every version checked, and FreeSO's loader or a `.uis` file depends on it. |
| **Observed** | Real files do this, but nothing shows how the game treats it. |
| **Unsettled** | The evidence does not decide it. The choice is stated, and it may change. |
| **Not seen** | No real file does this. The rule comes from an earlier parser or from design, and readers should accept it anyway. |

The evidence comes from three installs:

| | Beta 1.3.2.121 | Base game 1.145.1.0 | New & Improved 1.1097.1.0 |
| --- | ---: | ---: | ---: |
| Tables | 112 | 113 | 137 |
| Values | 2,561 | 2,795 | 3,588 |
| After a key on the same line | 1,383 | 1,454 | 2,150 |
| With no key on the same line | 1,178 | 1,341 | 1,438 |
| Directory under `gamedata` | `uitext.dir` | `uitext.dir` | `uitext/english.dir` |

## Readers and wrappers

This specification describes two layers:

- A **reader** turns the text of one table into its values, in file order, with each
  value's key and name. It knows nothing about files, other tables, or the game.
- A **wrapper** finds tables on disk and answers lookups for a program, the way TSO's own
  code does. Position lookups and references belong here, because they depend on how a
  game uses its tables. They are marked **Wrapper** below.

## Example

Every rule below applies to this file, which is original to this project. Tests read it
from this page and check the results listed after it.

<!-- The specification example. -->
```text
// A comment. So is a line starting with #, and a /* */ block.
1 ^A value after its key^
    2 ^An indented key^
3
^A key above its value^
4 ^A value that runs
across lines^
ok button ^A key with spaces^
kErrNoFood
^A name above its value^
A note for translators.

^A value with a note above it^
^A value on its own^ with a note after it
^Another value on its own^
```

| Lookup | Result |
| --- | --- |
| `1`, `2`, `3` | The first three values |
| `4` | `A value that runs`, a newline, then `across lines` |
| `ok button` | `A key with spaces` |
| `kErrNoFood`, or `5` through a wrapper | `A name above its value` |
| `A note for translators.`, or `6` through a wrapper | `A value with a note above it` |
| `7` through a wrapper | `A value on its own` |
| `8` through a wrapper | `Another value on its own` |

## Files

- **Names (Confirmed):** a table is a file named `_<id>_<name>.cst`, where `<id>` is
  a decimal number. Lookups use only the ID. The extension's case does not matter.
- **Other files (Observed):** the base game and beta also hold an unnumbered, empty
  `objectdata.dir/gamecompdrawacard.cst`. Readers should ignore files that do not
  follow the pattern.
- **Layout (Confirmed):** New & Improved uses `gamedata/uitext/<language>.dir`. Earlier
  versions have one language in `gamedata/uitext.dir`.
- **`.uis` references (Confirmed):** a `.uis` file names a table with `stringDir` and
  `stringTable`, and an entry with `stringIndex`. Every real `stringDir` is `UIText`.

## Encoding and line endings

- **Encoding (Confirmed):** a reader must accept UTF-8, with or without a byte order
  mark, and a wrapper loading files must fall back to Windows-1252. Beta and the base
  game have three non-UTF-8 tables, and New & Improved has one, the credits. Most files
  are plain ASCII.
- **Line endings (Observed):** real tables use CRLF, except one with no line break at
  all. Readers should accept LF, CR, CRLF, and U+2028, and convert them to LF before
  reading. Convert CRLF first, or each one becomes two line breaks.

## Entries

A value is the text between two carets. There is no way to escape a caret, so a value
cannot hold one (Confirmed: no real file has an odd number of carets).

A value's key depends on what comes before its opening caret:

1. **Text on the same line (Confirmed):** that text, trimmed, is the key. It may be a
   number, a word, or several words, and a lookup must match it whole. FreeSO looks up
   keys such as `ok button` whole.
2. **A number alone on the nearest line above (Not seen):** that number is the key.
   Earlier parsers accept this layout, and rule 3 shows why it is plausible.
3. **Any other text on the nearest line above (Confirmed):** that line, trimmed, is the
   value's name. FreeSO looks up table 137 by names such as `kPErrLocationOutOfBounds`,
   written this way. Others are plainly notes, such as `tooltips`. Nothing in the file
   separates a name from a note.
4. **Nothing above (Confirmed):** the value has no key or name.

Blank lines and comments between a line and its value do not matter.

### Positions (Wrapper)

A value with no key of its own, under rules 3 and 4, is also known by its position.
**Position** counts every value in the table, including those with keys and those never
closed. Keys are text, so position 5 is the key `5`.

A key written in the file always wins over a position, so a position only reaches a value
with no key of its own (Not seen: no real table has this collision). A name can't collide
with a position, because a number on the line above a value is its key.

**Starting from 0 is Unsettled.** FreeSO counts from 0, and SwiftCST's `UIText` and Hudini
do too. But nothing in the game's files requires it, and two things point the other way: no
numbered table starts at 0, while 111 start at 1, and table 136's own notes say "Strings
1-3". Only one `.uis` string in each version uses a position, `EALabelText` in
`credits.uis`, at 5. From 0 that is a copyright line, and from 1 it is a line about Maxis,
and either suits the name. That screen requires logging in, so with the game's servers gone
it can't be checked by running the game. A screenshot from when it was live would settle it.
Tables read in order, as described under [What values hold](#what-values-hold), work either
way.

### Text outside values

Text between values that does not become a key or name is ignored (Confirmed). This
includes any lines above the nearest one, and text after a closing caret on the same line,
which describes the value before it, whether that value took one line or several. Tables use
this for translators' notes.

### Comments

- **`//` (Confirmed):** a line whose first non-space characters are `//` is a comment.
  Real tables use these throughout.
- **`#` (Observed):** the same, though only two real lines start this way, both headers
  naming their file. Since text outside values is ignored anyway, little depends on it.
- **`/*` (Not seen):** a line whose first non-space characters are `/*` starts a comment
  that runs to the end of the line holding `*/`.

Comments are removed before anything else, so a comment line inside a value is not part
of it. No real value has such a line, so this case is Not seen too.

### Values

- **Multiline (Confirmed):** a value runs until its closing caret, and keeps its line
  breaks and spacing exactly.
- **Empty (Observed):** `^^` is a valid, empty value that still takes a position. Tables
  such as 138 hold dozens of them.

### Malformed tables

No real table has these, so the handling is this specification's design rather than a
finding.

- **Unclosed values:** while a value is open, a line holding exactly two carets, with only
  whitespace after the last, holds a whole entry. The open value was therefore never closed.
  Skip it and report it, but still count its position. Without this, one stray caret misreads
  every later entry. Any other line with a caret closes the open value.
- **The line before a whole entry:** the last non-blank line read into an unclosed value
  counts as the nearest line above the next value. In `broken ^unfinished`, `next`, `^value^`,
  the last value keeps the key `next`.
- **The end of a file:** a value still open there is also skipped and reported, and counts
  its position.
- **Reading never fails:** a table with one bad entry is still useful, so report the
  problem and keep the rest. Only an unreadable file or directory is an error.
- **Missing text:** report it as missing rather than returning a marker string, which
  a program cannot tell from real text. SwiftCST's older string-returning lookups still
  return `*** MISSING ***` for compatibility.

## What values hold

A value is not always text for a player to read, and code decides what it means. A reader
should hand values back untouched (Observed).

| Table | Values hold |
| --- | --- |
| 148 | Text, then a number of milliseconds to show it |
| 145 | Coordinates such as `(88;6)` alternating with button labels |
| 161 | Keyboard shortcuts such as `^p^ pause`, described by the text after each value |
| 242 | The credits, as instructions for their renderer |

### The credits

Table 241 holds the credits screen's ordinary text. Table 242 is a small script for the
scrolling credits, which documents itself in comments and credits Blazej Stompel for the
system. Its values have no keys, so they are read in order:

```text
^<scroll speed>^
^NewLine|<line height>|<font size>|<font color>^
^LineEntry|<Center, Left, Right, or a left offset>|<text>|<optional underline color>^
```

Colors are `r,g,b`. Most of the values with no key are this script: 735 of 1,178 in beta,
896 of 1,341 in the base game, and 980 of 1,438 in New & Improved. Parsing it belongs to the
code that draws the credits, not to a reader.

## Repeated keys

**Unsettled.** Table 237 is the only real case, in all three versions: its key `2`
appears twice, and the numbering suggests a typo. This specification keeps the first and
reports the second. FreeSO keeps the last.

A key from rule 1 or 2 always wins over a name from rule 3 without a report, whichever
comes first.

## Keys with two numbers

**Unsettled.** Fifteen entries in New & Improved's table 210 look like `24 012 ^...^`,
likely a position and a server reason code. This specification keeps `24 012` as the whole
key, so `24` does not find it.

## References (Wrapper)

Thirty-nine entries in New & Improved's table 208 hold a reference instead of text. They
start with the control character U+0002 (Confirmed: all 39 resolve):

```text
16 ^<U+0002><cst><cst_id>276</cst_id><string_id>1</string_id></cst>^
17 ^<U+0002><cst><cst_id>276</cst_id><string_id>2</string_id><string arg="1">%s</string></cst>^
```

`cst_id` is a table and `string_id` is a key. A wrapper returns the target's text and stops
at one reference, so a cycle cannot hang it. It passes arguments in order and ignores `arg`
numbers. All real ones are `arg="1"`, so their order is untested (Unsettled). A reader returns
the reference as written.

## Placeholders

Placeholders are filled in order by code that uses the text, so readers should return
them untouched unless asked to fill them. Padding follows C's `printf`, and never shortens a
number.

| Placeholder | Status | Meaning |
| --- | --- | --- |
| `%s` | Confirmed | Text |
| `%d`, `%i`, `%u` | Observed | A number |
| `%ld` | Observed | A number. Treated like `%d`. |
| `%02d` | Observed | At least 2 characters including a minus sign, filled with zeros, such as a clock's `05:30` |
| `%.2d` | Observed | At least 2 digits not including a minus sign, such as a skill's `5.07` |
| `%3d` | Not seen | At least 3 characters, filled with spaces |
| `%%` | Observed | One percent sign |

Some real text uses a lone `%` or `$` as a placeholder, as in `to sell % for $`, or
`<%>` in chat messages. Readers leave these for game code. A placeholder with no argument
left stays as written, so the mistake is visible.

## Where FreeSO differs

FreeSO's loader is the closest thing to a reference, but it is a reconstruction too.
These differences are deliberate.

| Case | FreeSO | This specification |
| --- | --- | --- |
| A note above a value | Becomes the only key, so the value has no position | The value has both |
| Text after a closing caret | Can become the next value's key | Ignored |
| `#` and `/*` comments | Treated as text outside values | Comments |
| An indented `//` line inside a value | Part of the value | A comment |
| A repeated key | Last wins | First wins, and it is reported |
| An unclosed value | Misreads the rest of the table | Skipped and reported |

## Checking a reader

A reader should be checked against more than hand-written samples. Hand-written files
tend to hold only the shapes their author already knows about, and real tables have
keyless values, indented keys, notes, CRLF, and Windows-1252, often at once. With an
install, check that every string a version's `.uis` files use is found, and try lookups
that should miss as well as lookups that should succeed. SwiftCST's test
`readsEveryTableOfALocalInstall` reads every table when `TSO_BETA_DIR`, `TSO_CLASSIC_DIR`,
or `TSO_GAME_DIR` is set. Without one, this page's example covers the same shapes.

## History and acknowledgments

This family of parsers began with [CST.NET](https://github.com/tonytins/cstdotnet), a rewrite
of [FreeSO](https://github.com/riperiperi/FreeSO)'s loader, meant to be reusable and to work as
a possible drop-in replacement in a fork of FreeSO. It started out against real files, but its
unit tests used sample data alone, covering as many edge cases as could be thought of for a
general-purpose library. CST began with TSO, but it's handy enough on its own for any project,
and it offers a clear path to translation.

Later rewrites, including [cstrs](https://github.com/tonytins/cstrs) and SwiftCST, were a way to
learn how complex algorithms work. Variables were the part that kept tripping them up, and sample
data couldn't show how much real tables actually hold.

[Hudini](https://github.com/tonytins/Hudini) brought the family full circle, back to reading
TSO's own tables for a reimplementation of the game. This specification was first reconstructed
there, and Hudini's reader finds the same text as SwiftCST's on every key in all three versions.

Treating text outside carets as ignorable first appears in cstrs, and keys above values and
unclosed-value handling come from SwiftCST.
