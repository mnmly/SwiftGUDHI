// SwiftGUDHI — a Swift-idiomatic wrapper over GUDHI's Nerve / Graph-Induced
// Complex (Mapper), bridged through the `gudhi_swift` C++ facade.
//
// Mapper turns a high-dimensional embedding cloud into a small graph: nodes are
// clusters of similar points, edges connect clusters that share points. It is a
// compact, renderable "shape" of the data — branches, loops, and isolated
// islands become visible.

import CxxStdlib
import GudhiCore

/// A cluster of input points produced by Mapper.
public struct MapperNode: Sendable, Hashable {
    /// GUDHI cover-element id. Stable for a given run but may be sparse.
    public let id: Int
    /// Number of points in this node.
    public let size: Int
    /// Mean color value over the node's points (drives node tinting).
    public let color: Double
    /// Indices (into the original input) of the points in this node.
    public let pointIndices: [Int]
}

/// An undirected edge: the two endpoint nodes share at least one input point.
public struct MapperEdge: Sendable, Hashable {
    public let source: Int
    public let target: Int
}

/// The computed Mapper graph (1-skeleton).
public struct MapperGraph: Sendable {
    public let nodes: [MapperNode]
    public let edges: [MapperEdge]

    public var isEmpty: Bool { nodes.isEmpty }
}

/// Entry point for building Mapper graphs.
public enum Mapper {

    /// Tuning options. Defaults give a usable Mapper out of the box.
    public struct Options: Sendable {
        /// Number of overlapping lens intervals.
        public var resolution: Int = 10
        /// Interval overlap fraction, in `[0, 0.5)`.
        public var gain: Double = 0.3
        /// Coordinate used as the lens when no explicit `lens` is supplied.
        public var lensCoordinate: Int = 0
        /// Neighbourhood-graph radius. Negative => auto-tuned via subsampling.
        public var ripsThreshold: Double = -1.0
        /// Subsampling iterations for the automatic threshold.
        public var automaticRipsN: Int = 100
        /// Coordinate used for node color when no explicit `color` is supplied.
        public var colorCoordinate: Int = 0
        /// Drop nodes with `<= mask` points (`0` keeps all).
        public var mask: Int = 0
        /// Log progress to stderr.
        public var verbose: Bool = false

        public init() {}
    }

    /// Build a Mapper graph from a point cloud / embedding matrix.
    ///
    /// - Parameters:
    ///   - pointCloud: rows of equal-length coordinate vectors (the embeddings).
    ///   - lens: optional 1-D lens, one value per point. When `nil`, the
    ///     `options.lensCoordinate`-th coordinate is used.
    ///   - color: optional color value per point. When `nil`, the
    ///     `options.colorCoordinate`-th coordinate is used.
    ///   - options: tuning parameters.
    public static func build(pointCloud: [[Double]],
                             lens: [Double]? = nil,
                             color: [Double]? = nil,
                             options: Options = Options()) -> MapperGraph {
        let rows = pointCloud.count
        guard rows > 0 else { return MapperGraph(nodes: [], edges: []) }
        let cols = pointCloud[0].count
        guard cols > 0 else { return MapperGraph(nodes: [], edges: []) }

        var flat = [Double]()
        flat.reserveCapacity(rows * cols)
        for row in pointCloud {
            precondition(row.count == cols, "SwiftGUDHI: ragged pointCloud (rows must share a dimension)")
            flat.append(contentsOf: row)
        }

        let opt = options.cxx
        return flat.withUnsafeBufferPointer { pts in
            withOptional(lens) { lensPtr in
                withOptional(color) { colorPtr in
                    let g = gudhi_swift.computeMapper(pts.baseAddress, Int32(rows), Int32(cols),
                                                      lensPtr, colorPtr, opt)
                    return convert(g)
                }
            }
        }
    }

    /// Build a Mapper graph from a precomputed pairwise distance matrix
    /// (e.g. cosine distances between embeddings).
    ///
    /// - Parameters:
    ///   - distanceMatrix: an `n x n` symmetric distance matrix.
    ///   - lens: REQUIRED 1-D lens, one value per point (no coordinates exist to
    ///     derive one from).
    ///   - color: optional color per point; when `nil`, the lens values are reused.
    ///   - options: tuning parameters. `ripsThreshold` MUST be `>= 0` (auto-tuning
    ///     needs coordinates). Returns an empty graph if preconditions are unmet.
    public static func build(distanceMatrix: [[Double]],
                             lens: [Double],
                             color: [Double]? = nil,
                             options: Options) -> MapperGraph {
        let n = distanceMatrix.count
        guard n > 0, lens.count == n, options.ripsThreshold >= 0 else {
            return MapperGraph(nodes: [], edges: [])
        }

        var flat = [Double]()
        flat.reserveCapacity(n * n)
        for row in distanceMatrix {
            precondition(row.count == n, "SwiftGUDHI: distanceMatrix must be square")
            flat.append(contentsOf: row)
        }

        let opt = options.cxx
        return flat.withUnsafeBufferPointer { dist in
            lens.withUnsafeBufferPointer { lensPtr in
                withOptional(color) { colorPtr in
                    let g = gudhi_swift.computeMapperFromDistanceMatrix(dist.baseAddress, Int32(n),
                                                                        lensPtr.baseAddress, colorPtr, opt)
                    return convert(g)
                }
            }
        }
    }

