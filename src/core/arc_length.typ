// cetz-spline: arc_length.typ
// High-precision arc-length computation using 5-point Gauss-Legendre quadrature
// and Newton-Raphson distance inversion (s -> t).

#import "@preview/cetz:0.5.3": vector, util
#import "types.typ": assert-spline
#import "bezier.typ": (
  cubic-derivative,
  cubic-point,
  spline-eval,
  spline-normal,
  spline-normal-angle,
  spline-tangent,
  spline-tangent-angle,
  spline-label-anchor,
  _resolve-spline-t,
)

// Gauss-Legendre 5-point quadrature constants on [-1, 1]
#let _gl5-roots = (
  0.0,
  0.538469310105683,
  -0.538469310105683,
  0.906179845938664,
  -0.906179845938664,
)

#let _gl5-weights = (
  128.0 / 225.0,
  (322.0 + 13.0 * calc.sqrt(70.0)) / 900.0,
  (322.0 + 13.0 * calc.sqrt(70.0)) / 900.0,
  (322.0 - 13.0 * calc.sqrt(70.0)) / 900.0,
  (322.0 - 13.0 * calc.sqrt(70.0)) / 900.0,
)

/// Compute arc length of a single cubic Bézier segment between parameters u1 and u2.
/// Uses 5-point Gauss-Legendre numerical quadrature.
///
/// - s (point): start point
/// - e (point): end point
/// - c1 (point): control point 1
/// - c2 (point): control point 2
/// - u1 (float): lower bound [0, 1]
/// - u2 (float): upper bound [0, 1]
/// -> float
#let _quadrature(s, e, c1, c2, u1: 0.0, u2: 1.0) = {
  let a = float(u1)
  let b = float(u2)
  if calc.abs(b - a) < 1e-12 {
    return 0.0
  }
  let sign = 1.0
  if b < a {
    let tmp = a
    a = b
    b = tmp
    sign = -1.0
  }

  let h = (b - a) / 2.0
  let mid = (a + b) / 2.0
  let sum = 0.0

  for i in range(0, 5) {
    let u = mid + h * _gl5-roots.at(i)
    let d = cubic-derivative(s, e, c1, c2, u)
    let speed = vector.len(d)
    sum += _gl5-weights.at(i) * speed
  }

  sign * h * sum
}

// Refine only intervals whose two-half estimate differs materially.
#let segment-arc-length(s, e, c1, c2, u1: 0.0, u2: 1.0) = {
  let integrate(a, b, whole, depth) = {
    let mid = (a + b) / 2
    let left = _quadrature(s, e, c1, c2, u1: a, u2: mid)
    let right = _quadrature(s, e, c1, c2, u1: mid, u2: b)
    let refined = left + right
    if depth == 0 or calc.abs(refined - whole) <= 1e-9 * (1 + calc.abs(refined)) {
      return refined
    }
    integrate(a, mid, left, depth - 1) + integrate(mid, b, right, depth - 1)
  }
  integrate(u1, u2, _quadrature(s, e, c1, c2, u1: u1, u2: u2), 12)
}

/// Build an arc-length lookup table (LUT) for a spline.
/// Stores cumulative segment lengths and equidistant parameter samples for fast inversion.
#let build-arc-length-lut(spline, samples-per-segment: 10) = {
  assert(type(samples-per-segment) == int and samples-per-segment >= 1, message: "samples-per-segment must be a positive integer")
  assert-spline(spline)
  let n = spline.segments.len()
  if n == 0 {
    return (
      total-length: 0.0,
      segment-lengths: (),
      cumulative-lengths: (0.0,),
      samples-per-segment: samples-per-segment,
      sub-tables: (),
    )
  }

  let seg-lengths = ()
  let cum-lengths = (0.0,)
  let sub-tables = ()
  let running-total = 0.0

  for seg in spline.segments {
    let (s, e, c1, c2) = seg
    let seg-len = 0.0
    let sub-cum = (0.0,)
    let dt = 1.0 / float(samples-per-segment)

    for step in range(0, samples-per-segment) {
      let u0 = float(step) * dt
      let u1 = float(step + 1) * dt
      let step-len = segment-arc-length(s, e, c1, c2, u1: u0, u2: u1)
      seg-len += step-len
      sub-cum.push(seg-len)
    }

    seg-lengths.push(seg-len)
    running-total += seg-len
    cum-lengths.push(running-total)
    sub-tables.push(sub-cum)
  }

  (
    total-length: running-total,
    segment-lengths: seg-lengths,
    cumulative-lengths: cum-lengths,
    samples-per-segment: samples-per-segment,
    sub-tables: sub-tables,
  )
}

/// Attach or retrieve cached arc-length LUT from a spline.
#let ensure-lut(spline, samples-per-segment: 10) = {
  assert-spline(spline)
  if spline.lut != none {
    return spline.lut
  }
  build-arc-length-lut(spline, samples-per-segment: samples-per-segment)
}

/// Return a copy of the spline with the lookup table pre-computed and stored.
#let with-lut(spline, samples-per-segment: 10) = {
  assert-spline(spline)
  let lut = ensure-lut(spline, samples-per-segment: samples-per-segment)
  let copy = spline
  copy.lut = lut
  copy
}

