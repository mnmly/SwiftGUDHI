// Tangential.swift — Tangential complex (manifold reconstruction).

import GudhiCoreFull

public enum Tangential {
    /// Build a Tangential complex from points sampled on a manifold of the given
    /// intrinsic dimension, exported as a SimplexTree.
    public static func complex(pointCloud: [[Double]],
                               intrinsicDimension: Int) -> SimplexTree {
        let cols = pointCloud.first?.count ?? 0
        return flatten(pointCloud).withUnsafeBufferPointer { p in
            SimplexTree(gudhi_swift.tangentialComplex(
                p.baseAddress, Int32(pointCloud.count), Int32(cols), Int32(intrinsicDimension)))
        }
    }
}
