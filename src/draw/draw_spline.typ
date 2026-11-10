// cetz-spline: draw_spline.typ
// CeTZ canvas element wrapper for splines with anchor injection.

#import "@preview/cetz:0.5.3"
#import "../core/types.typ": assert-spline, is-spline
#import "../core/catmull_rom.typ": spline-catmull
#import "../core/bezier.typ": spline-eval
#import "../core/arc_length.typ": spline-arc-length, spline-point-at-distance

/// Draw a spline in a CeTZ canvas with automatic anchor registration.
///
/// Anchors registered:
/// - `"start"`, `"end"`, `"mid"`
/// - `"pt-<idx>"`: Original control points or segment endpoints
/// - `"t(0%)"` .. `"t(100%)"`, `"t(50%)"`, etc.
/// - `"s(0%)"` .. `"s(100%)"`, `"s(50%)"`, etc. (exact arc-length positions)
/// - `"50%"`, `"25%"`, `"75%"`, etc.
///
/// - spline-obj (spline, array): Spline object or array of interpolation points
/// - name (str, none): Element name for anchor resolution
/// - stroke (stroke, none): Curve stroke
/// - fill (paint, none): Curve fill paint
/// - close (bool): Whether to force-close the curve
/// - mark (dictionary, none): Marks placed on path endpoints
#let spline(
  spline-obj,
  name: none,
  stroke: 1pt + black,
  fill: none,
  close: false,
  mark: none,
  ..style,
) = {
  import cetz.draw: group, merge-path, bezier, anchor

  let sp = if type(spline-obj) == array {
    spline-catmull(spline-obj, closed: close)
  } else {
    assert-spline(spline-obj)
    spline-obj
  }

  let is-closed = close or sp.closed
  let n-segs = sp.segments.len()
  assert(n-segs > 0, message: "Cannot draw spline with 0 segments")

  let body = {
    merge-path(
      close: is-closed,
      stroke: stroke,
      fill: fill,
      mark: mark,
      ..style.named(),
      {
        for seg in sp.segments {
          bezier(seg.at(0), seg.at(1), seg.at(2), seg.at(3))
        }
      }
    )

    if name != none {
      // 1. Endpoint & mid anchors
      let p-start = sp.segments.first().first()
      let p-end = sp.segments.last().at(1)
      let p-mid = spline-eval(sp, 0.5)

      anchor("start", p-start)
      anchor("end", p-end)
      anchor("mid", p-mid)
      anchor("default", p-start)

      // 2. Control point anchors: pt-<idx>
      if sp.pts.len() > 0 {
        for (i, pt) in sp.pts.enumerate() {
          anchor("pt-" + str(i), pt)
        }
      } else {
        // If pts is empty, use segment endpoints
        anchor("pt-0", sp.segments.first().first())
        for (i, seg) in sp.segments.enumerate() {
          anchor("pt-" + str(i + 1), seg.at(1))
        }
      }

      // 3. Normalized parameter anchors: t(X%), s(X%), X%
      let total-l = spline-arc-length(sp)
      let ratios = (
        (0.0, "0%"),
        (0.1, "10%"),
        (0.2, "20%"),
        (0.25, "25%"),
        (0.3, "30%"),
        (0.333, "33%"),
        (0.4, "40%"),
        (0.5, "50%"),
        (0.6, "60%"),
        (0.667, "67%"),
        (0.7, "70%"),
        (0.75, "75%"),
        (0.8, "80%"),
        (0.9, "90%"),
        (1.0, "100%"),
      )

      for (r, r-str) in ratios {
        let pt-t = spline-eval(sp, r)
        let pt-s = if total-l > 1e-9 {
          spline-point-at-distance(sp, r * total-l)
        } else {
          pt-t
        }

        anchor("t(" + r-str + ")", pt-t)
        anchor("s(" + r-str + ")", pt-s)
        anchor(r-str, pt-t)
      }

      // Underscore notation: t-0_5, s-0_5
      anchor("t-0_5", p-mid)
      anchor("s-0_5", if total-l > 1e-9 { spline-point-at-distance(sp, 0.5 * total-l) } else { p-mid })
      anchor("t-0_25", spline-eval(sp, 0.25))
      anchor("t-0_75", spline-eval(sp, 0.75))
    }
  }

  if name != none {
    group(name: name, body)
  } else {
    body
  }
}
