// cetz-spline: types.typ
// Spline data structures, validation, and constructors.

/// Construct a standard 2D vector `(x, y)` from a 2D or 3D coordinate array.
#let clean-point(pt) = {
  assert(type(pt) == array and pt.len() >= 2, message: "Point must be an array of at least 2 numbers, got " + repr(pt))
  (float(pt.at(0)), float(pt.at(1)))
}

/// Normalize an array of points.
#let clean-points(pts) = {
  assert(type(pts) == array, message: "Points must be an array, got " + repr(pts))
  pts.map(clean-point)
}

/// Create a new spline dictionary representation.
///
/// - type (str): "catmull-rom" | "bezier" | "bspline"
/// - pts (array): Original control points
/// - closed (bool): Whether curve is closed
/// - meta (dictionary): Additional metadata (e.g. alpha, degree, knots)
/// - segments (array): Array of cubic Bézier segments `((s, e, c1, c2), ...)`
/// - lut (dictionary, none): Arc-length lookup table (optional or lazy)
/// -> dictionary
#let make-spline(
  type: "catmull-rom",
  pts: (),
  closed: false,
  meta: (:),
  segments: (),
  lut: none,
) = (
  __is_spline: true,
  type: type,
  pts: pts,
  closed: closed,
  meta: meta,
  segments: segments,
  lut: lut,
)

/// Test whether a value is a valid cetz-spline object.
#let is-spline(obj) = {
  type(obj) == dictionary and obj.at("__is_spline", default: false) == true
}

/// Assert that a value is a valid cetz-spline object.
#let assert-spline(obj, name: "spline") = {
  assert(is-spline(obj), message: "Expected valid cetz-spline dictionary for " + name + ", got: " + repr(obj))
}

/// Get the number of Bézier segments in a spline.
#let segment-count(spline) = {
  assert-spline(spline)
  spline.segments.len()
}

/// Retrieve a specific Bézier segment `(s, e, c1, c2)` from a spline.
#let get-segment(spline, idx) = {
  assert-spline(spline)
  assert(idx >= 0 and idx < spline.segments.len(), message: "Segment index out of bounds: " + str(idx))
  spline.segments.at(idx)
}