    /// Build a Mapper graph from a point cloud using an **N-dimensional lens**.
    ///
    /// GUDHI's functional cover is 1-D; this builds the N-D hypercube cover and
    /// refines each cell into connected components, so with `lensDim` 2/3/4 the
    /// graph can branch/loop (a grid atlas) rather than collapse to a chain.
    ///
    /// - Parameters:
    ///   - pointCloud: rows of equal-length coordinate vectors.
    ///   - lensND: row-major `rows * lensDim` lens (point i = `lensND[i*lensDim ..< (i+1)*lensDim]`).
    ///   - lensDim: number of lens dimensions (>= 1).
    ///   - color: optional color per point; `nil` => `options.colorCoordinate`.
    ///   - options: tuning parameters (`resolution`/`gain` apply per lens axis).
    public static func build(pointCloud: [[Double]],
                             lensND: [Double],
                             lensDim: Int,
                             color: [Double]? = nil,
                             options: Options = Options()) -> MapperGraph {
        let rows = pointCloud.count
        guard rows > 0, lensDim > 0, lensND.count == rows * lensDim else {
            return MapperGraph(nodes: [], edges: [])
        }
        let cols = pointCloud[0].count
        guard cols > 0 else { return MapperGraph(nodes: [], edges: []) }

        var flat = [Double]()
        flat.reserveCapacity(rows * cols)
        for row in pointCloud {
            precondition(row.count == cols, "SwiftGUDHI: ragged pointCloud (rows must share a dimension)")
            flat.append(contentsOf: row)
        }

        let opt = options.cxx
        return flat.withUnsafeBufferPointer { pts in
            lensND.withUnsafeBufferPointer { lensPtr in
                withOptional(color) { colorPtr in
                    let g = gudhi_swift.computeMapperND(pts.baseAddress, Int32(rows), Int32(cols),
                                                        lensPtr.baseAddress, Int32(lensDim), colorPtr, opt)
                    return convert(g)
                }
            }
        }
    }

    /// Version string reported by the underlying C++ facade.
    public static var version: String { String(gudhi_swift.version()) }
}

// MARK: - Bridging helpers

private extension Mapper.Options {
    var cxx: gudhi_swift.MapperOptions {
        var o = gudhi_swift.MapperOptions()
        o.resolution = Int32(resolution)
        o.gain = gain
        o.lensCoordinate = Int32(lensCoordinate)
        o.ripsThreshold = ripsThreshold
        o.automaticRipsN = Int32(automaticRipsN)
        o.colorCoordinate = Int32(colorCoordinate)
        o.mask = Int32(mask)
        o.verbose = verbose
        return o
    }
}

/// Call `body` with a pointer to `array`'s storage, or `nil` when `array` is nil.
private func withOptional<R>(_ array: [Double]?,
                             _ body: (UnsafePointer<Double>?) -> R) -> R {
    if let array {
        return array.withUnsafeBufferPointer { body($0.baseAddress) }
    }
    return body(nil)
}

private func convert(_ g: gudhi_swift.MapperGraph) -> MapperGraph {
    var nodes: [MapperNode] = []
    nodes.reserveCapacity(g.nodes.size())
    for cxxNode in g.nodes {
        var indices: [Int] = []
        indices.reserveCapacity(cxxNode.point_indices.size())
        for v in cxxNode.point_indices { indices.append(Int(v)) }
        nodes.append(MapperNode(id: Int(cxxNode.id),
                                size: Int(cxxNode.size),
                                color: cxxNode.color,
                                pointIndices: indices))
    }

    var edges: [MapperEdge] = []
    edges.reserveCapacity(g.edges.size())
    for cxxEdge in g.edges {
        edges.append(MapperEdge(source: Int(cxxEdge.source), target: Int(cxxEdge.target)))
    }

    return MapperGraph(nodes: nodes, edges: edges)
}
