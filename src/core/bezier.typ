// cetz-spline: bezier.typ
// Bézier curve analysis: second derivatives, curvature, oriented left normal and tangent vectors.

#import "@preview/cetz:0.5.3": vector, util
#import "types.typ": assert-spline, clean-point

#let bezier = util.bezier

/// Evaluate point on cubic Bézier segment at parameter `u` in [0, 1].
/// - s (point): start point
/// - e (point): end point
/// - c1 (point): control point 1
/// - c2 (point): control point 2
/// - u (float): parameter [0, 1]
#let cubic-point(s, e, c1, c2, u) = {
  bezier.cubic-point(s, e, c1, c2, u)
}

/// Compute velocity / first derivative C'(u) of cubic Bézier segment.
#let cubic-derivative(s, e, c1, c2, u) = {
  bezier.cubic-derivative(s, e, c1, c2, u)
}

/// Compute acceleration / second derivative C''(u) of cubic Bézier segment.
/// For P0 = s, P1 = c1, P2 = c2, P3 = e:
/// C''(u) = 6(1-u)(c2 - 2*c1 + s) + 6u(e - 2*c2 + c1)
#let cubic-second-derivative(s, e, c1, c2, u) = {
  let v0 = vector.add(vector.sub(c2, vector.scale(c1, 2.0)), s)
  let v1 = vector.add(vector.sub(e, vector.scale(c2, 2.0)), c1)
  vector.scale(vector.add(vector.scale(v0, 1.0 - u), vector.scale(v1, u)), 6.0)
}

/// Compute unit tangent vector T(u) of cubic Bézier segment.
#let cubic-tangent(s, e, c1, c2, u) = {
  let d1 = bezier.cubic-derivative(s, e, c1, c2, u)
  let speed = vector.len(d1)
  if speed < 1e-9 {
    let delta = 1e-4
    let u-alt = if u < 0.5 { u + delta } else { u - delta }
    d1 = bezier.cubic-derivative(s, e, c1, c2, u-alt)
    speed = vector.len(d1)
    if speed < 1e-9 { return (1.0, 0.0) }
  }
  vector.scale(d1, 1.0 / speed)
}

/// Compute unit normal vector N(u) = (-T_y(u), T_x(u)) of cubic Bézier segment.
#let cubic-normal(s, e, c1, c2, u) = {
  let t = cubic-tangent(s, e, c1, c2, u)
  (-t.at(1), t.at(0))
}

/// Compute signed curvature kappa(u) of cubic Bézier segment.
/// kappa(u) = (x' y'' - y' x'') / (x'^2 + y'^2)^(3/2)
#let cubic-curvature(s, e, c1, c2, u) = {
  let d1 = bezier.cubic-derivative(s, e, c1, c2, u)
  let d2 = cubic-second-derivative(s, e, c1, c2, u)
  let speed-sq = vector.dot(d1, d1)
  if speed-sq < 1e-12 { return 0.0 }
  let num = d1.at(0) * d2.at(1) - d1.at(1) * d2.at(0)
  num / calc.pow(speed-sq, 1.5)
}

/// Split a cubic Bézier segment at parameter `u`.
#let cubic-split(s, e, c1, c2, u) = {
  bezier.split(s, e, c1, c2, u)
}

/// Split a CeTZ cubic tuple `(s, e, c1, c2)` into `count` equal-parameter
/// pieces, preserving its geometry up to floating-point rounding. The pieces
/// have equal parameter widths, not necessarily equal physical lengths.
/// `count` must be a positive integer; count=1 returns the original tuple.
#let subdivide-segment(segment, count) = {
  assert(type(segment) == array and segment.len() == 4,
    message: "segment must be a cubic tuple (s, e, c1, c2)")
  assert(type(count) == int and count >= 1, message: "count must be a positive integer")
  let pieces = ()
  let remaining = segment
  for i in range(count - 1) {
    let (piece, rest) = cubic-split(..remaining, 1 / (count - i))
    pieces.push(piece)
    remaining = rest
  }
  (..pieces, remaining)
}

