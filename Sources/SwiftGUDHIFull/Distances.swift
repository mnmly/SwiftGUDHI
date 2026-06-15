// Distances.swift — bottleneck and Wasserstein distances between persistence
// diagrams (via the bundled Hera).

import GudhiCoreFull

public enum DiagramDistance {
    /// Bottleneck distance between two diagrams.
    /// - Parameters:
    ///   - a: first diagram as `(birth, death)` points (`death` may be `.infinity`).
    ///   - b: second diagram as `(birth, death)` points.
    ///   - delta: relative error (`0` => exact).
    public static func bottleneck(_ a: [(Double, Double)],
                                  _ b: [(Double, Double)],
                                  delta: Double = 0.01) -> Double {
        flatDiagram(a).withUnsafeBufferPointer { pa in
            flatDiagram(b).withUnsafeBufferPointer { pb in
                gudhi_swift.bottleneckDistance(pa.baseAddress, Int32(a.count),
                                               pb.baseAddress, Int32(b.count), delta)
            }
        }
    }

    /// Wasserstein distance W_p between two diagrams.
    /// - Parameters:
    ///   - a: first diagram as `(birth, death)` points.
    ///   - b: second diagram as `(birth, death)` points.
    ///   - order: the exponent p.
    ///   - internalP: ground metric on R² (default Euclidean, `2`). Note: the
    ///     bundled Hera does not support the L∞ ground metric for Wasserstein —
    ///     use a finite `internalP` (bottleneck already is the L∞ limit).
    ///   - delta: relative error.
    public static func wasserstein(_ a: [(Double, Double)],
                                   _ b: [(Double, Double)],
                                   order: Double = 1,
                                   internalP: Double = 2,
                                   delta: Double = 0.01) -> Double {
        let ip = internalP.isInfinite ? -1.0 : internalP
        return flatDiagram(a).withUnsafeBufferPointer { pa in
            flatDiagram(b).withUnsafeBufferPointer { pb in
                gudhi_swift.wassersteinDistance(pa.baseAddress, Int32(a.count),
                                                pb.baseAddress, Int32(b.count),
                                                order, ip, delta)
            }
        }
    }

    /// Convenience: distances over `PersistenceInterval` arrays in a fixed dimension.
    public static func bottleneck(_ a: [PersistenceInterval], _ b: [PersistenceInterval],
                                  delta: Double = 0.01) -> Double {
        bottleneck(a.map { ($0.birth, $0.death) }, b.map { ($0.birth, $0.death) }, delta: delta)
    }
}

@usableFromInline
func flatDiagram(_ points: [(Double, Double)]) -> [Double] {
    var flat = [Double]()
    flat.reserveCapacity(points.count * 2)
    for (b, d) in points { flat.append(b); flat.append(d) }
    return flat
}
