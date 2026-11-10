// tests/test_math.typ
#import "@preview/cetz:0.5.3": vector
#import "../src/core/types.typ": clean-point, make-spline
#import "../src/core/bezier.typ": (
  cubic-point,
  cubic-derivative,
  cubic-second-derivative,
  cubic-normal,
  cubic-curvature,
  spline-eval,
  spline-curvature,
  spline-normal,
)

#let approx-eq(a, b, eps: 1e-4) = {
  calc.abs(a - b) < eps
}

// Test 1: Straight line has zero curvature
#{
  let s = (0.0, 0.0)
  let e = (10.0, 0.0)
  let c1 = (3.3333, 0.0)
  let c2 = (6.6667, 0.0)
  let kappa = cubic-curvature(s, e, c1, c2, 0.5)
  assert(approx-eq(kappa, 0.0), message: "Straight line must have 0 curvature, got " + str(kappa))
}

// Test 2: Circular arc approximation
#{
  let k = (4.0 / 3.0) * (calc.sqrt(2.0) - 1.0)
  let s = (1.0, 0.0)
  let e = (0.0, 1.0)
  let c1 = (1.0, k)
  let c2 = (k, 1.0)

  // Midpoint curvature for unit circular arc should be ~ 1.0
  let kappa-mid = cubic-curvature(s, e, c1, c2, 0.5)
  assert(approx-eq(kappa-mid, 1.0, eps: 0.02), message: "Unit circle arc curvature at mid should be ~1.0, got " + str(kappa-mid))

  // Normal vector at start (1, 0) should point towards center (0, 0), i.e. (-1, 0)
  let norm-start = cubic-normal(s, e, c1, c2, 0.0)
  assert(approx-eq(norm-start.at(0), -1.0, eps: 1e-4), message: "Normal x at start should be -1.0")
  assert(approx-eq(norm-start.at(1), 0.0, eps: 1e-4), message: "Normal y at start should be 0.0")

  // Normal vector at end (0, 1) should point towards center (0, 0), i.e. (0, -1)
  let norm-end = cubic-normal(s, e, c1, c2, 1.0)
  assert(approx-eq(norm-end.at(0), 0.0, eps: 1e-4), message: "Normal x at end should be 0.0")
  assert(approx-eq(norm-end.at(1), -1.0, eps: 1e-4), message: "Normal y at end should be -1.0")
}

// Test 3: Second derivative formula verification
#{
  let s = (0.0, 0.0)
  let c1 = (1.0 / 3.0, 0.0)
  let c2 = (2.0 / 3.0, 1.0 / 3.0)
  let e = (1.0, 1.0)

  // Q(u) has Q'(u) = (1, 2u), Q''(u) = (0, 2) constant everywhere!
  for u in (0.0, 0.25, 0.5, 0.75, 1.0) {
    let d2 = cubic-second-derivative(s, e, c1, c2, u)
    assert(approx-eq(d2.at(0), 0.0, eps: 1e-4), message: "d2.x should be 0")
    assert(approx-eq(d2.at(1), 2.0, eps: 1e-4), message: "d2.y should be 2.0, got " + str(d2.at(1)))
  }
}

Math tests passed!

// Test 4: Arc-length Gauss-Legendre quadrature
#import "../src/core/arc_length.typ": (
  segment-arc-length,
  spline-arc-length,
  spline-t-for-distance,
  spline-point-at-distance,
)
#import "../src/core/catmull_rom.typ": spline-catmull

#{
  // Straight line from (0,0) to (10, 0)
  let s = (0.0, 0.0)
  let e = (10.0, 0.0)
  let c1 = (3.333333, 0.0)
  let c2 = (6.666667, 0.0)
  let len = segment-arc-length(s, e, c1, c2, u1: 0.0, u2: 1.0)
  assert(approx-eq(len, 10.0, eps: 1e-4), message: "Segment length should be 10.0, got " + str(len))

  // Half length
  let half-len = segment-arc-length(s, e, c1, c2, u1: 0.0, u2: 0.5)
  assert(approx-eq(half-len, 5.0, eps: 1e-4), message: "Half length should be 5.0, got " + str(half-len))

  // Inversion on multi-segment spline
  let pts = ((0.0, 0.0), (5.0, 0.0), (10.0, 0.0))
  let sp = spline-catmull(pts, alpha: 0.5)
  let total-l = spline-arc-length(sp)
  assert(approx-eq(total-l, 10.0, eps: 1e-3), message: "Total spline length should be ~10, got " + str(total-l))

  // Point at distance 7.5
  let pt-75 = spline-point-at-distance(sp, 7.5)
  assert(approx-eq(pt-75.at(0), 7.5, eps: 1e-3), message: "Point at distance 7.5 should have x ~ 7.5, got " + repr(pt-75))
}

// Test 5: Rotation and affine transforms
#import "../src/core/ops.typ": (
  rotate-spline,
  rotate,
  translate-spline,
  scale-spline,
  mirror-spline,
  mirror,
)

