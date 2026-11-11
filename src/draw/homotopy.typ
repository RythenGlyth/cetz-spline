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
/// - mode (str): Morphing mode: `"auto"`, `"segment"`, or `"arc-length"`
/// - samples (int, auto): Resample count when using arc-length mode
#let draw-homotopy(
  spline-a,
  spline-b,
  steps: 5,
  stroke-fn: (t) => 0.8pt + rgb(int(255 * (1 - t)), 0, int(255 * t)),
  mode: "auto",
  samples: auto,
  ..style
) = {
  assert-spline(spline-a, name: "spline-a")
  assert-spline(spline-b, name: "spline-b")

  assert(type(steps) == int and steps >= 1, message: "steps must be a positive integer")
  let n = steps
  for i in range(0, n + 1) {
    let t = float(i) / float(n)
    let intermediate = homotopy(spline-a, spline-b, t, mode: mode, samples: samples)
    let stk = stroke-fn(t)
    spline(intermediate, stroke: stk, ..style.named())
  }
}

/// Draw a directed deformation vector field connecting spline-a to spline-b.
///
/// - spline-a (spline): Source curve
/// - spline-b (spline): Target curve
/// - samples (int): Number of vector field arrows
/// - stroke (stroke): Arrow stroke
/// - mark (dictionary, str): Endpoint arrow mark
/// - mode (str): Arrow distribution: `"arc-length"` (default, uniform physical spacing) or `"segment"`
#let draw-homotopy-field(
  spline-a,
  spline-b,
  samples: 8,
  stroke: 0.8pt + blue,
  mark: (end: ">"),
  mode: "arc-length",
  ..style,
) = {
  assert(style.pos() == (), message: "Unexpected positional arguments")
  import cetz.draw: line
  import "../core/bezier.typ": spline-eval

  assert-spline(spline-a, name: "spline-a")
  assert-spline(spline-b, name: "spline-b")

  assert(type(samples) == int and samples >= 2, message: "samples must be an integer >= 2")
  let n = samples
  assert(mode in ("segment", "arc-length"), message: "mode must be segment or arc-length")
  let (pts-a, pts-b) = if mode == "segment" {
    let pa = ()
    let pb = ()
    for i in range(0, n) {
      let t = float(i) / float(if spline-a.closed and spline-b.closed { n } else { n - 1 })
      pa.push(spline-eval(spline-a, t))
      pb.push(spline-eval(spline-b, t))
    }
    (pa, pb)
  } else {
    (resample(spline-a, n), resample(spline-b, n))
  }

  for i in range(0, n) {
    let pa = pts-a.at(i)
    let pb = pts-b.at(i)
    line(pa, pb, stroke: stroke, mark: mark, ..style.named())
  }
}

