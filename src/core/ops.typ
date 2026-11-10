// cetz-spline: ops.typ
// Advanced geometric spline operations: resampling, homotopies, and parallel offset curves.

#import "@preview/cetz:0.5.3": vector
#import "types.typ": assert-spline, make-spline, clean-point
#import "bezier.typ": (
  cubic-point,
  cubic-derivative,
  cubic-normal,
  cubic-curvature,
  cubic-split,
  spline-eval,
)
#import "arc_length.typ": spline-arc-length, spline-point-at-distance, spline-t-for-distance
#import "catmull_rom.typ": spline-catmull

/// Resample a spline into `count` points spaced uniformly by arc length.
///
/// - spline (spline): Spline dictionary
/// - count (int): Number of sample points (>= 2)
/// -> array of 2D points `((x0, y0), (x1, y1), ...)`
#let resample(spline, count) = {
  assert-spline(spline)
  assert(type(count) == int and count >= 2, message: "count must be an integer >= 2")
  let n = count
  let total-l = spline-arc-length(spline)
  let pts = ()

  if spline.closed {
    let ds = total-l / float(n)
    for i in range(0, n) {
      pts.push(spline-point-at-distance(spline, float(i) * ds))
    }
  } else {
    let ds = total-l / float(n - 1)
    for i in range(0, n) {
      let s = if i == n - 1 { total-l } else { float(i) * ds }
      pts.push(spline-point-at-distance(spline, s))
    }
  }

  pts
}

/// Compute intermediate morphed curve under linear homotopy (1 - t) A + t B.
///
/// - spline-a (spline): Base curve (t = 0)
/// - spline-b (spline): Target curve (t = 1)
/// - t (float): Homotopy parameter in [0, 1]
/// - mode (str): Morphing interpolation strategy:
///   - `"auto"` (default): uses `"segment"` if segment counts and closedness match;
///     otherwise falls back to `"arc-length"`.
///   - `"segment"`: forces direct segment-by-segment Bézier control point interpolation.
///     Both curves must have the same number of segments.
///   - `"arc-length"` (or `"length"`): forces uniform physical arc-length resampling
///     before morphing. Points at distance fraction $s$ morph directly to distance
///     fraction $s$ on the target curve, preventing non-uniform stretching even
///     when segment sizes differ.
/// - samples (int, auto): Number of sample points when using arc-length resampling
///   (defaults to `auto`, picking `max(segs_a * 4, segs_b * 4, 32)`).
/// -> intermediate spline object
#let homotopy(spline-a, spline-b, t, mode: "auto", samples: auto) = {
  assert-spline(spline-a, name: "spline-a")
  assert-spline(spline-b, name: "spline-b")
  assert(mode in ("auto", "segment", "arc-length", "length"), message: "Unknown homotopy mode")
  assert(samples == auto or (type(samples) == int and samples >= 4), message: "samples must be auto or an integer >= 4")
  assert(spline-a.closed == spline-b.closed, message: "Homotopy requires matching open/closed topology")
  if mode == "segment" {
    assert(spline-a.segments.len() == spline-b.segments.len(), message: "Segment homotopy requires identical segment counts")
  }
  let t-val = calc.max(0.0, calc.min(1.0, float(t)))

  if t-val == 0.0 {
    return spline-a
  }
  if t-val == 1.0 {
    return spline-b
  }

  let segs-a = spline-a.segments
  let segs-b = spline-b.segments

  let use-segment-mode = if mode == "segment" {
    assert(
      segs-a.len() == segs-b.len(),
      message: "Segment homotopy requires identical segment counts: spline-a has " + str(segs-a.len()) + ", spline-b has " + str(segs-b.len()),
    )
    true
  } else if mode == "arc-length" or mode == "length" {
    false
  } else if mode == "auto" {
    segs-a.len() == segs-b.len() and spline-a.closed == spline-b.closed
  } else {
    panic("Unknown homotopy mode: " + repr(mode) + ". Supported: 'auto', 'segment', 'arc-length'.")
  }

  // 1. Segment-by-segment control point interpolation
  if use-segment-mode {
    let morphed-segs = ()
    let one-minus-t = 1.0 - t-val

    for i in range(0, segs-a.len()) {
      let (sa, ea, c1a, c2a) = segs-a.at(i)
      let (sb, eb, c1b, c2b) = segs-b.at(i)

      let s = vector.add(vector.scale(sa, one-minus-t), vector.scale(sb, t-val))
      let e = vector.add(vector.scale(ea, one-minus-t), vector.scale(eb, t-val))
      let c1 = vector.add(vector.scale(c1a, one-minus-t), vector.scale(c1b, t-val))
      let c2 = vector.add(vector.scale(c2a, one-minus-t), vector.scale(c2b, t-val))

      morphed-segs.push((s, e, c1, c2))
    }

    let morphed-pts = ()
    if spline-a.pts.len() == spline-b.pts.len() {
      for i in range(0, spline-a.pts.len()) {
        morphed-pts.push(
          vector.add(
            vector.scale(spline-a.pts.at(i), one-minus-t),
            vector.scale(spline-b.pts.at(i), t-val)
          )
        )
      }
    }

    return make-spline(
      type: "homotopy",
      pts: morphed-pts,
      closed: spline-a.closed,
      meta: (t: t-val, mode: "segment"),
      segments: morphed-segs,
    )
  }

  // 2. Arc-length resampling path: resample both curves uniformly by physical arc length
  let m = if samples == auto {
    calc.max(segs-a.len() * 4, segs-b.len() * 4, 32)
  } else {
    calc.max(4, int(samples))
  }

  let pts-a = resample(spline-a, m)
  let pts-b = resample(spline-b, m)
  let lerped-pts = ()
  let one-minus-t = 1.0 - t-val

  for i in range(0, m) {
    lerped-pts.push(
      vector.add(
        vector.scale(pts-a.at(i), one-minus-t),
        vector.scale(pts-b.at(i), t-val)
      )
    )
  }

  spline-catmull(
    lerped-pts,
    alpha: 0.5,
    closed: spline-a.closed and spline-b.closed,
  )
}

