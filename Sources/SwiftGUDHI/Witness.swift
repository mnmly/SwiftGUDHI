// Witness.swift — witness complexes (landmark-based reconstruction).

import GudhiCore

public enum Witness {
    /// Witness complex from a precomputed nearest-landmark table. Each witness
    /// lists its `k` nearest landmarks (index, squared distance), nearest first.
    /// All rows must share the same `k`.
    public static func fromTable(_ table: [[(landmark: Int, squaredDistance: Double)]],
                                 maxAlphaSquare: Double = .infinity,
                                 limitDimension: Int = -1) -> SimplexTree {
        let k = table.first?.count ?? 0
        var indices = [Int32](); indices.reserveCapacity(table.count * k)
        var distances = [Double](); distances.reserveCapacity(table.count * k)
        for row in table {
            precondition(row.count == k, "SwiftGUDHI: witness table rows must share k")
            for e in row { indices.append(Int32(e.landmark)); distances.append(e.squaredDistance) }
        }
        return indices.withUnsafeBufferPointer { ip in
            distances.withUnsafeBufferPointer { dp in
                SimplexTree(gudhi_swift.witnessComplexFromTable(
                    ip.baseAddress, dp.baseAddress, Int32(table.count), Int32(k),
                    maxAlphaSquare, Int32(limitDimension)))
            }
        }
    }
}
