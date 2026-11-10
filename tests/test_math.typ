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
