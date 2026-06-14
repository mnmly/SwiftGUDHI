import Testing
import Foundation
@testable import SwiftGUDHI

private func circle(_ n: Int, radius: Double = 1) -> [[Double]] {
    (0..<n).map { i in
        let a = 2.0 * Double.pi * Double(i) / Double(n)
        return [radius * cos(a), radius * sin(a)]
    }
}

@Test func euclideanWitnessBuilds() {
    let witnesses = circle(80)
    let landmarks = Subsampling.farthestPoints(witnesses, count: 16, startingPoint: 0)
    let st = Witness.euclidean(landmarks: landmarks, witnesses: witnesses,
                               maxAlphaSquare: 0.5, limitDimension: 2)
    #expect(st.numVertices == 16)
    #expect(st.numSimplices > 16, "witnesses should induce edges among landmarks")
    // Persistence runs through the whole pipeline.
    let diagram = st.persistence(persistenceDimMax: true)
    #expect(!diagram.isEmpty)
}

@Test func witnessFromTableBuilds() {
    // 3 landmarks, 3 witnesses each nearest to a different pair — a triangle.
    let table: [[(landmark: Int, squaredDistance: Double)]] = [
        [(0, 0.0), (1, 1.0), (2, 1.0)],
        [(1, 0.0), (2, 1.0), (0, 1.0)],
        [(2, 0.0), (0, 1.0), (1, 1.0)],
    ]
    let st = Witness.fromTable(table, maxAlphaSquare: 2.0, limitDimension: 2)
    #expect(st.numVertices == 3)
}

@Test func tangentialComplexBuilds() {
    // Points on a circle = a 1-manifold; intrinsic dimension 1.
    let pts = circle(30)
    let st = Tangential.complex(pointCloud: pts, intrinsicDimension: 1)
    #expect(st.numVertices == 30)
    #expect(st.numSimplices > 0)
}

@Test func edgeCollapsePreservesLoop() {
    // Edge collapse must preserve persistent homology: the circle's loop survives.
    let pts = circle(40)

    let full = Rips.complex(pointCloud: pts, maxEdgeLength: 2.5, maxDimension: 2)
    let fullH1 = full.persistence(persistenceDimMax: true)
        .filter { $0.dimension == 1 && ($0.death - $0.birth) > 0.5 }.count

    // Build the 1-skeleton, collapse, then expand and compare.
    let collapsed = Rips.complex(pointCloud: pts, maxEdgeLength: 2.5, maxDimension: 1)
    let before = collapsed.numSimplices
    collapsed.collapseEdges(iterations: 2)
    let after = collapsed.numSimplices
    collapsed.expansion(maxDimension: 2)
    let collapsedH1 = collapsed.persistence(persistenceDimMax: true)
        .filter { $0.dimension == 1 && ($0.death - $0.birth) > 0.5 }.count

    #expect(after <= before, "collapse should not increase the edge count")
    #expect(collapsedH1 == fullH1, "collapse must preserve the H1 loop (\(collapsedH1) vs \(fullH1))")
    #expect(fullH1 == 1)
}
