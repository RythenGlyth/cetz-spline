// cetz-spline: catmull_rom.typ
// Generalized alpha-Catmull-Rom splines (uniform, centripetal, chordal).

#import "@preview/cetz:0.5.3": vector
#import "types.typ": make-spline, clean-points

/// Convert 4 consecutive points (P0, P1, P2, P3) into cubic Bézier control points (B0, B1, B2, B3)
/// spanning from P1 to P2.
#let _catmull-segment-to-bezier(p0, p1, p2, p3, alpha: 0.5) = {
  let d0 = vector.len(vector.sub(p1, p0))
  let d1 = vector.len(vector.sub(p2, p1))
  let d2 = vector.len(vector.sub(p3, p2))

  let dt0 = if alpha == 0.0 or alpha == 0 { 1.0 } else { calc.max(1e-6, calc.pow(d0, alpha)) }
  let dt1 = if alpha == 0.0 or alpha == 0 { 1.0 } else { calc.max(1e-6, calc.pow(d1, alpha)) }
  let dt2 = if alpha == 0.0 or alpha == 0 { 1.0 } else { calc.max(1e-6, calc.pow(d2, alpha)) }

  let t0 = 0.0
  let t1 = dt0
  let t2 = t1 + dt1
  let t3 = t2 + dt2

  // Derivative at P1 (t1)
  let v01 = vector.scale(vector.sub(p1, p0), 1.0 / (t1 - t0))
  let v12 = vector.scale(vector.sub(p2, p1), 1.0 / (t2 - t1))
  let c1-prime = vector.add(
    vector.scale(v01, (t2 - t1) / (t2 - t0)),
    vector.scale(v12, (t1 - t0) / (t2 - t0))
  )
  let b1 = vector.add(p1, vector.scale(c1-prime, (t2 - t1) / 3.0))

  // Derivative at P2 (t2)
  let v23 = vector.scale(vector.sub(p3, p2), 1.0 / (t3 - t2))
  let c2-prime = vector.add(
    vector.scale(v12, (t3 - t2) / (t3 - t1)),
    vector.scale(v23, (t2 - t1) / (t3 - t1))
  )
  let b2 = vector.sub(p2, vector.scale(c2-prime, (t2 - t1) / 3.0))

  let b0 = p1
  let b3 = p2

  // CeTZ segment representation: (s, e, c1, c2)
  (b0, b3, b1, b2)
}

/// Convert a list of points into cubic Bézier segments using Catmull-Rom interpolation.
///
/// - points (array): Array of 2D coordinates `((x0, y0), (x1, y1), ...)`
/// - alpha (float): 0.0 = uniform, 0.5 = centripetal (default), 1.0 = chordal
/// - closed (bool): Whether curve is closed into a periodic loop
/// - boundary (str): "clamped" (default) or "natural"
/// -> array of segments `((s, e, c1, c2), ...)`
#let catmull-to-bezier-segments(points, alpha: 0.5, closed: false, boundary: "clamped") = {
  let pts = clean-points(points)
  let n = pts.len()
  assert(n >= 2, message: "Catmull-Rom spline requires at least 2 points, got " + str(n))

  assert(type(alpha) in (int, float) and alpha >= 0 and alpha <= 1, message: "alpha must be a number in [0, 1]")
  assert(boundary in ("clamped", "natural"), message: "boundary must be clamped or natural")

  let segments = ()

  if closed {
    for i in range(0, n) {
      let p0 = pts.at(calc.rem(i - 1 + n, n))
      let p1 = pts.at(i)
      let p2 = pts.at(calc.rem(i + 1, n))
      let p3 = pts.at(calc.rem(i + 2, n))
      segments.push(_catmull-segment-to-bezier(p0, p1, p2, p3, alpha: alpha))
    }
  } else {
    // Generate ghost boundary points
    let p-first = pts.at(0)
    let p-second = pts.at(1)
    let p-last = pts.at(n - 1)
    let p-prev = pts.at(n - 2)

    // Extrapolated ghost points preserve the endpoint chord direction.
    let p-ghost-start = vector.sub(vector.scale(p-first, 2.0), p-second)
    let p-ghost-end = vector.sub(vector.scale(p-last, 2.0), p-prev)

    let extended = (p-ghost-start, ..pts, p-ghost-end)
    for i in range(0, n - 1) {
      let p0 = extended.at(i)
      let p1 = extended.at(i + 1)
      let p2 = extended.at(i + 2)
      let p3 = extended.at(i + 3)
      segments.push(_catmull-segment-to-bezier(p0, p1, p2, p3, alpha: alpha))
    }
  }

  if not closed and boundary == "natural" {
    // C''(0) = 6(s - 2c1 + c2) and C''(1) = 6(e - 2c2 + c1).
    // Adjust only exterior handles, preserving interpolation and interior joins.
    let first = segments.first()
    first.at(2) = vector.scale(vector.add(first.at(0), first.at(3)), 0.5)
    segments.at(0) = first
    let last = segments.last()
    last.at(3) = vector.scale(vector.add(last.at(1), last.at(2)), 0.5)
    segments.at(segments.len() - 1) = last
  }
  segments
}

/// Construct a Catmull-Rom spline object.
///
/// - points (array): Interpolation points
/// - alpha (float): Knot parameterization: 0.0 (uniform), 0.5 (centripetal, default), 1.0 (chordal)
/// - closed (bool): Whether curve is a closed loop
/// - boundary (str): "clamped" (default) or "natural"
/// -> spline dictionary
#let spline-catmull(points, alpha: 0.5, closed: false, boundary: "clamped") = {
  let pts = clean-points(points)
  let segs = catmull-to-bezier-segments(pts, alpha: alpha, closed: closed, boundary: boundary)
  make-spline(
    type: "catmull-rom",
    pts: pts,
    closed: closed,
    meta: (alpha: alpha, boundary: boundary),
    segments: segs,
  )
}
