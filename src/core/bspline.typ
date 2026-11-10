// cetz-spline: bspline.typ
// Arbitrary degree B-splines via Cox-de Boor recursion and Bézier segment extraction.

#import "@preview/cetz:0.5.3": vector
#import "types.typ": make-spline, clean-points

/// Generate clamped (open-uniform) knot vector for n control points and degree p.
/// Format: p+1 zeros, uniform intermediate knots, p+1 ones.
#let generate-clamped-knots(n, p) = {
  let knots = ()
  for _ in range(0, p + 1) {
    knots.push(0.0)
  }
  let interior-count = n - p - 1
  if interior-count > 0 {
    for j in range(1, interior-count + 1) {
      knots.push(float(j) / float(n - p))
    }
  }
  for _ in range(0, p + 1) {
    knots.push(1.0)
  }
  knots
}

/// Generate periodic uniform knot vector for closed B-splines.
#let generate-periodic-knots(n, p) = {
  // Knots 0, 1, ..., n + 2p
  let knots = ()
  for i in range(0, n + 2 * p + 1) {
    knots.push(float(i))
  }
  knots
}

/// Cox-de Boor evaluation of B-spline curve at parameter `u`.
/// - u (float): Evaluation parameter
/// - p (int): Spline degree
/// - knots (array): Non-decreasing knot vector
/// - pts (array): Control points
#let cox-de-boor(u, p, knots, pts) = {
  let n = pts.len()
  let u-start = knots.at(p)
  let u-end = knots.at(n)

  // Clamp u within domain
  let u-val = calc.max(u-start, calc.min(u-end, float(u)))

  // Find knot span i such that knots[i] <= u_val < knots[i+1]
  let idx = p
  if u-val >= u-end {
    idx = n - 1
    while idx > p and knots.at(idx) == u-end {
      idx -= 1
    }
  } else {
    for i in range(p, n) {
      if knots.at(i) <= u-val and u-val < knots.at(i + 1) {
        idx = i
        break
      }
    }
  }

  // Copy local control points
  let d = ()
  for j in range(0, p + 1) {
    d.push(pts.at(idx - p + j))
  }

  // Triangular de Boor scheme
  if p > 0 {
    for r in range(1, p + 1) {
      for j in range(p, r - 1, step: -1) {
        let left-knot = knots.at(idx - p + j)
        let right-knot = knots.at(idx + 1 + j - r)
        let denom = right-knot - left-knot
        let alpha = if denom > 0 { (u-val - left-knot) / denom } else { 0.0 }
        d.at(j) = vector.add(
          vector.scale(d.at(j - 1), 1.0 - alpha),
          vector.scale(d.at(j), alpha)
        )
      }
    }
  }

  d.at(p)
}

/// Derivative C'(u) of B-spline curve via degree p-1 hodograph.
#let cox-de-boor-derivative(u, p, knots, pts) = {
  if p <= 0 {
    return (0.0, 0.0)
  }
  let n = pts.len()
  let q-pts = ()
  for j in range(0, n - 1) {
    let denom = knots.at(j + p + 1) - knots.at(j + 1)
    let scale = if denom > 0 { float(p) / denom } else { 0.0 }
    let diff = vector.sub(pts.at(j + 1), pts.at(j))
    q-pts.push(vector.scale(diff, scale))
  }
  let q-knots = knots.slice(1, knots.len() - 1)
  cox-de-boor(u, p - 1, q-knots, q-pts)
}

