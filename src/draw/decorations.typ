// cetz-spline: decorations.typ
// Geometric visualizers: tangents, normals, curvature combs, control polygons.

#import "@preview/cetz:0.5.3"
#import "../core/types.typ": assert-spline
#import "../core/catmull_rom.typ": spline-catmull
#import "../core/bezier.typ": (
  spline-eval,
  spline-tangent,
  spline-normal,
  spline-curvature,
)
#import "draw_spline.typ": spline

/// Draw directed tangent / velocity vectors along a spline.
///
/// - spline-obj (spline, array): Spline dictionary or points
/// - samples (int): Number of tangent vectors to draw
/// - scale (float): Arrow length scale
/// - stroke (stroke): Vector arrow stroke
/// - mark (dictionary, str): Endpoint arrow mark
#let draw-tangents(
  spline-obj,
  samples: 10,
  scale: 0.4,
  stroke: 0.8pt + blue,
  mark: (end: ">"),
) = {
  import cetz.draw: line
  let sp = if type(spline-obj) == array { spline-catmull(spline-obj) } else { spline-obj }
  assert-spline(sp)

  let n = calc.max(2, samples)
  let count = if sp.closed { n } else { n }
  let denom = if sp.closed { float(n) } else { float(n - 1) }

  for i in range(0, count) {
    let t = float(i) / denom
    let p = spline-eval(sp, t)
    let tg = spline-tangent(sp, t)
    let p-end = (
      p.at(0) + scale * tg.at(0),
      p.at(1) + scale * tg.at(1),
    )
    line(p, p-end, stroke: stroke, mark: mark)
  }
}

/// Draw perpendicular normal vectors along a spline.
///
/// - spline-obj (spline, array): Spline dictionary or points
/// - samples (int): Number of normal vectors to draw
/// - scale (float): Arrow length scale
/// - stroke (stroke): Vector arrow stroke
/// - mark (dictionary, str): Endpoint arrow mark
#let draw-normals(
  spline-obj,
  samples: 10,
  scale: 0.4,
  stroke: 0.8pt + red,
  mark: (end: ">"),
) = {
  import cetz.draw: line
  let sp = if type(spline-obj) == array { spline-catmull(spline-obj) } else { spline-obj }
  assert-spline(sp)

  let n = calc.max(2, samples)
  let count = if sp.closed { n } else { n }
  let denom = if sp.closed { float(n) } else { float(n - 1) }

  for i in range(0, count) {
    let t = float(i) / denom
    let p = spline-eval(sp, t)
    let nrm = spline-normal(sp, t)
    let p-end = (
      p.at(0) + scale * nrm.at(0),
      p.at(1) + scale * nrm.at(1),
    )
    line(p, p-end, stroke: stroke, mark: mark)
  }
}

/// Draw a CAD-style curvature comb: spikes proportional to signed curvature kappa(u) * N(u)
/// connected by a smooth envelope curve.
///
/// - spline-obj (spline, array): Spline dictionary or points
/// - samples (int): Number of comb needles
/// - scale (float): Curvature spike amplification factor
/// - stroke (stroke): Spike needle stroke
/// - envelope-stroke (stroke, none): Stroke for outer envelope curve
/// - fill (paint, none): Optional fill under comb
#let draw-curvature-comb(
  spline-obj,
  samples: 40,
  scale: 0.5,
  stroke: 0.5pt + gray,
  envelope-stroke: 0.8pt + blue,
  fill: none,
) = {
  import cetz.draw: line, polygon, merge-path

  let sp = if type(spline-obj) == array { spline-catmull(spline-obj) } else { spline-obj }
  assert-spline(sp)

  let n = calc.max(3, samples)
  let denom = if sp.closed { float(n) } else { float(n - 1) }

  let base-pts = ()
  let tip-pts = ()

  for i in range(0, n) {
    let t = float(i) / denom
    let p = spline-eval(sp, t)
    let nrm = spline-normal(sp, t)
    let k = spline-curvature(sp, t)

    let spike-len = scale * k
    let tip = (
      p.at(0) + spike-len * nrm.at(0),
      p.at(1) + spike-len * nrm.at(1),
    )

    base-pts.push(p)
    tip-pts.push(tip)

    // Draw individual comb needle
    line(p, tip, stroke: stroke)
  }

  // Draw optional fill polygon
  if fill != none {
    let poly-pts = base-pts
    for j in range(tip-pts.len() - 1, -1, step: -1) {
      poly-pts.push(tip-pts.at(j))
    }
    polygon(..poly-pts, fill: fill, stroke: none)
  }

  // Draw envelope curve connecting needle tips
  if envelope-stroke != none {
    if tip-pts.len() >= 2 {
      spline(tip-pts, stroke: envelope-stroke, close: sp.closed)
    }
  }
}

/// Draw the Bézier control polygon and handle bars.
///
/// - spline-obj (spline): Spline dictionary
/// - stroke (stroke): Handle line stroke
/// - pt-radius (float): Radius of handle vertices
/// - pt-fill (paint): Vertex fill color
#let draw-control-polygon(
  spline-obj,
  stroke: (paint: luma(160), thickness: 0.6pt, dash: "dashed"),
  pt-radius: 0.05,
  pt-fill: luma(120),
) = {
  import cetz.draw: line, circle

  assert-spline(spline-obj)

  // Draw handle bars for each segment
  for seg in spline-obj.segments {
    let (s, e, c1, c2) = seg
    line(s, c1, stroke: stroke)
    line(e, c2, stroke: stroke)
    circle(c1, radius: pt-radius, fill: pt-fill, stroke: none)
    circle(c2, radius: pt-radius, fill: pt-fill, stroke: none)
  }

  // Draw original control points if present
  if spline-obj.pts.len() > 0 {
    for i in range(0, spline-obj.pts.len() - 1) {
      line(spline-obj.pts.at(i), spline-obj.pts.at(i + 1), stroke: stroke)
    }
    if spline-obj.closed and spline-obj.pts.len() >= 3 {
      line(spline-obj.pts.last(), spline-obj.pts.first(), stroke: stroke)
    }
    for pt in spline-obj.pts {
      circle(pt, radius: pt-radius * 1.2, fill: pt-fill, stroke: 0.5pt + black)
    }
  }
}
