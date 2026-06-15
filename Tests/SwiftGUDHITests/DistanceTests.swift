import Testing
import Foundation
@testable import SwiftGUDHI

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
