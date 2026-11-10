// cetz-spline: draw_spline.typ
// CeTZ canvas element wrapper for splines with dynamic anchor resolution.

#import "@preview/cetz:0.5.3"
#import "../core/types.typ": assert-spline
#import "../core/catmull_rom.typ": spline-catmull
#import "../core/bezier.typ": spline-eval
#import "../core/arc_length.typ": spline-arc-length, spline-point-at-distance

/// Private helper: safely parse a string as a float, returning none on failure.
#let _parse-float-or-none(str-val) = {
  let s = str-val.trim()
  if s.ends-with("%") { s = s.slice(0, -1).trim() }
  if s.len() == 0 { return none }
  if not s.contains(regex("^[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][+-]?[0-9]+)?$")) { return none }
  float(s)
}

/// Draw a spline in a CeTZ canvas with dynamic anchor resolution.
///
/// Anchors supported dynamically:
/// - `"start"`, `"end"`, `"mid"`, `"default"`
/// - `"pt-<idx>"`: Original control points or segment endpoints
/// - `"t(<val>)"`: Normalized parameter space position (e.g. `"t(0.5)"`, `"t(50%)"`, `"t(33.3%)"`)
/// - `"s(<val>)"`: Numerical arc length fraction via Gauss-Legendre quadrature (e.g. `"s(0.5)"`, `"s(50%)"`)
/// - `"50%"`, `"25%"`, `"75%"`: Shorthand percentage anchors
/// - `"t-50"`, `"s-50"`, `"t-0_5"`, `"s-0_5"`: Alternate dash-syntax anchors
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
  stroke: auto,
  fill: auto,
  close: false,
  mark: auto,
  ..style,
) = {
  import cetz.draw: group, merge-path, bezier, anchor
  assert(style.pos() == (), message: "Unexpected positional arguments")

  let sp = if type(spline-obj) == array {
    spline-catmull(spline-obj, closed: close)
  } else {
    assert-spline(spline-obj)
    spline-obj
  }

  let is-closed = close or sp.closed
  let n-segs = sp.segments.len()
  assert(n-segs > 0, message: "Cannot draw spline with 0 segments")

  if name != none {
    // 1. Create the internal group and get its state callback
    let (callback,) = group(name: name, {
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

      // Pre-register fundamental static anchors
      let p-start = sp.segments.first().first()
      let p-end = sp.segments.last().at(1)
      let p-mid = spline-eval(sp, 0.5)

      anchor("start", p-start)
      anchor("end", p-end)
      anchor("mid", p-mid)
      anchor("default", p-start)

      if sp.pts.len() > 0 {
        for (i, pt) in sp.pts.enumerate() {
          anchor("pt-" + str(i), pt)
        }
      } else {
        anchor("pt-0", p-start)
        for (i, seg) in sp.segments.enumerate() {
          anchor("pt-" + str(i + 1), seg.at(1))
        }
      }
    })

    let total-l = spline-arc-length(sp)

    // 2. Intercept context layout to dynamically resolve requested anchors on the fly
    ((ctx => {
      let grp = callback(ctx)
      let old-anchors = grp.anchors

      let resolve-anchor(key) = {
        let k-str = if type(key) == array { key.join(".") } else { str(key) }

        // 1. Parameter space: t(...) e.g. "t(50%)", "t(0.5)", "t(33.3%)"
        if k-str.starts-with("t(") and k-str.ends-with(")") {
          let inner = k-str.slice(2, -1)
          let is-pct = inner.trim().ends-with("%")
          let v = _parse-float-or-none(inner)
          if v != none {
            let t = if is-pct or v > 1.0 { v / 100.0 } else { v }
            let p = spline-eval(sp, calc.clamp(t, 0.0, 1.0))
            return cetz.util.apply-transform(ctx.transform, (float(p.at(0)), float(p.at(1)), 0.0))
          }
        }

        // 2. Arc length space: s(...) e.g. "s(50%)", "s(0.5)", "s(75%)"
        if k-str.starts-with("s(") and k-str.ends-with(")") {
          let inner = k-str.slice(2, -1)
          let is-pct = inner.trim().ends-with("%")
          let v = _parse-float-or-none(inner)
          if v != none {
            let ratio = if is-pct or v > 1.0 { v / 100.0 } else { v }
            let dist = calc.clamp(ratio, 0.0, 1.0) * total-l
            let p = spline-point-at-distance(sp, dist)
            return cetz.util.apply-transform(ctx.transform, (float(p.at(0)), float(p.at(1)), 0.0))
          }
        }

        // 3. Dashed syntax: t-50, t-50%, t-0_5, s-50, s-50%, s-0_5
        if k-str.starts-with("t-") {
          let inner = k-str.slice(2).replace("_", ".")
          let is-pct = inner.trim().ends-with("%")
          let v = _parse-float-or-none(inner)
          if v != none {
            let t = if is-pct or v > 1.0 { v / 100.0 } else { v }
            let p = spline-eval(sp, calc.clamp(t, 0.0, 1.0))
            return cetz.util.apply-transform(ctx.transform, (float(p.at(0)), float(p.at(1)), 0.0))
          }
        }

        if k-str.starts-with("s-") {
          let inner = k-str.slice(2).replace("_", ".")
          let is-pct = inner.trim().ends-with("%")
          let v = _parse-float-or-none(inner)
          if v != none {
            let ratio = if is-pct or v > 1.0 { v / 100.0 } else { v }
            let dist = calc.clamp(ratio, 0.0, 1.0) * total-l
            let p = spline-point-at-distance(sp, dist)
            return cetz.util.apply-transform(ctx.transform, (float(p.at(0)), float(p.at(1)), 0.0))
          }
        }

        // 4. Bare percentage: e.g. "50%", "33.3%"
        if k-str.ends-with("%") {
          let v = _parse-float-or-none(k-str)
          if v != none {
            let p = spline-eval(sp, calc.clamp(v / 100.0, 0.0, 1.0))
            return cetz.util.apply-transform(ctx.transform, (float(p.at(0)), float(p.at(1)), 0.0))
          }
        }

        // Fallback to static group anchors (start, end, mid, default, pt-0, pt-1, etc.)
        return old-anchors(key)
      }

      return grp + (anchors: resolve-anchor)
    }),)
  } else {
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
  }
}
