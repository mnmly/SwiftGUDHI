import Testing
import Foundation
@testable import SwiftGUDHI

// Connected-components / cycle helpers over a MapperGraph.
private struct DSU {
    var parent: [Int: Int] = [:]
    mutating func find(_ x: Int) -> Int {
        if parent[x] == nil { parent[x] = x }
        var r = x
        while parent[r]! != r { r = parent[r]! }
        var cur = x
        while parent[cur]! != r { let n = parent[cur]!; parent[cur] = r; cur = n }
        return r
    }
    mutating func union(_ a: Int, _ b: Int) { parent[find(a)] = find(b) }
}

private func components(_ g: MapperGraph) -> Int {
    var d = DSU()
    for n in g.nodes { _ = d.find(n.id) }
    for e in g.edges { d.union(e.source, e.target) }
    return Set(g.nodes.map { d.find($0.id) }).count
}

private func cycleRank(_ g: MapperGraph) -> Int {
    g.edges.count - g.nodes.count + components(g)
}

@Test func ndLensGridFormsAnAtlasNotAChain() {
    // An 8x8 grid of points. With the 2-D coordinates as the lens, the N-D cover
    // is a grid of cells whose nerve has cycles (a 2-D atlas). With a 1-D lens
    // (x only) the same data collapses to a chain (no cycles).
    var pts: [[Double]] = []
    var lens2: [Double] = []
    var lens1: [Double] = []
    for x in 0..<8 {
        for y in 0..<8 {
            pts.append([Double(x), Double(y)])
            lens2.append(Double(x)); lens2.append(Double(y))
            lens1.append(Double(x))
        }
    }

    var opts = Mapper.Options()
    opts.resolution = 4
    opts.gain = 0.3
    opts.ripsThreshold = 1.1   // connects 4-neighbours (grid spacing 1.0)

    let nd2 = Mapper.build(pointCloud: pts, lensND: lens2, lensDim: 2, options: opts)
    let nd1 = Mapper.build(pointCloud: pts, lensND: lens1, lensDim: 1, options: opts)

    #expect(!nd2.isEmpty)
    // The 2-D cover is res×res cells → many more nodes than the 1-D res cells.
    #expect(nd2.nodes.count > nd1.nodes.count,
            "2-D lens should yield a richer cover (\(nd2.nodes.count) vs \(nd1.nodes.count))")
    // The grid atlas must contain at least one loop.
    #expect(cycleRank(nd2) >= 1, "2-D grid Mapper should have a cycle; got \(cycleRank(nd2))")
    // Every input point lands in some node.
    let covered = Set(nd2.nodes.flatMap { $0.pointIndices })
    #expect(covered.count == pts.count, "covered \(covered.count)/\(pts.count)")
}

@Test func ndLensDim1CoversAllPoints() {
    // The N-D path reimplements the cover (it does NOT call GUDHI's
    // set_cover_from_function), so for lensDim == 1 it is NOT equivalent to
    // `computeMapper` — e.g. a circle's nerve here can fragment rather than form
    // one loop. For exact 1-D behaviour use `Mapper.build(pointCloud:lens:…)`.
    // The robust guarantee the N-D cover always provides: every point lands in
    // some node and the graph is non-empty.
    let n = 60
    let circle: [[Double]] = (0..<n).map { i in
        let a = 2.0 * Double.pi * Double(i) / Double(n)
        return [cos(a), sin(a)]
    }
    let lens = circle.map { $0[0] }   // x-coordinate

    var opts = Mapper.Options()
    opts.resolution = 12
    opts.gain = 0.3
    opts.ripsThreshold = 0.2

    let g = Mapper.build(pointCloud: circle, lensND: lens, lensDim: 1, options: opts)
    #expect(!g.isEmpty)
    #expect(Set(g.nodes.flatMap { $0.pointIndices }).count == n, "every point should be covered")
}
