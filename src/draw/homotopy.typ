// cetz-spline: homotopy.typ
// Dedicated topological drawing functions: homotopy families and deformation vector fields.

#import "@preview/cetz:0.5.3"
#import "../core/types.typ": assert-spline
#import "../core/ops.typ": homotopy, resample
#import "draw_spline.typ": spline

/// Draw a continuous family of intermediate curves between spline-a and spline-b.
///
/// - spline-a (spline): Starting curve (t = 0)
/// - spline-b (spline): Ending curve (t = 1)
/// - steps (int): Number of intermediate subdivisions (total curves = steps + 1)
/// - stroke-fn (function): Function mapping t in [0, 1] to a stroke style
#let draw-homotopy(
  spline-a,
  spline-b,
  steps: 5,
  stroke-fn: (t) => 0.8pt + rgb(int(255 * (1 - t)), 0, int(255 * t)),
) = {
  assert-spline(spline-a, name: "spline-a")
  assert-spline(spline-b, name: "spline-b")

  let n = calc.max(1, steps)
  for i in range(0, n + 1) {
    let t = float(i) / float(n)
    let intermediate = homotopy(spline-a, spline-b, t)
    let stk = stroke-fn(t)
    spline(intermediate, stroke: stk)
  }
}

/// Draw a directed deformation vector field connecting spline-a to spline-b
/// at uniform arc-length intervals.
///
/// - spline-a (spline): Source curve
/// - spline-b (spline): Target curve
/// - samples (int): Number of vector field arrows
/// - stroke (stroke): Arrow stroke
/// - mark (dictionary, str): Endpoint arrow mark
#let draw-homotopy-field(
  spline-a,
  spline-b,
  samples: 8,
  stroke: 0.8pt + blue,
  mark: (end: ">"),
) = {
  import cetz.draw: line

  assert-spline(spline-a, name: "spline-a")
  assert-spline(spline-b, name: "spline-b")

  let n = calc.max(2, samples)
  let pts-a = resample(spline-a, n)
  let pts-b = resample(spline-b, n)

  for i in range(0, n) {
    let pa = pts-a.at(i)
    let pb = pts-b.at(i)
    line(pa, pb, stroke: stroke, mark: mark)
  }
}
