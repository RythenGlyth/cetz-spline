// Endpoint-defined splines. Tangents always point in the traversal direction,
// including the end tangent (not an outward-facing CAD handle).
#import "@preview/cetz:0.5.3": vector
#import "types.typ": make-spline, clean-point

/// Construct one cubic from endpoint positions and endpoint derivatives.
/// Tangent vectors include magnitude and are derivatives with respect to t in
/// [0, 1]. `auto` uses the endpoint displacement, yielding a straight default.
#let spline-hermite(start, end, start-tangent: auto, end-tangent: auto) = {
  let s = clean-point(start)
  let e = clean-point(end)
  let chord = vector.sub(e, s)
  let v0 = if start-tangent == auto { chord } else { clean-point(start-tangent) }
  let v1 = if end-tangent == auto { chord } else { clean-point(end-tangent) }
  make-spline(
    type: "hermite",
    pts: (s, e),
    segments: ((s, e,
      vector.add(s, vector.scale(v0, 1 / 3)),
      vector.sub(e, vector.scale(v1, 1 / 3)),
    ),),
  )
}

#let _direction(value, chord, name) = {
  let v = if value == auto {
    chord
  } else if type(value) == angle {
    (calc.cos(value), calc.sin(value))
  } else {
    clean-point(value)
  }
  let length = vector.len(v)
  assert(length > 0, message: name + " must have nonzero length; supply a direction for coincident endpoints")
  vector.scale(v, 1 / length)
}

#let _sum(..terms) = {
  let result = (0.0, 0.0)
  for (v, weight) in terms.pos() {
    result = vector.add(result, vector.scale(v, weight))
  }
  result
}

/// Construct an endpoint-curvature-controlled C2 piecewise cubic transition.
/// Directions accept angles or nonzero vectors (their magnitude is ignored).
/// Speeds are |C'(t)| at t=0 and t=1; `auto` uses the chord length.
/// Curvatures are signed: positive bends left along traversal, negative right.
/// Endpoint tangential acceleration is zero. Three equal-duration cubic spans
/// meet with matching first and second derivatives. No shape/regularity or
/// intersection guarantee is implied by satisfying these boundary constraints.
#let spline-transition(
  start,
  end,
  start-tangent: auto,
  end-tangent: auto,
  start-curvature: 0,
  end-curvature: 0,
  start-speed: auto,
  end-speed: auto,
) = {
  let s = clean-point(start)
  let e = clean-point(end)
  let chord = vector.sub(e, s)
  let chord-length = vector.len(chord)
  let t0 = _direction(start-tangent, chord, "start-tangent")
  let t1 = _direction(end-tangent, chord, "end-tangent")
  let speed0 = if start-speed == auto { chord-length } else { start-speed }
  let speed1 = if end-speed == auto { chord-length } else { end-speed }
  assert(type(speed0) in (int, float) and speed0 > 0, message: "start-speed must be a positive number; supply a speed for coincident endpoints")
  assert(type(speed1) in (int, float) and speed1 > 0, message: "end-speed must be a positive number; supply a speed for coincident endpoints")
  assert(type(start-curvature) in (int, float) and type(end-curvature) in (int, float), message: "Endpoint curvatures must be numbers")

  let v0 = vector.scale(t0, speed0)
  let v1 = vector.scale(t1, speed1)
  let a0 = vector.scale((-t0.at(1), t0.at(0)), start-curvature * speed0 * speed0)
  let a1 = vector.scale((-t1.at(1), t1.at(0)), end-curvature * speed1 * speed1)

  // Three constant jerk vectors determine a C2 piecewise cubic. Integrating
  // them over h=1/3 gives the endpoint residual equations:
  // j0+j1+j2=A; 5j0+3j1+j2=V; 19j0+7j1+j2=P.
  let A = _sum((a1, 3), (a0, -3))
  let V = _sum((v1, 18), (v0, -18), (a0, -18))
  let P = _sum((e, 162), (s, -162), (v0, -162), (a0, -81))
  let jerks = (
    _sum((P, 1 / 6), (A, 1 / 3), (V, -1 / 2)),
    _sum((V, 3 / 2), (A, -7 / 6), (P, -1 / 3)),
    _sum((A, 11 / 6), (V, -1), (P, 1 / 6)),
  )
  let h = 1 / 3
  let p = s
  let v = v0
  let a = a0
  let segments = ()
  for j in jerks {
    let next = _sum((p, 1), (v, h), (a, h * h / 2), (j, h * h * h / 6))
    let c1 = _sum((p, 1), (v, h / 3))
    let c2 = _sum((p, 1), (v, 2 * h / 3), (a, h * h / 6))
    segments.push((p, next, c1, c2))
    p = next
    v = _sum((v, 1), (a, h), (j, h * h / 2))
    a = _sum((a, 1), (j, h))
  }
  make-spline(
    type: "transition",
    pts: (s, e),
    meta: (start-curvature: start-curvature, end-curvature: end-curvature),
    segments: segments,
  )
}