/// Helper: offset a single cubic Bézier segment along its normal field.
#let _offset-segment(s, e, c1, c2, distance) = {
  let n0 = cubic-normal(s, e, c1, c2, 0.0)
  let n1 = cubic-normal(s, e, c1, c2, 1.0)
  let k0 = cubic-curvature(s, e, c1, c2, 0.0)
  let k1 = cubic-curvature(s, e, c1, c2, 1.0)

  let s-off = vector.add(s, vector.scale(n0, distance))
  let e-off = vector.add(e, vector.scale(n1, distance))

  // Speed scaling factor: (1 - d * kappa)
  let w0 = calc.max(0.05, 1.0 - distance * k0)
  let w1 = calc.max(0.05, 1.0 - distance * k1)

  let c1-off = vector.add(s-off, vector.scale(vector.sub(c1, s), w0))
  let c2-off = vector.sub(e-off, vector.scale(vector.sub(e, c2), w1))

  (s-off, e-off, c1-off, c2-off)
}

/// Compute parallel offset curve at normal distance `distance`.
/// Positive distance offsets to the left of the curve tangent; negative offsets to the right.
///
/// - spline (spline): Spline dictionary
/// - distance (float): Perpendicular offset distance
/// - subdivide (bool): Whether to subdivide segments with high curvature variation for fidelity
/// -> offset spline object
#let offset(spline, distance, subdivide: true) = {
  assert-spline(spline)
  let d = float(distance)
  if calc.abs(d) < 1e-12 {
    return spline
  }

  let offset-segments = ()
  for seg in spline.segments {
    let (s, e, c1, c2) = seg
    let k0 = cubic-curvature(s, e, c1, c2, 0.0)
    let k1 = cubic-curvature(s, e, c1, c2, 1.0)

    if subdivide and calc.abs(k1 - k0) > 0.8 {
      // Split into 2 halves for high precision
      let (left, right) = cubic-split(s, e, c1, c2, 0.5)
      offset-segments.push(_offset-segment(left.at(0), left.at(1), left.at(2), left.at(3), d))
      offset-segments.push(_offset-segment(right.at(0), right.at(1), right.at(2), right.at(3), d))
    } else {
      offset-segments.push(_offset-segment(s, e, c1, c2, d))
    }
  }

  make-spline(
    type: "offset",
    pts: (),
    closed: spline.closed,
    meta: (distance: d, base-type: spline.type),
    segments: offset-segments,
  )
}

