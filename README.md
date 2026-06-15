# SwiftGUDHI

Swift bindings for [GUDHI](https://gudhi.inria.fr) — Topological Data Analysis on
Apple platforms. Build simplicial/cubical complexes from point clouds, images or
distance matrices, compute persistent homology, compare diagrams, and reduce the
"shape" of high-dimensional data to something you can reason about and render.

Built on a de-templated C++ facade over GUDHI, consumed through **Swift/C++
interoperability** (`.interoperabilityMode(.Cxx)`). macOS 14+, arm64.

## What's bridged

| Swift API | GUDHI |
|---|---|
| `SimplexTree` | Simplex_tree: insert/query/skeleton/star/cofaces, **persistence** (diagram, Betti, intervals, pairs), edge collapse |
| `Rips` | Rips & Sparse-Rips (point cloud or distance matrix) |
| `CubicalComplex` | Bitmap cubical complex (image/grid persistence) |
| `Witness` | Witness complex (table-based) |
| `DiagramDistance` | bottleneck + Wasserstein between diagrams |
| `Subsampling` | farthest-point / random |
| `Mapper` | Mapper (nerve of a functional cover, 1-D + N-D lens) — clusters + overlaps |

> **Permissive (MIT/BSD) build.** CGAL-backed features (Alpha, Tangential,
> Euclidean Witness, sparsify) are GPL-3.0 and excluded here; they live on the
> `full-gpl` branch of the builder repo. Rips covers point-cloud persistence in
> their place. See [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md).

Pinned to GUDHI **`gudhi-release-3.12.0`** (v3.12.0). `Mapper.version` reports
the exact upstream build it was compiled against; full provenance ships in the
xcframework's `Headers/GUDHI_PROVENANCE.txt`. The pin is managed in the sibling
builder repo (`cpp/gudhi-xcframework-builder/GUDHI_VERSION`).

## Setup

Add it as a Swift Package dependency — the prebuilt `GudhiCore.xcframework` is
fetched from the GitHub release automatically (no local build needed):

```swift
.package(url: "https://github.com/mnmly/SwiftGUDHI.git", from: "0.4.0"),
```

> Any Swift target that uses `SwiftGUDHI` must also enable C++ interop
> (`swiftSettings: [.interoperabilityMode(.Cxx)]`) — a known SwiftPM constraint
> (swift#66156).

To iterate locally against a freshly built framework, build it from the sibling
[`gudhi-xcframework-builder`](https://github.com/mnmly/gudhi-xcframework-builder)
(`make` mirrors `GudhiCore.xcframework` into `Frameworks/`) and switch the
`binaryTarget` in `Package.swift` from `url:` back to
`path: "Frameworks/GudhiCore.xcframework"`.

## License

Source: **MIT** ([LICENSE](./LICENSE)). The fetched `GudhiCore.xcframework` links
only permissive libraries (GUDHI MIT, Boost BSL-1.0, Hera BSD) — usable in
closed-source apps. A GPL-3.0 "full" build (adding CGAL Alpha/Tangential/Witness)
is available from the builder's `full-gpl` branch. See
[THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md).

## Usage

### Persistence from a point cloud

```swift
import SwiftGUDHI

let points: [[Double]] = loadPointCloud()

// Rips complex → persistent homology
let st = Rips.complex(pointCloud: points, maxEdgeLength: 2.5, maxDimension: 2)
let diagram = st.persistence(persistenceDimMax: true)
for p in diagram where !p.isEssential {
    print("H\(p.dimension): born \(p.birth), died \(p.death)")
}
print("Betti numbers:", st.bettiNumbers)

// Compare two diagrams
let other = Rips.complex(pointCloud: otherPoints, maxEdgeLength: 2.5, maxDimension: 2)
let d = DiagramDistance.bottleneck(diagram, other.persistence(persistenceDimMax: true))
```

### Image persistence (cubical)

```swift
let image: [[Double]] = grayscale            // rows x cols
let cx = CubicalComplex(dimensions: [image.count, image[0].count],
                        topCells: image.flatMap { $0 })
let holes = cx.persistence().filter { $0.dimension == 1 }
```

### Mapper — the "shape" of an embedding set

```swift
// `embeddings`: rows of equal-length vectors (e.g. art-style embeddings).
let embeddings: [[Double]] = loadEmbeddings()

var opts = Mapper.Options()
opts.resolution = 12        // number of overlapping lens intervals
opts.gain = 0.3             // interval overlap fraction
opts.lensCoordinate = 0     // 1-D lens; or pass an explicit `lens:` array
// opts.ripsThreshold = 0.2 // fixed neighbourhood radius; default (-1) auto-tunes

let graph = Mapper.build(pointCloud: embeddings, options: opts)

for node in graph.nodes {
    print("node \(node.id): \(node.size) points, color \(node.color)")
}
for edge in graph.edges {
    print("\(edge.source) — \(edge.target)")
}
```

Provide your own lens (e.g. a UMAP/PCA axis or eccentricity) and color signal:

```swift
let graph = Mapper.build(pointCloud: embeddings,
                         lens: lensValues,      // one Double per point
                         color: colorValues,    // one Double per point
                         options: opts)
```

Precomputed distances (e.g. cosine between embeddings):

```swift
var opts = Mapper.Options()
opts.ripsThreshold = 0.4    // required (>= 0) for the distance-matrix path
let graph = Mapper.build(distanceMatrix: cosineDistances,
                         lens: lensValues,
                         options: opts)
```

## Output

```swift
struct MapperGraph {
    let nodes: [MapperNode]   // id, size, color, pointIndices
    let edges: [MapperEdge]   // source, target (node ids)
}
```

Rendering is intentionally left to the host app (Metal/SwiftUI) — `SwiftGUDHI`
only computes the graph.

## Status

Covers the major GUDHI surface (see the table above), each verified by a
behavioral test on known topology (loops, components, Betti numbers,
persistence-preserving collapse). Rendering is left to the host app
(Metal/SwiftUI) — SwiftGUDHI only computes. See the builder repo's README for the
roadmap (multi-lens Mapper, extended persistence, iOS, remote distribution).
