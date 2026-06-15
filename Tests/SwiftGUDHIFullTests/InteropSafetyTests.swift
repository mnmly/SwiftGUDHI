import Testing
import Foundation
@testable import SwiftGUDHIFull

// These exercise the C++ facade's exception barrier. Swift cannot catch C++
// exceptions — without the barrier, a throw from GUDHI/CGAL/Hera would terminate
// the whole test process. So these tests *passing at all* is the proof: each
// feeds an input that makes the underlying library throw, and expects a safe
// empty/NaN result rather than a crash.

@Test func cubicalSizeMismatchIsSafe() {
    // A 3x3 grid needs 9 top cells; supplying 5 makes GUDHI's Bitmap
    // constructor throw std::invalid_argument.
    let cx = CubicalComplex(dimensions: [3, 3], topCells: [0, 1, 2, 3, 4])
    #expect(cx.numSimplices == 0)
    #expect(cx.persistence().isEmpty)
}

// NOTE: the barrier catches C++ *exceptions*, not undefined behavior. Feeding
// NaN/Inf into Hera or degenerate geometry into CGAL can be UB (a segfault),
// which no try/catch can intercept — validate inputs before calling, as you
// would any numeric library.

@Test func emptyAndDegenerateInputsAreSafe() {
    // Empty inputs flow through the guards to empty results.
    #expect(Rips.complex(pointCloud: [], maxEdgeLength: 1, maxDimension: 2).numVertices == 0)
    #expect(Alpha.complex(pointCloud: []).numVertices == 0)
    #expect(Subsampling.farthestPoints([], count: 3).isEmpty)
}
