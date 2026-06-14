import Testing
import Foundation
@testable import SwiftGUDHI

// Minimal union-find to reason about the produced graph's topology.
private struct DSU {
    var parent: [Int: Int] = [:]
    mutating func find(_ x: Int) -> Int {
        if parent[x] == nil { parent[x] = x }
        var r = x
        while parent[r]! != r { r = parent[r]! }
        var cur = x
        while parent[cur]! != r { let next = parent[cur]!; parent[cur] = r; cur = next }
        return r
    }
    mutating func union(_ a: Int, _ b: Int) { parent[find(a)] = find(b) }
}

private func components(_ graph: MapperGraph) -> Int {
    var dsu = DSU()
    for n in graph.nodes { _ = dsu.find(n.id) }
    for e in graph.edges { dsu.union(e.source, e.target) }
    let roots = Set(graph.nodes.map { dsu.find($0.id) })
    return roots.count
}

/// First Betti number of the 1-skeleton: independent cycles = E - V + components.
private func cycleRank(_ graph: MapperGraph) -> Int {
    graph.edges.count - graph.nodes.count + components(graph)
}

@Test func reportsVersion() {
    // version() is stamped from the pinned upstream tag at build time.
    #expect(Mapper.version.contains("GUDHI"))
    #expect(Mapper.version.contains("3.12.0"), "unexpected version string: \(Mapper.version)")
}

@Test func circleProducesALoop() {
    // A clean circle, lensed by its x-coordinate, is the canonical Mapper demo:
    // the two arcs (upper/lower) reconnect at both ends, forming one loop.
    let n = 200
    let circle: [[Double]] = (0..<n).map { i in
        let a = 2.0 * Double.pi * Double(i) / Double(n)
        return [cos(a), sin(a)]
    }

    var opts = Mapper.Options()
    opts.lensCoordinate = 0          // lens = x
    opts.resolution = 12
    opts.gain = 0.3
    opts.ripsThreshold = 0.2         // explicit (deterministic) neighbourhood radius

    let graph = Mapper.build(pointCloud: circle, options: opts)

    #expect(!graph.isEmpty, "expected a non-empty Mapper graph")
    #expect(graph.edges.count >= 1)
    // The circle's topology must survive: at least one independent cycle.
    #expect(cycleRank(graph) >= 1, "circle should yield a loop; got rank \(cycleRank(graph))")

    // Every input point lands in at least one node.
    let covered = Set(graph.nodes.flatMap { $0.pointIndices })
    #expect(covered.count == n, "covered \(covered.count)/\(n) points")
}

@Test func twoBlobsAreTwoComponents() {
    // Two well-separated clusters → two disconnected Mapper components.
    var points: [[Double]] = []
    for gx in 0..<5 {
        for gy in 0..<5 {
            points.append([Double(gx) * 0.1, Double(gy) * 0.1])              // blob A near origin
            points.append([10.0 + Double(gx) * 0.1, Double(gy) * 0.1])       // blob B near x=10
        }
    }

    var opts = Mapper.Options()
    opts.lensCoordinate = 0
    opts.resolution = 10
    opts.gain = 0.3
    opts.ripsThreshold = 0.3         // links within a blob (spacing 0.1), not across (gap ~10)

    let graph = Mapper.build(pointCloud: points, options: opts)

    #expect(!graph.isEmpty)
    #expect(components(graph) == 2, "expected 2 components, got \(components(graph))")
}