/// Internal helper: map global parameter t in [0, 1] to (segment_index, local_u).
#let _resolve-spline-t(spline, t) = {
  assert-spline(spline)
  let n = spline.segments.len()
  assert(n > 0, message: "Spline has no segments")
  let t-clamped = calc.max(0.0, calc.min(1.0, float(t)))
  if t-clamped >= 1.0 {
    return (n - 1, 1.0)
  }
  let v = t-clamped * n
  let idx = calc.min(calc.floor(v), n - 1)
  let u = v - idx
  (int(idx), u)
}

/// Evaluate spline position at global parameter t in [0, 1].
#let spline-eval(spline, t) = {
  let (idx, u) = _resolve-spline-t(spline, t)
  let seg = spline.segments.at(idx)
  cubic-point(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u)
}

/// Evaluate spline first derivative C'(t) at global parameter t in [0, 1].
/// Note: Scaled with respect to global parameter t (dC/dt = N * dC/du).
#let spline-derivative(spline, t) = {
  let (idx, u) = _resolve-spline-t(spline, t)
  let seg = spline.segments.at(idx)
  let n = float(spline.segments.len())
  let d = cubic-derivative(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u)
  vector.scale(d, n)
}

/// Evaluate spline acceleration / second derivative C''(t) at global parameter t in [0, 1].
#let spline-second-derivative(spline, t) = {
  let (idx, u) = _resolve-spline-t(spline, t)
  let seg = spline.segments.at(idx)
  let n = float(spline.segments.len())
  let d2 = cubic-second-derivative(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u)
  vector.scale(d2, n * n)
}

/// Evaluate unit tangent vector T(t) of spline at global parameter t in [0, 1].
#let spline-tangent(spline, t) = {
  let (idx, u) = _resolve-spline-t(spline, t)
  let seg = spline.segments.at(idx)
  cubic-tangent(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u)
}

/// Evaluate unit normal vector N(t) of spline at global parameter t in [0, 1].
#let spline-normal(spline, t) = {
  let (idx, u) = _resolve-spline-t(spline, t)
  let seg = spline.segments.at(idx)
  cubic-normal(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u)
}

/// Evaluate signed curvature kappa(t) of spline at global parameter t in [0, 1].
#let spline-curvature(spline, t) = {
  let (idx, u) = _resolve-spline-t(spline, t)
  let seg = spline.segments.at(idx)
  cubic-curvature(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u)
}

/// Compute normal direction angle of cubic Bézier segment as a Typst angle.
#let cubic-normal-angle(s, e, c1, c2, u) = {
  let n = cubic-normal(s, e, c1, c2, u)
  calc.atan2(n.at(0), n.at(1))
}

/// Compute tangent direction angle of cubic Bézier segment as a Typst angle.
#let cubic-tangent-angle(s, e, c1, c2, u) = {
  let tau = cubic-tangent(s, e, c1, c2, u)
  calc.atan2(tau.at(0), tau.at(1))
}

/// Evaluate unit normal vector angle of spline at global parameter t in [0, 1].
/// Returns a Typst angle (e.g. `90deg`, `-45deg`).
#let spline-normal-angle(spline, t) = {
  let n = spline-normal(spline, t)
  calc.atan2(n.at(0), n.at(1))
}

/// Evaluate unit tangent vector angle of spline at global parameter t in [0, 1].
/// Returns a Typst angle (e.g. `0deg`, `45deg`).
#let spline-tangent-angle(spline, t) = {
  let tau = spline-tangent(spline, t)
  calc.atan2(tau.at(0), tau.at(1))
}

/// Compute recommended CeTZ content anchor angle for placing labels along the curve normal.
///
/// If `side` is 1 (default), places the label on the outer normal side.
/// If `side` is -1, places the label on the inner/opposite side.
///
/// Example:
/// ```typst
/// content(pos, [Peak], anchor: cs.spline-label-anchor(sp, 0.5), padding: 0.15)
/// ```
#let spline-label-anchor(spline, t, side: 1) = {
  let n-ang = spline-normal-angle(spline, t)
  if side >= 0 {
    n-ang + 180deg
  } else {
    n-ang
  }
}
