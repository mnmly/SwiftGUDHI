# ``SwiftGUDHIFull``

Topological Data Analysis on Apple platforms, bridged from
[GUDHI](https://gudhi.inria.fr) through Swift/C++ interoperability.

## Overview

SwiftGUDHI turns geometry and data into *topology*: build a simplicial or
cubical complex from a point cloud, image, or distance matrix, then compute its
**persistent homology** — the multi-scale catalogue of connected components,
loops, and voids that summarises the data's shape.

The hub type is ``SimplexTree``: every complex builder (``Rips``, ``Alpha``,
``Witness``, ``Tangential``) returns one, and persistence is computed on it.
Images use ``CubicalComplex`` instead. Diagrams are compared with
``DiagramDistance``, point clouds are thinned with ``Subsampling``, and
``Mapper`` collapses a high-dimensional embedding into a small, renderable graph
of clusters and overlaps.

Rendering is intentionally out of scope — SwiftGUDHI only computes; draw the
results with Metal/SwiftUI.

```swift
import SwiftGUDHI

let points: [[Double]] = loadPointCloud()

// Rips complex → persistent homology
let tree = Rips.complex(pointCloud: points, maxEdgeLength: 2.5, maxDimension: 2)
let diagram = tree.persistence(persistenceDimMax: true)

for feature in diagram where !feature.isEssential {
    print("H\(feature.dimension): \(feature.birth) … \(feature.death)")
}
print("Betti numbers:", tree.bettiNumbers)   // e.g. [1, 1] for a circle
```

All inputs are plain `[[Double]]` matrices (one row per point) or `[Double]`
diagrams of `(birth, death)` points. The package targets macOS 14+ (arm64); any
target that imports it must also enable C++ interop
(`swiftSettings: [.interoperabilityMode(.Cxx)]`).

## Topics

### The simplex tree & persistence

- ``SimplexTree``
- ``PersistenceInterval``
- ``FilteredSimplex``

### Building complexes from point clouds

- ``Rips``
- ``Alpha``
- ``Witness``
- ``Tangential``

### Image & grid persistence

- ``CubicalComplex``

### Comparing persistence diagrams

- ``DiagramDistance``

### Preprocessing point clouds

- ``Subsampling``

### Mapper — the shape of an embedding set

- ``Mapper``
- ``MapperGraph``
- ``MapperNode``
- ``MapperEdge``
