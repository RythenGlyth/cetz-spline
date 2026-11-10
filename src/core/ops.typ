// cetz-spline: ops.typ
// Advanced geometric spline operations: resampling, homotopies, and parallel offset curves.

#import "@preview/cetz:0.5.3": vector
#import "types.typ": assert-spline, make-spline
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
  let n = calc.max(2, int(count))
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
/// -> intermediate spline object
#let homotopy(spline-a, spline-b, t) = {
  assert-spline(spline-a, name: "spline-a")
  assert-spline(spline-b, name: "spline-b")
  let t-val = calc.max(0.0, calc.min(1.0, float(t)))

  if t-val == 0.0 {
    return spline-a
  }
  if t-val == 1.0 {
    return spline-b
  }

  let segs-a = spline-a.segments
  let segs-b = spline-b.segments

  // Fast path: identical segment count and topological closure
  if segs-a.len() == segs-b.len() and spline-a.closed == spline-b.closed {
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
      meta: (t: t-val),
      segments: morphed-segs,
    )
  }

  // General path: resample both curves uniformly by arc length
  let m = calc.max(segs-a.len() * 4, segs-b.len() * 4, 32)
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
