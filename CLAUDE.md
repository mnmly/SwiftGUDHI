# SwiftGUDHI

Swift bindings for [GUDHI](https://gudhi.inria.fr) (Topological Data Analysis),
built on a de-templated C++ facade consumed via Swift/C++ interop. macOS 14+,
arm64.

## Architecture

- The compiled C++ facade ships as `Frameworks/GudhiCore.xcframework` (a binary
  target), built by the sibling repo
  `../../cpp/gudhi-xcframework-builder` (run its `make`, which mirrors the
  xcframework here). The Swift sources in `Sources/SwiftGUDHI/` are thin,
  idiomatic wrappers over the imported `gudhi_swift` C++ API.
- Any target importing `SwiftGUDHI` must also enable C++ interop
  (`swiftSettings: [.interoperabilityMode(.Cxx)]`) — a known SwiftPM constraint
  (swift#66156).
- Upstream is pinned to GUDHI `gudhi-release-3.12.0`; the pin lives in the
  builder repo's `GUDHI_VERSION`.

## Documentation

`SwiftGUDHI` ships DocC-generated reference docs (see
`Sources/SwiftGUDHI/Documentation.docc/` and `Scripts/build_docs.sh`).
**`///` doc comments on public symbols are published** to the static site and
(if `EMIT_LLMS_TXT=1` is used) into `docs/llms.txt`.

When you add or modify a `public` declaration:

- Write a `///` doc comment. One-sentence summary, then a paragraph if the *why*
  is non-obvious. Skip restating what the signature already says.
- Document each parameter with `- Parameter name:` (or a `- Parameters:` block).
  Use the **internal** parameter name when there's an external label, and
  document **all** parameters of a function or **none** — DocC warns on partial
  coverage.
- Cross-reference related symbols with double-backtick links, e.g.
  `` ``SimplexTree/persistence(coeffField:minPersistence:persistenceDimMax:)`` ``.
  DocC link syntax is signature-sensitive: `foo(_:)` and `foo(_:_:)` differ.
- When you add a new top-level symbol that belongs in the curated sidebar, add it
  under the appropriate `## Topics` group in
  `Sources/SwiftGUDHI/Documentation.docc/SwiftGUDHI.md`. Topics are organized by
  *user task*, not alphabetic order.

Verify before declaring documentation work done:

```bash
Scripts/build_docs.sh
```

Expect exit 0 and no new "missing documentation", "doesn't exist at", or
"external name used to document parameter" warnings attributable to your changes.
