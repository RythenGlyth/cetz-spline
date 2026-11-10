#import "../../src/lib.typ" as cs
#let pts = ((0, 0), (1, 2), (3, 0), (4, 1))
#let sp = cs.spline-catmull(pts)
#{
  let case = sys.inputs.at("case")
  if case == "alpha" { cs.spline-catmull(pts, alpha: -1) }
  else if case == "boundary" { cs.spline-catmull(pts, boundary: "typo") }
  else if case == "points" { cs.spline-bspline(((0, 0),)) }
  else if case == "degree" { cs.spline-bspline(pts, degree: 1.5) }
  else if case == "knot-count" { cs.spline-bspline(pts, knots: (0, 1)) }
  else if case == "knot-order" { cs.spline-bspline(pts, knots: (0, 0, 0, 0, 1, 0, 1, 1)) }
  else if case == "knot-domain" { cs.spline-bspline(pts, knots: (0, 0, 0, 0, 0, 0, 0, 0)) }
  else if case == "discontinuous" {
    cs.spline-bspline(pts, degree: 1, knots: (0, 0, 0.5, 0.5, 1, 1))
  }
  else if case == "count" { cs.resample(sp, 1) }
  else if case == "lut" { cs.with-lut(sp, samples-per-segment: 0) }
  else if case == "mode" { cs.homotopy(sp, sp, 0, mode: "typo") }
  else if case == "transition-direction" { cs.spline-transition((0, 0), (2, 1), start-tangent: (0, 0)) }
  else if case == "transition-speed" { cs.spline-transition((0, 0), (2, 1), end-speed: 0) }
  else if case == "transition-curvature" { cs.spline-transition((0, 0), (2, 1), start-curvature: "bad") }
  else if case == "transition-coincident" { cs.spline-transition((0, 0), (0, 0), start-tangent: 0deg, end-tangent: 0deg) }
  else if case == "topology" { cs.homotopy(sp, cs.spline-catmull(pts, closed: true), 0.5) }
}
