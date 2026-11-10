# CST Format

> **Draft.** This specification is being reworked now that CST is known to predate The Sims
> Online. Rules may change, and the open questions are marked **Unsettled** below.

Caret-Separated Text (CST) is a string-text format: a plain-text resource format that holds a
table of values, each written between two carets and found by its key or by its position. Maxis
never published a specification, so this one is reconstructed from the games' files and from the
parsers written for them. [SwiftCST](../README.md) implements it.

## Where CST comes from

CST is older than The Sims Online (TSO). Its earliest known use is in Sims Steering Committee
(SSC), a prototype of The Sims, where its tables hold animation names, file and resource names,
body and texture names, motive curves, and tutorial goals. Most of them are not text for players
at all.

SSC's executable names a resource-file system, with classes such as `FlatResFile`,
`ChainResFile`, `MultiResFile`, and `IFFResFile`, and resource types named `kStringSetResType`
and `kCStringSetResType`. Its tables sit in `.dir` folders beside the `.iff` files of the same
name, such as `sigmund.dir` beside `sigmund.iff`. The likely reading is that a `.dir` is a
resource file kept as loose files, and that a CST file is a string set written out as text (not
Confirmed: no SSC code has been read, only its file names and strings).

TSO later used the same format for its interface text, in `uitext.dir`, and gave it new jobs
there, such as references between tables and a script for the credits. That history explains
why TSO's tables use CST in ways a plain translation file wouldn't: the format was never only
for translation.

## How sure each rule is

No rule here has been checked against either game while it runs. Each carries one of these
labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Real files do this in every version checked where it comes up, and something shows how a game reads it: FreeSO's loader, a `.uis` file, or a table's own notes. |
| **Observed** | Real files do this, but nothing shows how a game treats it. |
| **Unsettled** | The evidence does not decide it. The choice is stated, and it may change. |
| **Not seen** | No real file does this. The rule comes from an earlier parser or from design, and readers should accept it anyway. |

The evidence comes from four installs:

| | SSC | TSO beta 1.3.2.121 | TSO base game 1.145.1.0 | TSO New & Improved 1.1097.1.0 |
| --- | ---: | ---: | ---: | ---: |
| Tables | 24 | 112 | 113 | 137 |
| Values | 1,606 | 2,561 | 2,795 | 3,588 |
| After a key on the same line | 109 | 1,383 | 1,454 | 2,150 |
| With no key on the same line | 1,497 | 1,178 | 1,341 | 1,438 |
| Where tables live | `<name>.dir` beside `<name>.iff` | `gamedata/uitext.dir` | `gamedata/uitext.dir` | `gamedata/uitext/english.dir` |

Eighteen of SSC's tables are the same two tables kept for each of nine people, nearly alike, so
it holds fewer distinct shapes than its count suggests.

## Readers and wrappers

This specification describes two layers:

- A **reader** turns the text of one table into its values, in file order, with each
  value's key and name. It knows nothing about files, other tables, or the game.
- A **wrapper** finds tables on disk and answers lookups for a program, the way a game's own
  code does. Position lookups, layered tables, and references belong here, because they depend
  on how a game uses its tables. They are marked **Wrapper** below.

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

- **Names (Confirmed):** a table is a file named for its ID and a name. TSO writes
  `_<id>_<name>.cst`, and SSC writes `#<id>#<name>.cst`, where `<id>` is a decimal number.
  Lookups use only the ID. The extension's case does not matter.
- **Other files (Observed):** TSO's base game and beta also hold an unnumbered, empty
  `objectdata.dir/gamecompdrawacard.cst`. Readers should ignore files that do not
  follow the pattern.
- **TSO's layout (Confirmed):** New & Improved uses `gamedata/uitext/<language>.dir`.
  Earlier versions have one language in `gamedata/uitext.dir`.
