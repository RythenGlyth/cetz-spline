#import "../src/lib.typ" as cs
#import "@preview/cetz:0.5.3": vector
#let near(a, b, eps: 1e-8) = assert(calc.abs(a - b) < eps, message: repr((a, b)))
#let point-near(a, b, eps: 1e-8) = {
  near(a.at(0), b.at(0), eps: eps)
  near(a.at(1), b.at(1), eps: eps)
}

// Cubic Hermite matches endpoint positions and full derivatives, not just
// tangent directions. Compare an interior point with the independent basis.
#{
  let s = (1, -2)
  let e = (5, 3)
  let v0 = (4, 7)
  let v1 = (2, -1)
  let sp = cs.spline-hermite(s, e, start-tangent: v0, end-tangent: v1)
  assert(cs.segment-count(sp) == 1)
  point-near(cs.spline-eval(sp, 0), s)
  point-near(cs.spline-eval(sp, 1), e)
  point-near(cs.spline-derivative(sp, 0), v0)
  point-near(cs.spline-derivative(sp, 1), v1)
  for t in (0.1, 0.37, 0.7) {
    let h00 = 2*t*t*t - 3*t*t + 1
    let h10 = t*t*t - 2*t*t + t
    let h01 = -2*t*t*t + 3*t*t
    let h11 = t*t*t - t*t
    let expected = vector.add(vector.add(vector.scale(s, h00), vector.scale(v0, h10)),
      vector.add(vector.scale(e, h01), vector.scale(v1, h11)))
    point-near(cs.spline-eval(sp, t), expected)
  }
  let line = cs.spline-hermite((0, 0), (3, 0))
  point-near(cs.spline-eval(line, 0.4), (1.2, 0))
  let stationary = cs.spline-hermite((0, 0), (1, 0), start-tangent: (0, 0))
  point-near(cs.spline-derivative(stationary, 0), (0, 0))
}

// Independently prescribed endpoint derivatives and signed curvatures are met.
// Check C2 on each side of both joins using local cubic derivatives, avoiding
// sampling near a boundary (which could hide a discontinuity).
#{
  for (k0, k1) in ((0.0, 0.0), (0.4, -0.7), (-1.0, 0.2)) {
    let sp = cs.spline-transition((1, 2), (6, -1),
      start-tangent: (3, 4), end-tangent: -30deg,
      start-speed: 2, end-speed: 4,
      start-curvature: k0, end-curvature: k1)
    assert(cs.segment-count(sp) == 3)
    point-near(cs.spline-eval(sp, 0), (1, 2))
    point-near(cs.spline-eval(sp, 1), (6, -1))
    point-near(cs.spline-derivative(sp, 0), (1.2, 1.6))
    point-near(cs.spline-derivative(sp, 1), (4 * calc.cos(-30deg), -2))
    near(cs.spline-curvature(sp, 0), k0)
    near(cs.spline-curvature(sp, 1), k1)
    near(vector.dot(cs.spline-derivative(sp, 0), cs.spline-second-derivative(sp, 0)), 0)
    near(vector.dot(cs.spline-derivative(sp, 1), cs.spline-second-derivative(sp, 1)), 0)
    for i in (0, 1) {
      let a = cs.get-segment(sp, i)
      let b = cs.get-segment(sp, i + 1)
      point-near(a.at(1), b.at(0))
      point-near(cs.cubic-derivative(..a, 1), cs.cubic-derivative(..b, 0))
      point-near(cs.cubic-second-derivative(..a, 1), cs.cubic-second-derivative(..b, 0))
    }
  }
  let line = cs.spline-transition((0, 0), (3, 0))
  for t in (0.0, 0.2, 0.6, 1.0) {
    point-near(cs.spline-eval(line, t), (3 * t, 0))
    near(cs.spline-curvature(line, t), 0)
  }
  // Magnitudes of direction vectors must not change the transition.
  let a = cs.spline-transition((0, 0), (3, 1), start-tangent: (1, 0))
  let b = cs.spline-transition((0, 0), (3, 1), start-tangent: (20, 0))
  for t in (0.0, 0.3, 0.8, 1.0) { point-near(cs.spline-eval(a, t), cs.spline-eval(b, t)) }
  // Coincident endpoints are supported with explicit directions and speeds.
  let loop = cs.spline-transition((0, 0), (0, 0), start-tangent: 0deg,
    end-tangent: 90deg, start-speed: 2, end-speed: 2)
  point-near(cs.spline-eval(loop, 1), (0, 0))
}

// An existing cubic can be continued at G2 by matching its oriented tangent
// and signed curvature at the join, while freely choosing the new end.
#{
  let a = cs.spline-hermite((0, 0), (2, 1), start-tangent: (2, 0), end-tangent: (2, 2))
  let b = cs.spline-transition(cs.spline-eval(a, 1), (5, 0),
    start-tangent: cs.spline-tangent(a, 1),
    start-curvature: cs.spline-curvature(a, 1), end-tangent: 0deg)
  point-near(cs.spline-tangent(a, 1), cs.spline-tangent(b, 0))
  near(cs.spline-curvature(a, 1), cs.spline-curvature(b, 0))
}