/// Compute total arc length of a spline, or length between parameters t1 and t2 in [0, 1].
///
/// - spline (spline): Spline dictionary
/// - t1 (float): Start parameter [0, 1]
/// - t2 (float): End parameter [0, 1]
/// -> float
#let spline-arc-length(spline, t1: 0.0, t2: 1.0) = {
  assert-spline(spline)
  let n = spline.segments.len()
  if n == 0 { return 0.0 }
  if t1 == 0.0 and t2 == 1.0 {
    let lut = ensure-lut(spline)
    return lut.total-length
  }

  let t-start = calc.max(0.0, calc.min(1.0, float(t1)))
  let t-end = calc.max(0.0, calc.min(1.0, float(t2)))
  if calc.abs(t-end - t-start) < 1e-12 { return 0.0 }

  let sign = 1.0
  if t-end < t-start {
    let tmp = t-start
    t-start = t-end
    t-end = tmp
    sign = -1.0
  }

  let (idx1, u1) = _resolve-spline-t(spline, t-start)
  let (idx2, u2) = _resolve-spline-t(spline, t-end)

  if idx1 == idx2 {
    let seg = spline.segments.at(idx1)
    return sign * segment-arc-length(seg.at(0), seg.at(1), seg.at(2), seg.at(3), u1: u1, u2: u2)
  }

  let total = 0.0
  // First segment
  let seg1 = spline.segments.at(idx1)
  total += segment-arc-length(seg1.at(0), seg1.at(1), seg1.at(2), seg1.at(3), u1: u1, u2: 1.0)

  // Intermediate full segments
  if idx2 > idx1 + 1 {
    let lut = ensure-lut(spline)
    for i in range(idx1 + 1, idx2) {
      total += lut.segment-lengths.at(i)
    }
  }

  // Last segment
  let seg2 = spline.segments.at(idx2)
  total += segment-arc-length(seg2.at(0), seg2.at(1), seg2.at(2), seg2.at(3), u1: 0.0, u2: u2)

  sign * total
}

/// Invert arc-length distance s in [0, L] to global parameter t in [0, 1] using Newton-Raphson.
///
/// - spline (spline): Spline dictionary
/// - distance (float): Arc length distance from curve start
/// -> float in [0, 1]
#let spline-t-for-distance(spline, distance) = {
  assert-spline(spline)
  let n = spline.segments.len()
  if n == 0 { return 0.0 }

  let lut = ensure-lut(spline)
  let L = lut.total-length
  if L < 1e-12 { return 0.0 }

  let s = float(distance)
  if s <= 0.0 { return 0.0 }
  if s >= L { return 1.0 }

  // Binary search segment index
  let idx = 0
  let low = 0
  let high = n - 1
  while low <= high {
    let mid = calc.floor((low + high) / 2)
    let s-start = lut.cumulative-lengths.at(mid)
    let s-end = lut.cumulative-lengths.at(mid + 1)
    if s >= s-start and s <= s-end {
      idx = mid
      break
    } else if s < s-start {
      high = mid - 1
    } else {
      low = mid + 1
    }
  }

  let seg = spline.segments.at(idx)
  let (s-pt, e-pt, c1-pt, c2-pt) = seg
  let seg-s-start = lut.cumulative-lengths.at(idx)
  let target-seg-s = s - seg-s-start
  let seg-len = lut.segment-lengths.at(idx)

  // Initial estimate
  let u = if seg-len > 1e-9 { calc.max(0.0, calc.min(1.0, target-seg-s / seg-len)) } else { 0.5 }

  // Newton-Raphson iterations
  let lower = 0.0
  let upper = 1.0
  let max-iter = 32
  let tol = 1e-6
  for _ in range(0, max-iter) {
    let current-s = segment-arc-length(s-pt, e-pt, c1-pt, c2-pt, u1: 0.0, u2: u)
    let diff = current-s - target-seg-s
    if calc.abs(diff) < tol {
      break
    }
    let d = cubic-derivative(s-pt, e-pt, c1-pt, c2-pt, u)
    let speed = vector.len(d)
    if diff > 0 { upper = u } else { lower = u }
    let u-next = if speed > 1e-12 { u - diff / speed } else { (lower + upper) / 2 }
    u = if lower < u-next and u-next < upper { u-next } else { (lower + upper) / 2 }
  }

  (float(idx) + u) / float(n)
}

/// Evaluate spline position at numerical arc-length distance `distance` from start.
///
/// - spline (spline): Spline dictionary
/// - distance (float): Distance in curve coordinate units
/// -> point (x, y)
#let spline-point-at-distance(spline, distance) = {
  let t = spline-t-for-distance(spline, distance)
  spline-eval(spline, t)
}

/// Evaluate unit normal vector N at numerical arc-length distance `distance`.
#let spline-normal-at-distance(spline, distance) = {
  let t = spline-t-for-distance(spline, distance)
  spline-normal(spline, t)
}

/// Evaluate unit normal vector direction angle at numerical arc-length distance `distance`.
/// Returns a Typst angle (e.g. `90deg`, `-45deg`).
#let spline-normal-angle-at-distance(spline, distance) = {
  let t = spline-t-for-distance(spline, distance)
  spline-normal-angle(spline, t)
}

/// Evaluate unit tangent vector T at numerical arc-length distance `distance`.
#let spline-tangent-at-distance(spline, distance) = {
  let t = spline-t-for-distance(spline, distance)
  spline-tangent(spline, t)
}

/// Evaluate unit tangent vector direction angle at numerical arc-length distance `distance`.
#let spline-tangent-angle-at-distance(spline, distance) = {
  let t = spline-t-for-distance(spline, distance)
  spline-tangent-angle(spline, t)
}

/// Compute recommended CeTZ content anchor angle for placing labels along the curve normal
/// at numerical arc-length distance `distance`.
#let spline-label-anchor-at-distance(spline, distance, side: 1) = {
  let t = spline-t-for-distance(spline, distance)
  spline-label-anchor(spline, t, side: side)
}

