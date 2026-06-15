// Support.swift — shared bridging helpers between Swift and the C++ facade.

import CxxStdlib
import GudhiCoreFull

/// Build a C++ `std::vector<int>` from a Swift `[Int]`.
@inlinable
func cxxIntVector(_ values: [Int]) -> gudhi_swift.IntVector {
    var v = gudhi_swift.IntVector()
    v.reserve(values.count)
    for x in values { v.push_back(Int32(x)) }
    return v
}

/// Convert a C++ `std::vector<int>` to a Swift `[Int]`.
@inlinable
func swiftInts<V: Collection>(_ vec: V) -> [Int] where V.Element == Int32 {
    vec.map { Int($0) }
}

/// A persistence-diagram point. `death` is `.infinity` for essential features.
public struct PersistenceInterval: Sendable, Hashable {
    public let dimension: Int
    public let birth: Double
    public let death: Double
    public var persistence: Double { death - birth }
    public var isEssential: Bool { death == .infinity }
}

/// A simplex together with its filtration value.
public struct FilteredSimplex: Sendable, Hashable {
    public let vertices: [Int]
    public let filtration: Double
}

extension PersistenceInterval {
    init(_ c: gudhi_swift.PersistenceInterval) {
        self.init(dimension: Int(c.dimension), birth: c.birth, death: c.death)
    }
}

extension FilteredSimplex {
    init(_ c: gudhi_swift.FilteredSimplex) {
        self.init(vertices: swiftInts(c.vertices), filtration: c.filtration)
    }
}
