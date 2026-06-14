import Testing
import Foundation
@testable import SwiftGUDHI

@Test func alphaComplexCircleHasLoop() {
    // Alpha complex of a circle (CGAL/Epeck path) must recover the loop.
    let n = 40
    let circle: [[Double]] = (0..<n).map { i in
        let a = 2.0 * Double.pi * Double(i) / Double(n)
        return [cos(a), sin(a)]
    }
    let st = Alpha.complex(pointCloud: circle, precision: .safe)
    #expect(st.numVertices == n)

    let diagram = st.persistence(persistenceDimMax: true)
    let h1 = diagram.filter { $0.dimension == 1 }
    #expect(h1.count >= 1, "alpha complex of a circle should have an H1 class")
    let longest = h1.map { $0.death - $0.birth }.max() ?? 0
    #expect(longest > 0.1, "the loop should be prominent; got \(longest)")
}

@Test func bottleneckBasics() {
    // Identical diagrams: distance 0.
    let d: [(Double, Double)] = [(0, 1), (0.5, 2)]
    #expect(DiagramDistance.bottleneck(d, d, delta: 0) == 0)

    // One point (0,3) vs empty: matched to the diagonal, distance = 3/2.
    let one: [(Double, Double)] = [(0, 3)]
    let empty: [(Double, Double)] = []
    let dist = DiagramDistance.bottleneck(one, empty, delta: 0)
    #expect(Swift.abs(dist - 1.5) < 1e-9, "expected 1.5, got \(dist)")
}

@Test func wassersteinBasics() {
    // Identical diagrams: distance 0.
    let d: [(Double, Double)] = [(0, 1), (1, 4)]
    #expect(DiagramDistance.wasserstein(d, d, order: 1) == 0)

    // Point-to-point matching under the default L∞ ground metric is monotone in
    // the gap between the matched points.
    let close = DiagramDistance.wasserstein([(0, 2)], [(0, 3)], order: 1)
    let apart = DiagramDistance.wasserstein([(0, 2)], [(0, 5)], order: 1)
    #expect(close > 0)
    #expect(apart > close, "more separated points cost more (\(apart) vs \(close))")

    // Under a Euclidean ground metric, matching-to-diagonal cost scales with how
    // far the point is from the diagonal.
    let near = DiagramDistance.wasserstein([(0, 2)], [], order: 1, internalP: 2)
    let far = DiagramDistance.wasserstein([(0, 4)], [], order: 1, internalP: 2)
    #expect(far > near, "farther-from-diagonal point should cost more (\(far) vs \(near))")
}

@Test func alphaVsRipsAgreeOnLoopCount() {
    // Both constructions should agree: a circle has exactly one 1-cycle.
    let n = 30
    let circle: [[Double]] = (0..<n).map { i in
        let a = 2.0 * Double.pi * Double(i) / Double(n)
        return [cos(a), sin(a)]
    }
    let alpha = Alpha.complex(pointCloud: circle).persistence(persistenceDimMax: true)
    let rips = Rips.complex(pointCloud: circle, maxEdgeLength: 2.5, maxDimension: 2)
        .persistence(persistenceDimMax: true)
    let alphaH1 = alpha.filter { $0.dimension == 1 && ($0.death - $0.birth) > 0.05 }.count
    let ripsH1 = rips.filter { $0.dimension == 1 && ($0.death - $0.birth) > 0.5 }.count
    #expect(alphaH1 == 1)
    #expect(ripsH1 == 1)
}