/// Helper: rotate a 2D point around an origin by an angle.
#let _rotate-pt(pt, angle, origin: (0.0, 0.0)) = {
  let rad = if type(angle) == std.angle { angle.rad() } else { float(angle) }
  let cos-a = calc.cos(rad)
  let sin-a = calc.sin(rad)
  let (ox, oy) = clean-point(origin)
  let dx = float(pt.at(0)) - ox
  let dy = float(pt.at(1)) - oy
  (
    ox + dx * cos-a - dy * sin-a,
    oy + dx * sin-a + dy * cos-a,
  )
}

/// Rotate a spline around an origin point by a given angle.
///
/// Bézier curves are affine-invariant, so rotating all segment endpoints and
/// control handles transforms the curve geometry exactly without approximation.
/// Arc-length is preserved under rigid rotation.
///
/// - spline (spline): Target spline dictionary
/// - angle (angle, float): Rotation angle (e.g. `90deg`, `-45deg`, or radians as float)
/// - origin (point): Pivot point of rotation (default: `(0, 0)`)
/// -> rotated spline object
#let rotate-spline(spline, angle, origin: (0.0, 0.0)) = {
  assert-spline(spline)
  let orig = clean-point(origin)
  let rot(p) = _rotate-pt(p, angle, origin: orig)

  let rotated-segs = spline.segments.map(seg => {
    let (s, e, c1, c2) = seg
    (rot(s), rot(e), rot(c1), rot(c2))
  })

  let rotated-pts = spline.pts.map(rot)

  make-spline(
    type: spline.type,
    pts: rotated-pts,
    closed: spline.closed,
    meta: spline.meta,
    segments: rotated-segs,
    lut: spline.lut,
  )
}
#let rotate = rotate-spline

/// Translate a spline by a 2D delta offset `(dx, dy)`.
///
/// - spline (spline): Target spline dictionary
/// - offset (point): Translation offset `(dx, dy)`
/// -> translated spline object
#let translate-spline(spline, offset) = {
  assert-spline(spline)
  let (dx, dy) = clean-point(offset)
  let shift(p) = (float(p.at(0)) + dx, float(p.at(1)) + dy)

  let translated-segs = spline.segments.map(seg => {
    let (s, e, c1, c2) = seg
    (shift(s), shift(e), shift(c1), shift(c2))
  })

  let translated-pts = spline.pts.map(shift)

  make-spline(
    type: spline.type,
    pts: translated-pts,
    closed: spline.closed,
    meta: spline.meta,
    segments: translated-segs,
    lut: spline.lut,
  )
}
#let translate = translate-spline

/// Helper: parse an angle, array, or string into a normalized 2D direction unit vector.
#let _parse-dir(d) = {
  if d == none {
    return none
  }
  if type(d) == std.angle {
    let rad = d.rad()
    return (calc.cos(rad), calc.sin(rad))
  }
  if type(d) == str {
    if d == "x" or d == "horizontal" {
      return (1.0, 0.0)
    } else if d == "y" or d == "vertical" {
      return (0.0, 1.0)
    } else {
      assert(false, message: "Invalid direction string: expected 'x', 'y', 'horizontal', or 'vertical', got " + repr(d))
    }
  }
  if type(d) == array and d.len() >= 2 {
    let vx = float(d.at(0))
    let vy = float(d.at(1))
    let len = calc.sqrt(vx * vx + vy * vy)
    assert(len > 1e-12, message: "Direction vector cannot have zero length")
    return (vx / len, vy / len)
  }
  assert(false, message: "Invalid direction: expected array (dx, dy), angle, or str ('x', 'y'), got " + repr(d))
}