/// Convert B-spline into equivalent cubic Bézier segments.
///
/// - points (array): Control points
/// - degree (int): Polynomial degree (default 3)
/// - closed (bool): Whether curve is closed
/// - knots (array, none): Custom knot vector or none for standard clamped/periodic
#let bspline-to-bezier-segments(points, degree: 3, closed: false, knots: none) = {
  let pts = clean-points(points)
  let n = pts.len()
  assert(n >= 2, message: "B-spline requires at least 2 points")
  assert(type(degree) == int and degree >= 1, message: "degree must be a positive integer")
  let p = calc.min(degree, n - 1)
  if knots != none {
    let count = if closed { n + 2 * p + 1 } else { n + p + 1 }
    assert(type(knots) == array and knots.len() == count, message: "Invalid knot vector length; expected " + str(count))
    for k in knots {
      assert(type(k) in (int, float), message: "Knots must be numeric")
    }
    for i in range(1, knots.len()) {
      assert(knots.at(i) >= knots.at(i - 1), message: "Knots must be non-decreasing")
    }
    let end = if closed { n + p } else { n }
    assert(knots.at(p) < knots.at(end), message: "Knot domain must have positive length")
    for k in knots.dedup() {
      if knots.at(p) < k and k < knots.at(end) {
        assert(knots.filter(v => v == k).len() <= p, message: "Discontinuous interior knots are not supported")
      }
    }
  }

  let (eval-pts, knot-vec, spans) = if closed {
    // Extend control points periodically
    let ext-pts = pts
    for i in range(0, p) {
      ext-pts.push(pts.at(i))
    }
    let k-vec = if knots != none { knots } else { generate-periodic-knots(n, p) }
    // Knot spans between u_p and u_{n+p}
    let sp = ()
    for i in range(p, n + p) {
      if k-vec.at(i + 1) - k-vec.at(i) > 0 {
        sp.push((k-vec.at(i), k-vec.at(i + 1)))
      }
    }
    (ext-pts, k-vec, sp)
  } else {
    let k-vec = if knots != none { knots } else { generate-clamped-knots(n, p) }
    let sp = ()
    for i in range(p, n) {
      if k-vec.at(i + 1) - k-vec.at(i) > 0 {
        sp.push((k-vec.at(i), k-vec.at(i + 1)))
      }
    }
    (pts, k-vec, sp)
  }

  let segments = ()
  for span in spans {
    let (a, b) = span
    let delta = b - a

    if p <= 3 {
      // Exact representation for degree <= 3
      let s = cox-de-boor(a, p, knot-vec, eval-pts)
      let e = cox-de-boor(b, p, knot-vec, eval-pts)
      // The derivative has degree <= 2. Recover its one-sided endpoint
      // values from interior samples, avoiding epsilon perturbation at knots.
      let d1 = cox-de-boor-derivative(a + delta / 4, p, knot-vec, eval-pts)
      let d2 = cox-de-boor-derivative(a + delta / 2, p, knot-vec, eval-pts)
      let d3 = cox-de-boor-derivative(a + 3 * delta / 4, p, knot-vec, eval-pts)
      let d_a = vector.add(vector.sub(vector.scale(d1, 3), vector.scale(d2, 3)), d3)
      let d_b = vector.add(vector.sub(d1, vector.scale(d2, 3)), vector.scale(d3, 3))

      let c1 = vector.add(s, vector.scale(d_a, delta / 3.0))
      let c2 = vector.sub(e, vector.scale(d_b, delta / 3.0))

      segments.push((s, e, c1, c2))
    } else {
      // For higher degree p > 3, subdivide span into subsegments
      let sub-divisions = p - 2
      for sub in range(0, sub-divisions) {
        let t0 = a + delta * (float(sub) / float(sub-divisions))
        let t1 = a + delta * (float(sub + 1) / float(sub-divisions))
        let sub-delta = t1 - t0
        let s = cox-de-boor(t0, p, knot-vec, eval-pts)
        let e = cox-de-boor(t1, p, knot-vec, eval-pts)
        let d0 = cox-de-boor-derivative(t0 + 1e-8 * sub-delta, p, knot-vec, eval-pts)
        let d1 = cox-de-boor-derivative(t1 - 1e-8 * sub-delta, p, knot-vec, eval-pts)
        let c1 = vector.add(s, vector.scale(d0, sub-delta / 3.0))
        let c2 = vector.sub(e, vector.scale(d1, sub-delta / 3.0))
        segments.push((s, e, c1, c2))
      }
    }
  }

  segments
}

/// Construct a B-spline curve object.
///
/// - points (array): Control polygon vertices
/// - degree (int): Polynomial degree (default 3)
/// - closed (bool): Whether curve forms a closed loop
/// - knots (array, none): Explicit knot vector (or none for standard clamped/periodic)
/// -> spline dictionary
#let spline-bspline(points, degree: 3, closed: false, knots: none) = {
  let pts = clean-points(points)
  let segs = bspline-to-bezier-segments(pts, degree: degree, closed: closed, knots: knots)
  let p = calc.min(degree, pts.len() - 1)
  make-spline(
    type: "bspline",
    pts: pts,
    closed: closed,
    meta: (degree: p, knots: knots),
    segments: segs,
  )
}
