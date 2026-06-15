// Alpha.swift — Alpha complex (Delaunay-based, CGAL) builder.

import GudhiCoreFull

public enum Alpha {
    /// Numerical precision of the underlying CGAL kernel.
    public enum Precision: Sendable {
        case fast   // Epick_d — fastest, no exactness guarantee
        case safe   // Epeck_d, lazy — robust (default)
        case exact  // Epeck_d, exact filtration values

        var cxx: gudhi_swift.AlphaPrecision {
            switch self {
            case .fast: return .fast
            case .safe: return .safe
            case .exact: return .exact
            }
        }
    }

    /// Build an Alpha complex from a point cloud.
    /// - Parameters:
    ///   - pointCloud: rows of equal-length coordinate vectors.
    ///   - maxAlphaSquare: keep simplices with filtration ≤ this (squared α radius).
    ///   - precision: CGAL kernel precision (default `.safe`).
    ///   - outputSquared: filtration values are squared circumradii when true.
    public static func complex(pointCloud: [[Double]],
                               maxAlphaSquare: Double = .infinity,
                               precision: Precision = .safe,
                               outputSquared: Bool = true) -> SimplexTree {
        let rows = pointCloud.count
        let cols = pointCloud.first?.count ?? 0
        return flatten(pointCloud).withUnsafeBufferPointer { p in
            SimplexTree(gudhi_swift.alphaComplex(
                p.baseAddress, Int32(rows), Int32(cols),
                maxAlphaSquare, precision.cxx, outputSquared))
        }
    }
}