/// Scale a spline relative to a center point, optionally along an arbitrary direction.
///
/// Supports negative factors for reflections, as well as directional scaling along
/// an arbitrary vector or angle.
///
/// - spline (spline): Target spline dictionary
/// - factor (float, array): Scale factor.
///   - If `dir` is none: a single float scales uniformly; an array `(sx, sy)` scales along Cartesian axes.
///   - If `dir` is specified: a single float scales along `dir` (leaving the perpendicular unchanged); an array `(su, sv)` scales along `dir` and its normal.
/// - origin (point): Scaling origin pivot point (default: `(0, 0)`)
/// - dir (str, array, angle, none): Optional direction vector `(dx, dy)`, angle (e.g. `45deg`), or `"x"` / `"y"`.
/// -> scaled spline object
#let scale-spline(spline, factor, origin: (0.0, 0.0), dir: none) = {
  assert-spline(spline)
  let (ox, oy) = clean-point(origin)
  let dir-vec = _parse-dir(dir)

  let sc = if dir-vec == none {
    let (sx, sy) = if type(factor) == array {
      (float(factor.at(0)), float(factor.at(1)))
    } else {
      (float(factor), float(factor))
    }
    (p) => (
      ox + (float(p.at(0)) - ox) * sx,
      oy + (float(p.at(1)) - oy) * sy,
    )
  } else {
    let (ux, uy) = dir-vec
    let (vx, vy) = (-uy, ux)
    let (su, sv) = if type(factor) == array {
      (float(factor.at(0)), float(factor.at(1)))
    } else {
      (float(factor), 1.0)
    }
    (p) => {
      let dx = float(p.at(0)) - ox
      let dy = float(p.at(1)) - oy
      let du = dx * ux + dy * uy
      let dv = dx * vx + dy * vy
      (
        ox + su * du * ux + sv * dv * vx,
        oy + su * du * uy + sv * dv * vy,
      )
    }
  }

  let scaled-segs = spline.segments.map(seg => {
    let (s, e, c1, c2) = seg
    (sc(s), sc(e), sc(c1), sc(c2))
  })

  let scaled-pts = spline.pts.map(sc)

  make-spline(
    type: spline.type,
    pts: scaled-pts,
    closed: spline.closed,
    meta: spline.meta,
    segments: scaled-segs,
    lut: none,
  )
}
#let scale = scale-spline

/// Mirror (reflect) a spline across a line or through a point.
///
/// - spline (spline): Target spline dictionary
/// - origin (point): Point that the reflection axis/center passes through (default: `(0, 0)`)
/// - axis (str, array, angle, none): Reflection axis:
///   - `"x"`: horizontal line through `origin` (flips y-coordinates)
///   - `"y"`: vertical line through `origin` (flips x-coordinates)
///   - direction vector `(dx, dy)` or `angle`: reflection across line along this direction
///   - `none`: point reflection through `origin` (inverts both coordinates)
/// -> mirrored spline object
#let mirror-spline(spline, origin: (0.0, 0.0), axis: "x") = {
  assert-spline(spline)
  if axis == none {
    // Point reflection through origin: scale by -1
    return scale-spline(spline, -1.0, origin: origin)
  }
  let dir-vec = _parse-dir(axis)
  // Reflection across a line with direction u preserves u and inverts normal v:
  scale-spline(spline, (1.0, -1.0), origin: origin, dir: dir-vec)
}
#let mirror = mirror-spline
