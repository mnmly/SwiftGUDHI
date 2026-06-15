// CubicalComplex.swift — persistence of images / regular grids.

import CxxStdlib
import GudhiCoreFull

public struct CubicalComplex {
    var cxx: gudhi_swift.CubicalComplex

    /// Build from top-dimensional cell values (e.g. pixel/voxel intensities).
    /// `dimensions` is the grid shape; `topCells` are its values (row-major).
    public init(dimensions: [Int], topCells: [Double]) {
        cxx = Self.make(dimensions, topCells, inputTopCells: true)
    }

    /// Build from vertex values instead of top-cell values.
    public init(dimensions: [Int], vertexValues: [Double]) {
        cxx = Self.make(dimensions, vertexValues, inputTopCells: false)
    }

    private static func make(_ dimensions: [Int], _ cells: [Double],
                             inputTopCells: Bool) -> gudhi_swift.CubicalComplex {
        let dims = dimensions.map { Int32($0) }
        return dims.withUnsafeBufferPointer { dp in
            cells.withUnsafeBufferPointer { cp in
                gudhi_swift.cubicalComplex(dp.baseAddress, Int32(dims.count),
                                           cp.baseAddress, Int32(cells.count), inputTopCells)
            }
        }
    }

    public var numSimplices: Int { Int(cxx.numSimplices()) }
    public var dimension: Int { Int(cxx.dimension()) }

    @discardableResult
    public func persistence(coeffField: Int = 11, minPersistence: Double = 0) -> [PersistenceInterval] {
        cxx.persistence(Int32(coeffField), minPersistence).map(PersistenceInterval.init)
    }
    public var bettiNumbers: [Int] { swiftInts(cxx.bettiNumbers()) }
    public func intervals(inDimension dimension: Int) -> [(birth: Double, death: Double)] {
        cxx.persistenceIntervalsInDimension(Int32(dimension)).map { ($0.birth, $0.death) }
    }
}
