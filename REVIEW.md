# Review Guide

Use this checklist when reviewing a change to SwiftCST. It is adapted from the
contributor and review practices in [NVIDIA FLARE's contribution guide](https://github.com/NVIDIA/NVFlare/blob/main/CONTRIBUTING.md),
with checks tailored to this Swift package and the CST format.

## Before reviewing

- Read the change description and the relevant code and tests.
- Identify the user-visible behavior or problem the change is intended to address.
  If it refers to an issue or design discussion, check that the change addresses
  that context.
- Check available build, test, and CI results. Run `swift build` or `swift test`
  when the change or its verification warrants it; report checks that could not
  be run.

## Review checklist

- Does the behavior match the stated intent, including boundary cases such as empty
  values, keys with spaces, indented keys, values with no key, comments inside values,
  and every line ending?
- Could a lookup now return another entry's text? A key must match whole, and an
  unclosed value must not swallow the entries after it.
- Are public API names, defaults, and behavior clear and consistent with existing
  APIs? Could the change break existing callers or change what a lookup returns?
- Does each change belong to its layer? The CST core should stay general purpose, and
  `UIText` should reach it only through the public API.
- If the change affects how files are read, was it checked against real tables, and does
  it agree with the specification? Does a malformed entry get reported rather than
  stopping the read?
- Do new standard library or Foundation APIs need a newer Apple OS than the package
  supports? A Linux build does not show this.
- Do focused tests cover the changed behavior? Is a run from a scratch package needed
  in addition to the tests?
- Are the READMEs and changelog updated when they are affected?

## Writing review comments

- Report concrete correctness, compatibility, reliability, or missing-test
  concerns; do not block changes on personal style preferences.
- Make each comment specific, constructive, and actionable. Point to the
  smallest relevant location and explain the impact and a useful next step.
- Prioritize findings by impact:
  - **Blocking**: prevents the package from building or causes severe,
    unavoidable failure in normal use.
  - **High**: breaks an existing public behavior, returns wrong text, or misreads
    the entries after a common input.
  - **Medium**: causes a limited but meaningful behavior or reliability issue.
  - **Low**: a small edge case or non-blocking improvement.
- If no actionable issues remain, say so and note any important checks that
  were not run.
