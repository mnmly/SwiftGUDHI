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
| `Alpha` | Alpha complex (CGAL, fast/safe/exact precision) |
| `CubicalComplex` | Bitmap cubical complex (image/grid persistence) |
| `Witness`, `Tangential` | Witness (Euclidean + table) and Tangential complexes |
| `DiagramDistance` | bottleneck + Wasserstein between diagrams |
| `Subsampling` | farthest-point / random / sparsify |
| `Mapper` | Mapper (nerve of a functional cover) — graph of clusters + overlaps |

Pinned to GUDHI **`gudhi-release-3.12.0`** (v3.12.0). `Mapper.version` reports
the exact upstream build it was compiled against; full provenance ships in the
xcframework's `Headers/GUDHI_PROVENANCE.txt`. The pin is managed in the sibling
builder repo (`cpp/gudhi-xcframework-builder/GUDHI_VERSION`).

## Setup

The package depends on a prebuilt `Gudhi.xcframework` in `Frameworks/`. Produce
it from the sibling builder repo:

```sh
cd ../../cpp/gudhi-xcframework-builder
cp config.sh.example config.sh        # SWIFT_PACKAGE_FRAMEWORKS_DIR points here
make                                  # builds + mirrors Gudhi.xcframework into Frameworks/
```

Then:

```sh
swift build
swift test
```

> Any Swift target that uses `SwiftGUDHI` must also enable C++ interop
> (`swiftSettings: [.interoperabilityMode(.Cxx)]`) — a known SwiftPM constraint
> (swift#66156).

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

// Alpha complex (sparser, exact filtration values) — great for low-D clouds
let alpha = Alpha.complex(pointCloud: points, precision: .safe)
let alphaH1 = alpha.persistence().filter { $0.dimension == 1 }

// Compare two diagrams
let d = DiagramDistance.bottleneck(diagram, alpha.diagram)
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