- **SSC's layout (Observed):** tables sit in `.dir` folders. Shared tables are in
  `Global/Global.dir` and `Shell.dir`, and each person in `Objects` has a `<person>.dir` beside
  `<person>.iff`. Table IDs repeat across folders, and a person's table can override the global
  one with the same ID, as described under [Layered tables](#layered-tables-wrapper).
- **`.uis` references (Confirmed, TSO):** a `.uis` file names a table with `stringDir` and
  `stringTable`, and an entry with `stringIndex`. Every real `stringDir` is `UIText`.

## Encoding and line endings

- **Encoding (Confirmed):** a reader must accept UTF-8, with or without a byte order
  mark, and a wrapper loading files must fall back to Windows-1252. TSO's beta and base game
  have three non-UTF-8 tables, and New & Improved has one, the credits. Every SSC table, and
  most TSO tables, are plain ASCII.
- **Line endings (Observed):** real tables use CRLF, except one TSO table with no line break at
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
   value's name. FreeSO looks up TSO's table 137 by names such as `kPErrLocationOutOfBounds`,
   written this way. Others are plainly notes, such as `tooltips`, or labels, such as SSC's
   `house 7` and `Energy`. Nothing in the file separates a name from a note.
4. **Nothing above (Confirmed):** the value has no key or name.

Blank lines and comments between a line and its value do not matter.

### Numbers with a separator

**Unsettled.** SSC writes some keys as a number followed by a period or colon:

```text
1.new house window name
	^New World^

5.
	^:not used^

1:^biped^
```

Today, `1:` is the whole key of `biped` under rule 1, and `1.new house window name` and `5.`
are names under rule 3, so a lookup for `1` or `5` finds neither. The numbering, and SSC's
notes describing what each slot is for, suggest the number is meant as the key and the rest as
a label. Reading them that way is planned, and would change what lookups return for these
shapes. No line in any of the three TSO versions starts with a number and a period or colon,
so the change would only affect tables like SSC's.

### Positions (Wrapper)

A value with no key of its own, under rules 3 and 4, is also known by its position.
**Position** counts every value in the table, including those with keys and those never
closed. Keys are text, so position 5 is the key `5`.

A key written in the file always wins over a position, so a position only reaches a value
with no key of its own (Not seen: no real table has this collision). A name can't collide
with a position, because a number on the line above a value is its key.

Positions matter more in SSC than in TSO: 1,420 of SSC's 1,606 values have neither a key nor a
name, and SSC's tables say which slots are "old unused entries" and which are "for motive
failures", so code finds them by position alone.

**Starting from 0 is Unsettled.** FreeSO counts from 0, and SwiftCST's `UIText` and Hudini
do too. But nothing in TSO's files requires it, and two things point the other way: no
numbered TSO table starts at 0, while 111 start at 1, and table 136's own notes say "Strings
1-3". Only one `.uis` string in each TSO version uses a position, `EALabelText` in
`credits.uis`, at 5. From 0 that is a copyright line, and from 1 it is a line about Maxis,
and either suits the name. That screen requires logging in, so with the game's servers gone
it can't be checked by running the game. A screenshot from when it was live would settle it.

SSC adds a weak hint toward 0. Its animation tables follow each value with the name of a C
constant, such as `^adult-tantrum^	AnimMotiveTantrum`, which suggests the order once matched
an enumeration in code, and C enumerations start at 0. SSC's numbered keys start at 1, though,
which leaves the question open. Tables read in order, as described under
[What values hold](#what-values-hold), work either way.

### Text outside values

Text between values that does not become a key or name is ignored (Confirmed). This
includes any lines above the nearest one, and text after a closing caret on the same line,
which describes the value before it, whether that value took one line or several. TSO's
tables use this for translators' notes, and SSC's for the name of the constant each value
stands for.

### Comments

- **`//` (Confirmed):** a line whose first non-space characters are `//` is a comment.
  Real tables in both games use these.
- **`#` (Observed):** the same, though only two real lines start this way, both TSO headers
  naming their file. Since text outside values is ignored anyway, little depends on it.
- **`/*` (Not seen):** a line whose first non-space characters are `/*` starts a comment
  that runs to the end of the line holding `*/`.

Comments are removed before anything else, so a comment line inside a value is not part
of it. No real value has such a line, so this case is Not seen too.

### Values

- **Multiline (Confirmed):** a value runs until its closing caret, and keeps its line
  breaks, blank lines, and spacing exactly. SSC's tutorial goals run for several paragraphs.
- **Empty (Observed):** `^^` is a valid, empty value that still takes a position. TSO tables
  such as 138 hold dozens of them, and in SSC an empty value can mean "use the base table's
  value", as described under [Layered tables](#layered-tables-wrapper).

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
  a program cannot tell from real text. SwiftCST's `CSTTable.value(forKey:)` and
  `UIText.textIfPresent` return `nil`, and its older string-returning lookups still return
  `*** MISSING ***` for compatibility.

## What values hold

A value is not always text for a player to read, and code decides what it means. A reader
should hand values back untouched (Observed).

| Game | Table | Values hold |
| --- | --- | --- |
| SSC | 240 | Directory, file, and resource names, such as `Textures/` and `Tools.rsrc` |
| SSC | 128, 130 | Animation names, each followed by the constant it stands for |
| SSC | 200 | Body, texture, and bone names, such as `HEAD` and `R_HAND` |
| SSC | 300, in `Global.dir` | Motive curves as points, such as `(10,10),(-45,0)` |
| SSC | 300, in `Shell.dir` | Tutorial goals for each house, several paragraphs long |
| TSO | 148 | Text, then a number of milliseconds to show it |
| TSO | 145 | Coordinates such as `(88;6)` alternating with button labels |
| TSO | 161 | Keyboard shortcuts such as `^p^ pause`, described by the text after each value |
| TSO | 242 | The credits, as instructions for their renderer |

### The credits

TSO's table 241 holds the credits screen's ordinary text. Table 242 is a small script for the
scrolling credits, which documents itself in comments and credits Blazej Stompel for the
system. Its values have no keys, so they are read in order:

```text
^<scroll speed>^
^NewLine|<line height>|<font size>|<font color>^
^LineEntry|<Center, Left, Right, or a left offset>|<text>|<optional underline color>^
```

Colors are `r,g,b`. Most of TSO's values with no key are this script: 735 of 1,178 in beta,
896 of 1,341 in the base game, and 980 of 1,438 in New & Improved. Parsing it belongs to the
code that draws the credits, not to a reader.

## Layered tables (Wrapper)

**Observed, from SSC's own notes.** SSC keeps a global table 130 of person animations in
`Global.dir`, and each person has a table 130 of their own. The global one begins "These are
just placeholders for what the person's table should be overriding", and the person's begins
"blank string get filled in from the global table". So a person's table is laid over the
global one by position, and an empty value there means "use the global table's value".

A wrapper that supports this looks a position up in the top table first and falls back to the
base table when the value is empty or missing. Whether an empty value always means "fall back"
or only in tables meant as overrides is Unsettled, since TSO's empty values look like real empty
text. A reader knows nothing about layers and returns empty values as written.

## Repeated keys

**Unsettled.** TSO's table 237 is the only real case, in all three TSO versions: its key `2`
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
number. SSC's tables have no placeholders, so every row below comes from TSO.

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

FreeSO's loader is the closest thing to a reference for TSO, but it is a reconstruction too.
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
that should miss as well as lookups that should succeed. SwiftCST's tests read every table
of a local install when `SSC_GAME_DIR`, `TSO_BETA_DIR`, `TSO_CLASSIC_DIR`, or `TSO_GAME_DIR`
is set. Without one, this page's example covers the same shapes.

## History and acknowledgments

This family of parsers began with [CST.NET](https://github.com/tonytins/cstdotnet), a rewrite
of [FreeSO](https://github.com/riperiperi/FreeSO)'s loader, meant to be reusable and to work as
a possible drop-in replacement in a fork of FreeSO. It started out against real files, but its
unit tests used sample data alone, covering as many edge cases as could be thought of for a
general-purpose library. The family first knew CST from TSO, but it's handy enough on its own
for any project, and it offers a clear path to translation.

Later rewrites, including [cstrs](https://github.com/tonytins/cstrs) and SwiftCST, were a way to
learn how complex algorithms work. Variables were the part that kept tripping them up, and sample
data couldn't show how much real tables actually hold.

[Hudini](https://github.com/tonytins/Hudini) brought the family full circle, back to reading
TSO's own tables for a reimplementation of the game. This specification was first reconstructed
there, and Hudini's reader finds the same text as SwiftCST's on every key in all three TSO
versions. SSC's tables later showed that the format began before TSO, as a general store for a
game's strings.

Treating text outside carets as ignorable first appears in cstrs, and keys above values and
unclosed-value handling come from SwiftCST.
