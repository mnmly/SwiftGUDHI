// Subsampling.swift — point-cloud subsampling (landmark selection).

import CxxStdlib
import GudhiCore

public enum Subsampling {
    /// Greedy farthest-point sampling: `count` well-spread landmarks.
    /// - Parameters:
    ///   - points: rows of equal-length coordinate vectors.
    ///   - count: number of landmarks to select.
    ///   - startingPoint: index of the first landmark (nil => random).
    ///   - metric: use the triangle-inequality-accelerated variant.
    public static func farthestPoints(_ points: [[Double]], count: Int,
                                      startingPoint: Int? = nil,
                                      metric: Bool = false) -> [[Double]] {
        let rows = points.count, cols = points.first?.count ?? 0
        return flatten(points).withUnsafeBufferPointer { p in
            matrixToSwift(gudhi_swift.chooseNFarthestPoints(
                p.baseAddress, Int32(rows), Int32(cols),
                Int32(count), Int32(startingPoint ?? -1), metric))
        }
    }

    /// `count` points chosen uniformly at random.
    public static func randomPoints(_ points: [[Double]], count: Int) -> [[Double]] {
        let rows = points.count, cols = points.first?.count ?? 0
        return flatten(points).withUnsafeBufferPointer { p in
            matrixToSwift(gudhi_swift.pickNRandomPoints(
                p.baseAddress, Int32(rows), Int32(cols), Int32(count)))
        }
    }

    /// Keep points no two of which are closer than `sqrt(minSquaredDistance)`.
    public static func sparsify(_ points: [[Double]], minSquaredDistance: Double) -> [[Double]] {
        let rows = points.count, cols = points.first?.count ?? 0
        return flatten(points).withUnsafeBufferPointer { p in
            matrixToSwift(gudhi_swift.sparsifyPointSet(
                p.baseAddress, Int32(rows), Int32(cols), minSquaredDistance))
        }
    }
}

/// Convert a C++ `std::vector<std::vector<double>>` to a Swift `[[Double]]`.
func matrixToSwift(_ matrix: gudhi_swift.DoubleMatrix) -> [[Double]] {
    var out: [[Double]] = []
    out.reserveCapacity(matrix.size())
    for row in matrix {
        var r = [Double]()
        r.reserveCapacity(row.size())
        for x in row { r.append(x) }
        out.append(r)
    }
    return out
}
