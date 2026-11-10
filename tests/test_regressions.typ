#import "../src/lib.typ" as cs
#import "@preview/cetz:0.5.3"
#let near(a, b, eps: 1e-6) = assert(calc.abs(a - b) <= eps, message: repr((a, b)))
#let point-near(a, b, eps: 1e-6) = {
  near(a.at(0), b.at(0), eps: eps)
  near(a.at(1), b.at(1), eps: eps)
}

// Natural endpoints must differ from extrapolated boundaries on a bent curve.
#{
  let pts = ((0, 0), (1, 3), (4, -1), (6, 2))
  let sp = cs.spline-catmull(pts, boundary: "natural")
  point-near(cs.spline-second-derivative(sp, 0), (0, 0))
  point-near(cs.spline-second-derivative(sp, 1), (0, 0))
  for (i, pt) in pts.enumerate() { point-near(cs.spline-eval(sp, i / 3), pt) }
  assert(sp.segments != cs.spline-catmull(pts).segments)
}

// Compare extracted cubics with an independent de Boor evaluator, including
// nonuniform and repeated knots; global t assigns equal time to each span.
#{
  let pts = ((0, 0), (1, 3), (2, -2), (3, 4), (5, 1), (6, 0))
  for degree in (1, 2, 3) {
    let knots = cs.generate-clamped-knots(pts.len(), degree)
    let sp = cs.spline-bspline(pts, degree: degree)
    let spans = range(degree, pts.len()).map(i => (knots.at(i), knots.at(i + 1)))
    for (i, span) in spans.enumerate() {
      for u in (0.0, 0.17, 0.5, 0.83, 1.0) {
        point-near(cs.spline-eval(sp, (i + u) / spans.len()),
          cs.cox-de-boor(span.at(0) + u * (span.at(1) - span.at(0)), degree, knots, pts))
      }
    }
  }
  let knots = (0, 0, 0, 0, 0.2, 0.2, 1, 1, 1, 1)
  let sp = cs.spline-bspline(pts, knots: knots)
  for (i, span) in ((0, 0.2), (0.2, 1)).enumerate() {
    for u in (0.0, 0.2, 0.7, 1.0) {
      point-near(cs.spline-eval(sp, (i + u) / 2), cs.cox-de-boor(span.at(0) + u * (span.at(1) - span.at(0)), 3, knots, pts))
    }
  }
  let closed = cs.spline-bspline(pts, closed: true)
  point-near(cs.spline-eval(closed, 0), cs.spline-eval(closed, 1))
  point-near(cs.spline-derivative(closed, 0), cs.spline-derivative(closed, 1))
}

// Difficult looping geometry: compare length with a dense chord sum, then
// check partial-length additivity and distance inversion at many positions.
#{
  let seg = ((0, 0), (0.1, 0), (4, 8), (-4, -7))
  let sp = cs.make-spline(segments: (seg,))
  let polygon-length = 0.0
  let prev = cs.spline-eval(sp, 0)
  for i in range(1, 2001) {
    let p = cs.spline-eval(sp, i / 2000)
    polygon-length += cetz.vector.len(cetz.vector.sub(p, prev))
    prev = p
  }
  let length = cs.spline-arc-length(sp)
  near(length, polygon-length, eps: 1e-4)
  near(cs.spline-arc-length(sp, t2: 0.37) + cs.spline-arc-length(sp, t1: 0.37), length)
  near(cs.spline-arc-length(sp, t1: 1, t2: 0), -length)
  for ratio in (0, 0.01, 0.1, 0.3, 0.5, 0.7, 0.99, 1) {
    let t = cs.spline-t-for-distance(sp, ratio * length)
    near(cs.spline-arc-length(sp, t2: t), ratio * length, eps: 2e-6)
  }
  let cached = cs.with-lut(sp)
  near(cs.spline-arc-length(cs.scale(cached, 3)), 3 * length)
  near(cs.spline-arc-length(cs.translate(cached, (2, 3))), length)
}

// Zero-length geometry, clamping, closed resampling and exact line offsets.
#{
  let zero = cs.spline-catmull(((1, 1), (1, 1), (1, 1)))
  near(cs.spline-arc-length(zero), 0)
  point-near(cs.spline-point-at-distance(zero, 5), (1, 1))
  let line = cs.spline-catmull(((0, 0), (4, 0)))
  point-near(cs.spline-eval(line, -1), (0, 0))
  point-near(cs.spline-eval(line, 2), (4, 0))
  point-near(cs.spline-eval(cs.offset(line, 2), 0.5), (2, 2))
  let samples = cs.resample(line, 5)
  for (i, p) in samples.enumerate() { point-near(p, (i, 0)) }
  let loop = cs.spline-catmull(((0, 0), (2, 0), (1, 2)), closed: true)
  let samples = cs.resample(loop, 6)
  assert(samples.len() == 6 and samples.first() != samples.last())
  assert(cs.homotopy(line, cs.translate(line, (0, 2)), 0) == line)
}

// Assert actual anchor positions and inherited styles, rather than merely
// compiling markers. Dynamic anchors must use the same canvas transform.
#cetz.canvas({
  import cetz.draw: *
  translate((2, 3))
  scale(2)
  set-style(stroke: (paint: orange, thickness: 3pt), fill: green)
  cs.draw.spline(((0, 0), (4, 0)), name: "curve", fill-rule: "even-odd")
  get-ctx(ctx => {
    let node = ctx.nodes.at("curve")
    for key in ("mid", "t(50%)", "s(50%)", "50%", "t-0_5", "s-50") {
      point-near((node.anchors)(key), (6, 3))
    }
    let path = node.drawables.first()
    assert(path.stroke.paint == orange)
    assert(path.fill == green)
    assert(path.fill-rule == "even-odd")
    ()
  })
})

// Hermite approximation above cubic degree retains endpoints and approximates
// this quartic with its known Hermite error polynomial.
#{
  let pts = ((0, 0), (1, 1), (2, -1), (3, 2), (4, 0))
  let sp = cs.spline-bspline(pts, degree: 4)
  let knots = cs.generate-clamped-knots(5, 4)
  for t in (0, 0.1, 0.25, 0.5, 0.75, 0.9, 1) {
    let exact = cs.cox-de-boor(t, 4, knots, pts)
    let a = if t < 0.5 { 0 } else { 0.5 }
    let b = a + 0.5
    // Quartic leading coefficient is -18; cubic Hermite error is
    // exact - approximation = -18 (t - a)^2 (t - b)^2.
    point-near(cs.spline-eval(sp, t), (exact.at(0), exact.at(1) + 18 * (t - a) * (t - a) * (t - b) * (t - b)))
  }
  let seg = cs.spline-catmull(((0, 0), (2, 3), (4, 0))).segments.first()
  let (left, right) = cs.cubic-split(..seg, 0.3)
  point-near(cs.cubic-point(..left, 1), cs.cubic-point(..right, 0))
  point-near(cs.cubic-point(..left, 0.5), cs.cubic-point(..seg, 0.15))
}
