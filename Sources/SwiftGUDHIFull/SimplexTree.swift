// SimplexTree.swift — Swift-idiomatic wrapper over GUDHI's Simplex_tree and its
// persistent (co)homology. The hub object: complex builders return one, and
// persistence is computed on it.

import CxxStdlib
import GudhiCoreFull

public struct SimplexTree {
    /// The underlying C++ handle (reference semantics: copies share the complex).
    var cxx: gudhi_swift.SimplexTree

    public init() { cxx = gudhi_swift.SimplexTree() }
    init(_ c: gudhi_swift.SimplexTree) { cxx = c }

    // ── construction / mutation ─────────────────────────────────────────────
    @discardableResult
    public func insert(_ simplex: [Int], filtration: Double = 0) -> Bool {
        cxx.insert(cxxIntVector(simplex), filtration)
    }

    public func assignFiltration(_ simplex: [Int], _ filtration: Double) {
        cxx.assignFiltration(cxxIntVector(simplex), filtration)
    }

    @discardableResult
    public func makeFiltrationNonDecreasing() -> Bool { cxx.makeFiltrationNonDecreasing() }
    @discardableResult
    public func pruneAboveFiltration(_ filtration: Double) -> Bool { cxx.pruneAboveFiltration(filtration) }
    @discardableResult
    public func pruneAboveDimension(_ dimension: Int) -> Bool { cxx.pruneAboveDimension(Int32(dimension)) }
    public func expansion(maxDimension: Int) { cxx.expansion(Int32(maxDimension)) }
    /// Collapse flag-complex edges `iterations` times (preserves persistence).
    public func collapseEdges(iterations: Int = 1) { cxx.collapseEdges(Int32(iterations)) }
    public func resetFiltration(_ filtration: Double, minDimension: Int = 0) {
        cxx.resetFiltration(filtration, Int32(minDimension))
    }
    public func clear() { cxx.clear() }

    // ── queries ─────────────────────────────────────────────────────────────
    public var numVertices: Int { Int(cxx.numVertices()) }
    public var numSimplices: Int { Int(cxx.numSimplices()) }
    public var dimension: Int { Int(cxx.dimension()) }

    public func contains(_ simplex: [Int]) -> Bool { cxx.find(cxxIntVector(simplex)) }
    public func filtration(of simplex: [Int]) -> Double { cxx.filtration(cxxIntVector(simplex)) }

    public var simplices: [FilteredSimplex] { cxx.getSimplices().map(FilteredSimplex.init) }
    public func skeleton(dimension: Int) -> [FilteredSimplex] {
        cxx.getSkeleton(Int32(dimension)).map(FilteredSimplex.init)
    }
    public func star(of simplex: [Int]) -> [FilteredSimplex] {
        cxx.getStar(cxxIntVector(simplex)).map(FilteredSimplex.init)
    }
    public func cofaces(of simplex: [Int], codimension: Int) -> [FilteredSimplex] {
        cxx.getCofaces(cxxIntVector(simplex), Int32(codimension)).map(FilteredSimplex.init)
    }
    public func boundaries(of simplex: [Int]) -> [FilteredSimplex] {
        cxx.getBoundaries(cxxIntVector(simplex)).map(FilteredSimplex.init)
    }

    // ── persistence ─────────────────────────────────────────────────────────
    /// Compute and return the full persistence diagram in one call.
    @discardableResult
    public func persistence(coeffField: Int = 11,
                            minPersistence: Double = 0,
                            persistenceDimMax: Bool = false) -> [PersistenceInterval] {
        cxx.persistence(Int32(coeffField), minPersistence, persistenceDimMax)
            .map(PersistenceInterval.init)
    }

    /// Compute persistence without materializing the diagram (use the accessors below).
    public func computePersistence(coeffField: Int = 11,
                                   minPersistence: Double = 0,
                                   persistenceDimMax: Bool = false) {
        cxx.computePersistence(Int32(coeffField), minPersistence, persistenceDimMax)
    }

    public var diagram: [PersistenceInterval] {
        cxx.persistenceDiagram().map(PersistenceInterval.init)
    }
    public var bettiNumbers: [Int] { swiftInts(cxx.bettiNumbers()) }
    public func persistentBettiNumbers(from: Double, to: Double) -> [Int] {
        swiftInts(cxx.persistentBettiNumbers(from, to))
    }
    public func intervals(inDimension dimension: Int) -> [(birth: Double, death: Double)] {
        cxx.persistenceIntervalsInDimension(Int32(dimension)).map { ($0.birth, $0.death) }
    }
    public func persistencePairs() -> [(birth: [Int], death: [Int])] {
        cxx.persistencePairs().map { (swiftInts($0.birth), swiftInts($0.death)) }
    }
}
