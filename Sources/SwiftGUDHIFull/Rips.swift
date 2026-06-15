// Rips.swift — Rips and Sparse-Rips complex builders.

import GudhiCoreFull

public enum Rips {
    /// Rips complex from a point cloud (Euclidean), expanded to `maxDimension`.
    public static func complex(pointCloud: [[Double]],
                               maxEdgeLength: Double,
                               maxDimension: Int) -> SimplexTree {
        flatten(pointCloud).withUnsafeBufferPointer { p in
            SimplexTree(gudhi_swift.ripsComplexFromPoints(
                p.baseAddress, Int32(pointCloud.count), Int32(pointCloud.first?.count ?? 0),
                maxEdgeLength, Int32(maxDimension)))
        }
    }

    /// Rips complex from a precomputed square distance matrix.
    public static func complex(distanceMatrix: [[Double]],
                               maxEdgeLength: Double,
                               maxDimension: Int) -> SimplexTree {
        flatten(distanceMatrix).withUnsafeBufferPointer { p in
            SimplexTree(gudhi_swift.ripsComplexFromDistanceMatrix(
                p.baseAddress, Int32(distanceMatrix.count), maxEdgeLength, Int32(maxDimension)))
        }
    }

    /// Sparse (approximate) Rips from points. `epsilon` is the approximation factor.
    public static func sparseComplex(pointCloud: [[Double]],
                                     epsilon: Double,
                                     maxEdgeLength: Double,
                                     maxDimension: Int) -> SimplexTree {
        flatten(pointCloud).withUnsafeBufferPointer { p in
            SimplexTree(gudhi_swift.sparseRipsFromPoints(
                p.baseAddress, Int32(pointCloud.count), Int32(pointCloud.first?.count ?? 0),
                epsilon, maxEdgeLength, Int32(maxDimension)))
        }
    }

    /// Sparse (approximate) Rips from a distance matrix.
    public static func sparseComplex(distanceMatrix: [[Double]],
                                     epsilon: Double,
                                     maxEdgeLength: Double,
                                     maxDimension: Int) -> SimplexTree {
        flatten(distanceMatrix).withUnsafeBufferPointer { p in
            SimplexTree(gudhi_swift.sparseRipsFromDistanceMatrix(
                p.baseAddress, Int32(distanceMatrix.count), epsilon, maxEdgeLength, Int32(maxDimension)))
        }
    }
}

/// Row-major flatten of a rectangular `[[Double]]`.
@usableFromInline
func flatten(_ rows: [[Double]]) -> [Double] {
    guard let cols = rows.first?.count else { return [] }
    var flat = [Double]()
    flat.reserveCapacity(rows.count * cols)
    for row in rows {
        precondition(row.count == cols, "SwiftGUDHI: ragged matrix (rows must share a length)")
        flat.append(contentsOf: row)
    }
    return flat
}