#{
  let pts = ((0.0, 0.0), (2.0, 0.0), (4.0, 0.0))
  let sp = spline-catmull(pts, alpha: 0.5)

  // 1. Rotate 90deg around origin (0, 0)
  let rot-90 = rotate-spline(sp, 90deg, origin: (0.0, 0.0))
  let p-start = spline-eval(rot-90, 0.0)
  let p-mid = spline-eval(rot-90, 0.5)
  let p-end = spline-eval(rot-90, 1.0)

  assert(approx-eq(p-start.at(0), 0.0) and approx-eq(p-start.at(1), 0.0), message: "Start should be (0, 0)")
  assert(approx-eq(p-mid.at(0), 0.0) and approx-eq(p-mid.at(1), 2.0), message: "Mid should be (0, 2), got " + repr(p-mid))
  assert(approx-eq(p-end.at(0), 0.0) and approx-eq(p-end.at(1), 4.0), message: "End should be (0, 4), got " + repr(p-end))

  // Arc length must be preserved under rotation
  let l-orig = spline-arc-length(sp)
  let l-rot = spline-arc-length(rot-90)
  assert(approx-eq(l-orig, l-rot, eps: 1e-4), message: "Arc length must be invariant under rotation")

  // 2. Rotate around non-origin pivot: rotate around midpoint (2, 0) by 90deg
  let rot-pivot = rotate(sp, 90deg, origin: (2.0, 0.0))
  let piv-start = spline-eval(rot-pivot, 0.0)
  let piv-mid = spline-eval(rot-pivot, 0.5)
  let piv-end = spline-eval(rot-pivot, 1.0)
  assert(approx-eq(piv-start.at(0), 2.0) and approx-eq(piv-start.at(1), -2.0), message: "Pivot start should be (2, -2), got " + repr(piv-start))
  assert(approx-eq(piv-mid.at(0), 2.0) and approx-eq(piv-mid.at(1), 0.0), message: "Pivot mid should be (2, 0)")
  assert(approx-eq(piv-end.at(0), 2.0) and approx-eq(piv-end.at(1), 2.0), message: "Pivot end should be (2, 2), got " + repr(piv-end))

  // 3. Translation
  let trans = translate-spline(sp, (1.0, 3.0))
  let tr-start = spline-eval(trans, 0.0)
  let tr-end = spline-eval(trans, 1.0)
  assert(approx-eq(tr-start.at(0), 1.0) and approx-eq(tr-start.at(1), 3.0))
  assert(approx-eq(tr-end.at(0), 5.0) and approx-eq(tr-end.at(1), 3.0))

  // 4. Scaling (uniform, non-uniform, negative)
  let sc = scale-spline(sp, 2.0, origin: (0.0, 0.0))
  let sc-end = spline-eval(sc, 1.0)
  assert(approx-eq(sc-end.at(0), 8.0) and approx-eq(sc-end.at(1), 0.0))

  // Negative scale: point reflection through (0, 0)
  let sc-neg = scale-spline(sp, -1.0, origin: (0.0, 0.0))
  let neg-end = spline-eval(sc-neg, 1.0)
  assert(approx-eq(neg-end.at(0), -4.0) and approx-eq(neg-end.at(1), 0.0))

  // 5. Directional scaling: scale in direction (1, 1) by factor 3.0
  // Curve points (0,0), (2,0), (4,0).
  // At (2,0): d = (2,0). u = (1/sqrt(2), 1/sqrt(2)), v = (-1/sqrt(2), 1/sqrt(2))
  // du = 2/sqrt(2) = sqrt(2). dv = -sqrt(2)
  // Scaled d': su*du*u + sv*dv*v = 3 * sqrt(2) * (1/sqrt(2), 1/sqrt(2)) + 1 * (-sqrt(2)) * (-1/sqrt(2), 1/sqrt(2))
  //           = (3, 3) + (1, -1) = (4, 2)
  let sc-dir = scale-spline(sp, 3.0, origin: (0.0, 0.0), dir: (1.0, 1.0))
  let p-dir-mid = spline-eval(sc-dir, 0.5)
  assert(approx-eq(p-dir-mid.at(0), 4.0, eps: 1e-4) and approx-eq(p-dir-mid.at(1), 2.0, eps: 1e-4),
    message: "Directional scale mid should be (4, 2), got " + repr(p-dir-mid))

  // 6. Mirroring
  let pts2 = ((1.0, 1.0), (2.0, 3.0), (3.0, 2.0))
  let sp2 = spline-catmull(pts2, alpha: 0.5)

  // Mirror across x-axis through (0,0) -> y negated
  let mir-x = mirror-spline(sp2, axis: "x")
  let mx-start = spline-eval(mir-x, 0.0)
  assert(approx-eq(mx-start.at(0), 1.0) and approx-eq(mx-start.at(1), -1.0),
    message: "Mirror-x should negate y: got " + repr(mx-start))

  // Mirror across y-axis through (0,0) -> x negated
  let mir-y = mirror-spline(sp2, axis: "y")
  let my-start = spline-eval(mir-y, 0.0)
  assert(approx-eq(my-start.at(0), -1.0) and approx-eq(my-start.at(1), 1.0),
    message: "Mirror-y should negate x: got " + repr(my-start))

  // Mirror across diagonal 45deg line y = x through (0,0) -> swaps x and y
  let mir-diag = mirror-spline(sp2, axis: 45deg)
  let md-start = spline-eval(mir-diag, 0.0)
  assert(approx-eq(md-start.at(0), 1.0) and approx-eq(md-start.at(1), 1.0))
  let md-mid = spline-eval(mir-diag, 0.5)
  let orig-mid = spline-eval(sp2, 0.5)
  assert(approx-eq(md-mid.at(0), orig-mid.at(1), eps: 1e-4) and approx-eq(md-mid.at(1), orig-mid.at(0), eps: 1e-4),
    message: "Mirror across 45deg should swap x and y")

  // Point reflection through (1, 1):
  let mir-pt = mirror-spline(sp2, origin: (1.0, 1.0), axis: none)
  let mp-start = spline-eval(mir-pt, 0.0)
  assert(approx-eq(mp-start.at(0), 1.0) and approx-eq(mp-start.at(1), 1.0))
}
