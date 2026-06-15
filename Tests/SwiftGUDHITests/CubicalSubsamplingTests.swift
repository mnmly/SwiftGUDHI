import Testing
import Foundation
@testable import SwiftGUDHI

@Test func cubicalMonotoneImageOneComponent() {
    // A 3x3 grid of strictly increasing values has a single sublevel component
    // and no holes: exactly one essential H0, no H1.
    let cells = (0..<9).map { Double($0) }
    let cx = CubicalComplex(dimensions: [3, 3], topCells: cells)
    #expect(cx.dimension == 2)
    #expect(cx.numSimplices > 0)

    let diagram = cx.persistence()
    let essentialH0 = diagram.filter { $0.dimension == 0 && $0.isEssential }
    #expect(essentialH0.count == 1, "monotone image => 1 component; got \(essentialH0.count)")
    #expect(cx.intervals(inDimension: 1).isEmpty, "monotone image has no holes")
}

@Test func cubicalRingHasHole() {
    // A 5x5 image with a low-valued ring around a high center forms a loop in
    // the sublevel filtration: one H1 feature.
    let hi = 10.0, lo = 0.0
    let image: [[Double]] = [
        [hi, hi, hi, hi, hi],
        [hi, lo, lo, lo, hi],
        [hi, lo, hi, lo, hi],
        [hi, lo, lo, lo, hi],
        [hi, hi, hi, hi, hi],
    ]
    let cx = CubicalComplex(dimensions: [5, 5], topCells: image.flatMap { $0 })
    let h1 = cx.persistence().filter { $0.dimension == 1 }
    #expect(h1.count >= 1, "ring image should have an H1 hole; got \(h1.count)")
}

@Test func subsamplingFarthestAndRandom() {
    // A 10x10 grid of 100 points.
    var grid: [[Double]] = []
    for x in 0..<10 { for y in 0..<10 { grid.append([Double(x), Double(y)]) } }

    let far = Subsampling.farthestPoints(grid, count: 12, startingPoint: 0)
    #expect(far.count == 12)
    // Farthest-point sampling starting at (0,0) should include a far corner.
    #expect(far.contains { $0 == [9, 9] || $0 == [9, 0] || $0 == [0, 9] })

    let rnd = Subsampling.randomPoints(grid, count: 7)
    #expect(rnd.count == 7)
}
