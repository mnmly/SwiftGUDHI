import Testing
import Foundation
@testable import SwiftGUDHIFull

@Test func manualSimplexTreeAndPersistence() {
    // A hollow triangle (3 edges, no filling 2-simplex) has one 1-cycle.
    let st = SimplexTree()
    st.insert([0, 1], filtration: 0)
    st.insert([1, 2], filtration: 0)
    st.insert([0, 2], filtration: 0)
    #expect(st.numVertices == 3)
    #expect(st.dimension == 1)
    #expect(st.contains([0, 1]))
    #expect(!st.contains([0, 1, 2]))

    let diagram = st.persistence(persistenceDimMax: true)
    let h1 = diagram.filter { $0.dimension == 1 }
    #expect(h1.count == 1, "hollow triangle has exactly one H1 class; got \(h1.count)")
}

@Test func ripsCircleHasOneLoop() {
    // 40 points on a unit circle. Its Rips persistence must show one long-lived
    // H1 bar (the loop) and an essential H0 component.
    let n = 40
    let circle: [[Double]] = (0..<n).map { i in
        let a = 2.0 * Double.pi * Double(i) / Double(n)
        return [cos(a), sin(a)]
    }

    let st = Rips.complex(pointCloud: circle, maxEdgeLength: 2.5, maxDimension: 2)
    #expect(st.numVertices == n)

    let diagram = st.persistence(persistenceDimMax: true)

    // Exactly one essential H0 feature (the single connected component).
    let essentialH0 = diagram.filter { $0.dimension == 0 && $0.isEssential }
    #expect(essentialH0.count == 1, "expected 1 essential H0, got \(essentialH0.count)")

    // A prominent 1-dimensional loop.
    let h1 = st.intervals(inDimension: 1)
    let longestH1 = h1.map { $0.death - $0.birth }.max() ?? 0
    #expect(!h1.isEmpty, "circle should have an H1 bar")
    #expect(longestH1 > 1.0, "circle's loop should be long-lived; got \(longestH1)")

    // Betti numbers at a mid-scale slice: one component, one loop.
    let betti = st.persistentBettiNumbers(from: 0.5, to: 0.6)
    #expect(betti.count >= 2 && betti[0] == 1 && betti[1] == 1,
            "expected b0=1, b1=1 mid-filtration; got \(betti)")
}
