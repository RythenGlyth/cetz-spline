// manual.typ
// Reference Manual for cetz-spline
// Follows the official CeTZ documentation architecture

#import "@preview/cetz:0.5.3"
#import "src/lib.typ" as cs

#set document(
  title: "cetz-spline Manual",
  author: "RythenGlyth",
)

#set page(
  paper: "a4",
  margin: (x: 2.2cm, top: 2.5cm, bottom: 2.5cm),
  header: context {
    let i = counter(page).get().first()
    if i > 1 [
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8.5pt, fill: luma(100), font: "Liberation Sans")[cetz-spline]],
        align(right)[#text(size: 8.5pt, fill: luma(100), font: "Liberation Sans")[Manual]],
      )
      #v(-4pt)
      #line(length: 100%, stroke: 0.5pt + luma(200))
    ]
  },
  footer: context {
    let i = counter(page).get().first()
    if i > 1 [
      #line(length: 100%, stroke: 0.5pt + luma(200))
      #v(2pt)
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8.5pt, fill: luma(100), font: "Liberation Sans")[cetz-spline 0.1.0]],
        align(right)[#text(size: 8.5pt, fill: luma(100), font: "Liberation Sans", weight: "bold")[#i]],
      )
    ]
  },
)

#set text(font: "Liberation Serif", size: 10pt, lang: "en")
#set par(justify: true, leading: 0.65em)
#show raw: set text(font: "Liberation Mono", size: 8.8pt)

#set heading(numbering: (..nums) => {
  let nums = nums.pos()
  if nums.len() <= 2 {
    return nums.map(n => [#n]).join([.])
  }
})

// CeTZ-native type pill colors
#let type-colors = (
  "any": rgb("#eff0f3"),
  "content": rgb("#a6ebe6"),
  "str": rgb("#d1ffe2"),
  "string": rgb("#d1ffe2"),
  "none": rgb("#ffcbc4"),
  "auto": rgb("#ffcbc4"),
  "bool": rgb("#ffedc1"),
  "boolean": rgb("#ffedc1"),
  "int": rgb("#e7d9ff"),
  "integer": rgb("#e7d9ff"),
  "float": rgb("#e7d9ff"),
  "number": rgb("#e7d9ff"),
  "function": rgb("#f9dfff"),
  "array": rgb("#e7d9ff"),
  "spline": rgb("#dbeafe"),
  "element": rgb("#fed7aa"),
  "coordinate": rgb("#fef08a"),
  "point": rgb("#e0e7ff"),
  "vector": rgb("#e0e7ff"),
  "stroke": rgb("#e2e8f0"),
  "paint": rgb("#fbcfe8"),
)

#let show-type(name) = {
  box(
    raw(name),
    inset: (x: 3.5pt, y: 1.5pt),
    baseline: 1pt,
    radius: 2pt,
    fill: type-colors.at(name, default: type-colors.at("any")),
    stroke: none,
  )
}

#let render-example(code, vertical: false) = {
  let columns = if vertical { (1fr,) } else { (1fr, 1.4fr) }
  let alignments = if vertical {
    (x, y) => (center + top, left + top).at(y)
  } else {
    (x, y) => (center + horizon, left + top).at(x)
  }
  let line = if vertical { table.hline } else { table.vline }

  block(
    radius: 3pt,
    stroke: 0.8pt + luma(180),
    fill: rgb("#fafafa"),
    breakable: false,
    {
      table(
        columns: columns,
        align: alignments,
        stroke: none,
        inset: 9pt,
        cetz.canvas({
          let preamble = "import cetz.draw: *\nimport cs.draw: *\n"
          eval("{\n" + preamble + code + "\n}", mode: "code", scope: (
            cetz: cetz,
            cs: cs,
          ))
        }),
        line(stroke: (paint: luma(180), thickness: 0.8pt, dash: "dashed")),
        raw(code.trim(), lang: "typc"),
      )
    }
  )
}

#show raw.where(lang: "example"): it => render-example(it.text)
#show raw.where(lang: "example-vertical"): it => render-example(it.text, vertical: true)

// Function documentation layout (CeTZ manual style)
#let fn-doc(
  name,
  args: (),
  ret: none,
  description,
  parameters: (),
) = block(
  breakable: false,
  width: 100%,
  above: 1.6em,
  below: 1.2em,
  {
    // Signature
    block(
      fill: rgb("#f4f7fb"),
      inset: (x: 8pt, y: 6pt),
      radius: 3pt,
      stroke: (left: 3pt + rgb("#2b6cb0")),
      {
        text(rgb("#1a4971"), weight: "bold", raw(name))
        raw("(")
        if args.len() > 0 {
          [\ ]
          for arg in args {
            h(1.2em)
            raw(arg.at(0))
            if arg.len() > 1 and arg.at(1) != none {
              [ ]
              show-type(arg.at(1))
            }
            if arg.len() > 2 and arg.at(2) != none {
              text(luma(100))[#raw(" = " + repr(arg.at(2)))]
            }
            if arg != args.last() [,\ ] else [\ ]
          }
        }
        raw(")")
        if ret != none [
          #h(4pt) #sym.arrow.r #h(4pt) #show-type(ret)
        ]
      }
    )

    v(0.3em)
    description

    if parameters.len() > 0 {
      v(0.4em)
      text(weight: "bold", size: 8.8pt)[Parameters]
      list(
        ..parameters.map(p => [
          #strong(raw(p.at(0))) #show-type(p.at(1)) \
          #p.at(2)
        ])
      )
    }
  }
)

// =========================================================================
// TITLE & METADATA
// =========================================================================

#v(1.2em)
#align(center)[
  #text(2.4em, weight: "bold", font: "Liberation Sans")[cetz-spline]
  #v(0.3em)
  #text(1.15em, fill: rgb("#334155"), font: "Liberation Sans")[Advanced Curve Geometry and Splines for CeTZ]

  #v(0.8em)
  #grid(
    columns: (auto, auto, auto, auto),
    gutter: 2.2em,
    [#text(weight: "bold")[Version:] 0.1.0],
    [#text(weight: "bold")[Compiler:] #sym.gt.eq 0.15.0],
    [#text(weight: "bold")[CeTZ:] 0.5.3],
    [#text(weight: "bold")[License:] MIT],
  )
]

#v(1.5em)
#columns(2, outline(depth: 3))
#pagebreak()

// =========================================================================
// 1. OVERVIEW
// =========================================================================

= Overview

`cetz-spline` provides a mathematically rigorous spline and curve geometry library built specifically for the CeTZ canvas ecosystem.

CeTZ already includes 2D/3D vector mathematics (`cetz.vector`), basic cubic Bézier evaluation (`cubic-point`, `cubic-derivative`), and de Casteljau curve splitting (`split`). `cetz-spline` directly re-uses those primitives and focuses strictly on higher-order geometric operations that CeTZ does not provide:

- *Centripetal and Chordal Catmull-Rom Parameterization* ($alpha = 0.5, 1.0$): CeTZ only implements uniform Catmull-Rom ($alpha = 0$), which produces self-intersections and loops around sharp corners. Centripetal parameterization prevents cusps and self-intersections within regular individual segments.
- *Second Derivatives and Curvature Fields*: Piecewise acceleration vectors $C''(u)$, oriented left unit normal fields $bold(N)(u)$, and signed scalar curvature $kappa(u)$.
- *Arbitrary-Degree B-Splines*: Cox-de Boor evaluation with cubic conversion for degrees up to three and cubic approximation for higher degrees.
- *High-Precision Arc Length*: 5-point Gauss-Legendre numerical quadrature with Newton-Raphson distance inversion ($s |-> t$).
- *Parallel Offset Curves*: Normal-offset curves $C(u) + d dot bold(N)(u)$ with curvature-scaled tangent matching.
- *Homotopies and Deformation Vector Fields*: Morphing families $(1-t) A + t B$ and directional deformation vectors connecting curves at equal arc-length fractions.
- *CAD-Style Geometric Visualizers*: Curvature needles and envelope curves, unit tangent vectors, normal fields, and control polygons.

CeTZ supplies the canvas, paths, transforms, and coordinate system. This package adds reusable spline objects, geometric analysis, distance queries, and drawing helpers. Import the package as `cs` to avoid collisions between geometric transformations such as `cs.scale` and CeTZ canvas transformations such as `cetz.draw.scale`.

= Getting Started

== Usage

Import `cetz` and `cetz-spline` into your document:

```typst
#import "@preview/cetz:0.5.3"
#import "@preview/cetz-spline:0.1.0" as cs
```

Spline rendering functions are typically called inside a CeTZ canvas block:

```example
let pts = ((0, 0), (1.5, 2.5), (3.5, 0.5), (5, 2))
let sp = cs.spline-catmull(pts, alpha: 0.5)

spline(sp, name: "c", stroke: 2pt + blue)
circle("c.pt-1", radius: 0.15, fill: red)
circle("c.pt-2", radius: 0.15, fill: red)
circle("c.mid", radius: 0.15, fill: orange)
circle("c.end", radius: 0.12, fill: black)
content("c.pt-1", text(size: 8pt, fill: black)[P1], anchor: "south", padding: 7pt)
content("c.pt-2", text(size: 8pt, fill: black)[P2], anchor: "north", padding: 7pt)
content("c.mid", text(size: 8pt, fill: black)[Mid], anchor: "south-west", padding: 5pt)
content("c.end", text(size: 8pt, fill: black)[End], anchor: "south-west", padding: 5pt)
```

#block(breakable: false)[
== Named Anchors

When `name: "..."` is passed to `cs.draw.spline`, the following named anchors are injected:
- `"start"`, `"end"`: curve extremities
- `"mid"`: midpoint at global parameter $t = 0.5$
- `"pt-<idx>"`: original control points (`"pt-0"`, `"pt-1"`, ...)
- `"t(X%)"`: position at parameter ratio (e.g. `"t(25%)"`, `"t(50%)"`, `"t(75%)"`)
- `"s(X%)"`: position at numerical arc-length ratio (e.g. `"s(50%)"`)
- `"50%"`, `"25%"`, `"75%"`: standard CeTZ path percentage anchors

]

= Practical Guide

== Choose the Curve for the Task

Use `cs.spline-catmull` when the curve must pass through every data point, for example a route or a measured profile. Start with `alpha: 0.5`; `alpha: 0` and `alpha: 1` are useful comparisons, not universal improvements. Use `cs.spline-bspline` when the points should act as a control polygon: interior points generally do not lie on the curve. Open clamped B-splines interpolate their first and last points. Closed curves wrap automatically; do not repeat the first point at the end.

When the endpoint behavior drives the design, use `cs.spline-hermite` for a single cubic with specified derivatives, or `cs.spline-transition` for endpoint directions and signed curvatures. The latter is useful for joining profiles at $G^2$ continuity.

== Interpolation versus Control Points

Both curves below use the same points. Blue interpolates them; orange is pulled towards them. The dashed polygon is the input data, rather than the individual cubic handle polygons.

```example-vertical
let pts = ((0, 0), (1, 2), (3, -1), (5, 1))
line(..pts, stroke: (paint: gray, dash: "dashed"))
spline(cs.spline-catmull(pts), stroke: 1.5pt + blue)
spline(cs.spline-bspline(pts), stroke: 1.5pt + orange)
for pt in pts { circle(pt, radius: 0.07, fill: black) }
content((0, 3), [Blue: interpolation], anchor: "west")
content((0, 2.5), [Orange: B-spline], anchor: "west")
```

#block(breakable: false)[
== Place Markers at Equal Distances

A parameter midpoint is not necessarily halfway along the curve. In the upper row below, equal $t$ steps cluster on the short first segment. In the lower row, equal distance fractions give evenly spaced markers along the same geometry. These are distances along the curve, rather than straight-line distances between markers.

```example-vertical
let sp = cs.with-lut(cs.spline-catmull(((0, 0), (0.5, 0), (5, 0))))
spline(sp, name: "t", stroke: gray)
let shifted = cs.translate(sp, (0, -0.7))
spline(shifted, name: "s", stroke: gray)
for i in range(0, 9) {
  let pct = str(i * 12.5) + "%"
  circle("t.t(" + pct + ")", radius: 0.055, fill: blue)
  circle("s.s(" + pct + ")", radius: 0.055, fill: orange)
}
content((5.2, 0), [Equal t], anchor: "west")
content((5.2, -0.7), [Equal distance], anchor: "west")
```

]

#block(breakable: false)[
== Label a Curve and Inherit Canvas Styles

The label anchor is chosen from the left normal so the text sits beside the curve. Use `side: -1` for the opposite side. Distance values in analytical functions are absolute canvas units; `.s(50%)` is a fraction of total length.

```example-vertical
let sp = cs.with-lut(cs.spline-catmull(((0, 0), (2, 1.5), (4, 0))))
set-style(stroke: (paint: teal, thickness: 1.5pt))
spline(sp, name: "route", mark: (end: ">"))
let d = cs.spline-arc-length(sp) * 0.6
circle("route.s(60%)", radius: 0.06, fill: teal)
content("route.s(60%)", [60% of the route],
  anchor: cs.spline-label-anchor-at-distance(sp, d), padding: 0.15)
```

]

== Numerical and API Conventions

Each stored cubic receives the same share of global $t$. Position and distance queries clamp to the curve domain. Reversing arc-length integration limits returns a negative length. Numeric `.s(0.5)` and `.t(0.5)` mean fractions; write percentages explicitly to avoid ambiguity. Legacy numeric anchor values above one are interpreted as percentages. Bare percentage anchors mean parameter fractions in this package.

Sampling counts must be integers (`resample`: at least two; comb: at least three; homotopy resampling: at least four). Homotopy inputs must both be open or both closed. The arc-length mode rebuilds an interpolating curve through sampled correspondences, so it is an approximation. For closed curves, align their start points and traversal directions before morphing.

The mathematical notes at the end explain continuity, orientation, and numerical limitations. They are optional for drawing and labeling curves.

= API Reference

== Spline Constructors

#fn-doc(
  "spline-catmull",
  args: (
    ("points", "array"),
    ("alpha", "float", 0.5),
    ("closed", "bool", false),
    ("boundary", "str", "clamped"),
  ),
  ret: "spline",
  [Constructs a Catmull-Rom spline through a list of points using generalized knot spacing.],
  parameters: (
    ("points", "array", [Array of 2D coordinates `((x0, y0), (x1, y1), ...)`.]),
    ("alpha", "float", [Knot exponent: `0.0` (uniform), `0.5` (centripetal, default), or `1.0` (chordal).]),
    ("closed", "bool", [Whether the curve is a closed periodic loop.]),
    ("boundary", "str", [Open endpoint treatment: `"clamped"` extrapolates virtual points along endpoint chords; it does not prescribe a user-supplied derivative. `"natural"` adjusts exterior handles to give zero second derivatives at both ends.]),
  )
)

```example
let pts = ((0, 0), (1, 2), (3, 0), (4, 2))
let sp = cs.spline-catmull(pts, alpha: 0.5)
spline(sp, stroke: 1.5pt + blue)
for pt in pts { circle(pt, radius: 0.08, fill: black) }
```

#fn-doc(
  "spline-bspline",
  args: (
    ("points", "array"),
    ("degree", "int", 3),
    ("closed", "bool", false),
    ("knots", "array", none),
  ),
  ret: "spline",
  [Constructs a B-spline via Cox-de Boor recursion. Degrees up to three have exact cubic representations; higher degrees are approximated. The effective degree is limited to the number of points minus one.],
  parameters: (
    ("points", "array", [Array of control polygon vertices.]),
    ("degree", "int", [Polynomial degree (default: 3 for cubic B-spline).]),
    ("closed", "bool", [Whether the spline forms a closed periodic loop.]),
    ("knots", "array", [Optional custom knot vector. Defaults to clamped open-uniform knots.]),
  )
)

```example
let pts = ((0, 0), (1, 3), (3, 3), (4, 0), (5, 2))
let sp = cs.spline-bspline(pts, degree: 3)
draw-control-polygon(sp)
spline(sp, stroke: 2pt + teal)
```

== Endpoint-Defined Splines

#fn-doc(
  "spline-hermite",
  args: (
    ("start", "point"),
    ("end", "point"),
    ("start-tangent", "vector", auto),
    ("end-tangent", "vector", auto),
  ),
  ret: "spline",
  [Constructs one cubic from endpoint positions and derivative vectors. For this constructor, a tangent includes its magnitude: it is $C'(t)$ at the endpoint. `auto` uses `end - start`. Both tangents point along traversal, including the end tangent. Zero vectors are allowed, but produce stationary endpoints with undefined geometric tangent or curvature.],
)

The two interior Bézier poles are computed as `start + start-tangent / 3` and `end - end-tangent / 3`. Increasing a vector's magnitude pulls the curve farther along its direction.

```example-vertical
let a = cs.spline-hermite((0, 0), (4, 0),
  start-tangent: (2, 3), end-tangent: (2, -3))
let b = cs.spline-hermite((0, 0), (4, 0),
  start-tangent: (4, 6), end-tangent: (4, -6))
spline(a, stroke: 1.5pt + blue)
spline(b, stroke: 1.5pt + orange)
circle((0, 0), radius: 0.06, fill: black)
circle((4, 0), radius: 0.06, fill: black)
content((2, 2), [Orange: twice the derivatives], anchor: "south")
```

#fn-doc(
  "spline-transition",
  args: (
    ("start", "point"),
    ("end", "point"),
    ("start-tangent", "any", auto),
    ("end-tangent", "any", auto),
    ("start-curvature", "number", 0),
    ("end-curvature", "number", 0),
    ("start-speed", "number", auto),
    ("end-speed", "number", auto),
  ),
  ret: "spline",
  [Constructs a curvature-controlled transition from three cubic spans with continuous first and second derivatives. Tangents are directions: pass Typst angles or nonzero vectors; vector magnitudes are ignored. `auto` uses the chord direction. Endpoint curvatures are signed, positive to the left of traversal. Speeds are positive derivative magnitudes, with `auto` using the chord length.],
)

A general single cubic cannot independently match both endpoint positions, both derivative vectors, and both curvatures. This constructor instead builds a $C^2$ piecewise cubic, meeting the endpoint constraints up to floating-point rounding. Endpoint tangential acceleration is set to zero. The curve is not necessarily free from loops, interior stationary points, or overshoot; endpoint constraints alone do not establish those properties. Coincident endpoints require explicit directions and speeds.

For a $G^2$ continuation of an existing curve, use its end position, forward tangent, and signed curvature as the new start constraints. The example below additionally sets the start speed to the previous derivative magnitude, matching first derivatives as well. It does not generally match the previous full acceleration vector.

```example-vertical
let a = cs.spline-hermite((0, 0), (2, 1),
  start-tangent: (2, 0), end-tangent: (2, 2))
let b = cs.spline-transition(cs.spline-eval(a, 1), (5, 1),
  start-tangent: cs.spline-tangent(a, 1),
  start-curvature: cs.spline-curvature(a, 1),
  start-speed: cetz.vector.len(cs.spline-derivative(a, 1)),
  end-tangent: -20deg, end-curvature: 0)
draw-curvature-comb(a, samples: 18, scale: 0.4,
  stroke: 0.4pt + blue, envelope-stroke: none)
draw-curvature-comb(b, samples: 30, scale: 0.4,
  stroke: 0.4pt + orange, envelope-stroke: none)
spline(a, stroke: 1.5pt + blue)
spline(b, stroke: 1.5pt + orange)
circle((2, 1), radius: 0.06, fill: black)
content((2, 1), [G2 join], anchor: "south-east", padding: 0.15)
```

== Analytical Evaluation

#fn-doc(
  "spline-eval",
  args: (("spline", "spline"), ("t", "float")),
  ret: "point",
  [Evaluates position $C(t) in bb(R)^2$ on the spline for parameter $t in [0, 1]$.],
  parameters: (
    ("spline", "spline", [Target spline dictionary.]),
    ("t", "float", [Global parameter in range $[0, 1]$.]),
  )
)

#fn-doc(
  "spline-derivative",
  args: (("spline", "spline"), ("t", "float")),
  ret: "vector",
  [Computes velocity vector $C'(t) = frac(d C, d t)$ scaled with respect to global parameter $t$.],
)

#fn-doc(
  "spline-second-derivative",
  args: (("spline", "spline"), ("t", "float")),
  ret: "vector",
  [Computes acceleration vector $C''(t) = frac(d^2 C, d t^2)$.],
)

#fn-doc(
  "spline-tangent",
  args: (("spline", "spline"), ("t", "float")),
  ret: "vector",
  [Computes normalized unit tangent vector $bold(T)(t) = frac(C'(t), ||C'(t)||)$.],
)

#fn-doc(
  "spline-normal",
  args: (("spline", "spline"), ("t", "float")),
  ret: "vector",
  [Computes oriented left unit normal vector $bold(N)(t) = (-T_y, T_x)$.],
)

#fn-doc(
  "spline-curvature",
  args: (("spline", "spline"), ("t", "float")),
  ret: "float",
  [Computes signed scalar curvature $kappa(t) = frac(x' y'' - y' x'', (x'^2 + y'^2)^(3/2))$.],
)

#fn-doc(
  "spline-normal-angle",
  args: (("spline", "spline"), ("t", "float")),
  ret: "angle",
  [Computes the direction angle of the unit normal vector $bold(N)(t)$ as a Typst `angle` (e.g. `90deg`, `-45deg`). Ideal for orienting perpendicular annotations, ticks, and CeTZ label anchors.],
)

#fn-doc(
  "spline-tangent-angle",
  args: (("spline", "spline"), ("t", "float")),
  ret: "angle",
  [Computes the direction angle of the unit tangent vector $bold(T)(t)$ as a Typst `angle`. Useful for vehicle heading, arrow alignment, and flow orientations.],
)

#fn-doc(
  "spline-label-anchor",
  args: (
    ("spline", "spline"),
    ("t", "float"),
    ("side", "int", 1),
  ),
  ret: "angle",
  [Computes the optimal CeTZ `content` anchor angle to position text cleanly along the curve normal without colliding with the stroke. If `side` is 1 (default), returns `spline-normal-angle + 180deg` (places text on the outer normal side). If `side` is -1, returns `spline-normal-angle` (places text on the inner side).],
)

== Arc Length & Inversion

#fn-doc(
  "spline-arc-length",
  args: (
    ("spline", "spline"),
    ("t1", "float", 0.0),
    ("t2", "float", 1.0),
  ),
  ret: "float",
  [Computes arc length between parameters $t_1$ and $t_2$ via 5-point Gauss-Legendre quadrature.],
)

#fn-doc(
  "spline-t-for-distance",
  args: (("spline", "spline"), ("distance", "float")),
  ret: "float",
  [Finds parameter $t in [0, 1]$ corresponding to physical distance along the curve using Newton-Raphson iteration.],
)

#fn-doc(
  "spline-point-at-distance",
  args: (("spline", "spline"), ("distance", "float")),
  ret: "point",
  [Evaluates point $C(s)$ at physical distance $s$ from curve start.],
)

== Geometric Operations

#fn-doc(
  "resample",
  args: (("spline", "spline"), ("count", "int")),
  ret: "array",
  [Resamples the curve into `count` points spaced uniformly by physical arc length.],
  parameters: (
    ("spline", "spline", [Target spline.]),
    ("count", "int", [Number of equidistant sample points ($>= 2$).]),
  )
)

```example
let sp = cs.spline-catmull(((0, 0), (1, 2), (3, 0), (4, 2)))
let pts = cs.resample(sp, 8)
spline(sp, stroke: 1pt + gray)
for p in pts { circle(p, radius: 0.1, fill: red) }
```

#fn-doc(
  "homotopy",
  args: (
    ("spline-a", "spline"),
    ("spline-b", "spline"),
    ("t", "float"),
    ("mode", "str", "auto"),
    ("samples", "int, auto", auto),
  ),
  ret: "spline",
  [Computes intermediate morphed spline under linear homotopy $(1-t) A + t B$.],
  parameters: (
    ("spline-a", "spline", [Base source spline ($t = 0$).]),
    ("spline-b", "spline", [Target destination spline ($t = 1$).]),
    ("t", "float", [Homotopy parameter in $[0, 1]$.]),
    ("mode", "str", [Interpolation strategy:
      - `"auto"` (default): uses `"segment"` if segment counts and closedness match; otherwise resamples by arc length.
      - `"segment"`: forces direct segment-by-segment Bézier control point interpolation.
      - `"arc-length"` (or `"length"`): forces uniform physical arc-length resampling before morphing, ensuring points at distance fraction $s$ morph directly to distance fraction $s$ on the target curve. Useful when segment lengths vary significantly between curves (e.g. $[0, 1, 8]$ to $[0, 7, 8]$) to prevent non-uniform stretching waves.]),
    ("samples", "int, auto", [Resample count when in `"arc-length"` mode (default: `auto`, picking $max(4 N_A, 4 N_B, 32)$).]),
  ),
)

#fn-doc(
  "offset",
  args: (
    ("spline", "spline"),
    ("distance", "float"),
    ("subdivide", "bool", true),
  ),
  ret: "spline",
  [Approximates the normal offset $C(u) + d dot bold(N)(u)$ using endpoint positions and curvature-scaled tangent handles. No approximation error bound or intersection removal is provided.],
  parameters: (
    ("spline", "spline", [Base curve.]),
    ("distance", "float", [Perpendicular offset distance (positive: left, negative: right).]),
    ("subdivide", "bool", [Whether to split segments with high curvature variation.]),
  )
)

```example
let sp = cs.spline-catmull(((0, 0), (2, 2), (4, 0)))
let left = cs.offset(sp, 0.4)
let right = cs.offset(sp, -0.4)

spline(left, stroke: 1.5pt + red)
spline(sp, stroke: 1pt + black)
spline(right, stroke: 1.5pt + blue)
```

#fn-doc(
  "rotate-spline",
  args: (
    ("spline", "spline"),
    ("angle", "angle, float"),
    ("origin", "point", (0.0, 0.0)),
  ),
  ret: "spline",
  [Rotates a spline rigidly by `angle` around an `origin` pivot point. Because Bézier curves are affine-invariant, all segment endpoints and control handles are transformed exactly without numerical approximation, preserving parameterization and arc lengths. Also aliased as `rotate`.],
  parameters: (
    ("spline", "spline", [Target spline dictionary.]),
    ("angle", "angle, float", [Rotation angle (e.g. `45deg`, `-90deg`, or radians as float).]),
    ("origin", "point", [Pivot point of rotation (default: `(0, 0)`).]),
  ),
)

```example
let sp = cs.spline-catmull(((0, 0), (1.5, 2), (3, 0.5), (4, 2)))
let piv = (1.5, 2)

spline(sp, stroke: 1.5pt + gray)
circle(piv, radius: 0.1, fill: orange)

for (i, a) in (30deg, 60deg, 90deg).enumerate() {
  let rot = cs.rotate-spline(sp, a, origin: piv)
  let clr = (blue, purple, red).at(i)
  spline(rot, stroke: 1.2pt + clr)
}
```

#fn-doc(
  "translate-spline",
  args: (
    ("spline", "spline"),
    ("offset", "point"),
  ),
  ret: "spline",
  [Translates a spline rigidly by a 2D delta vector `offset = (dx, dy)`. Preserves arc lengths and lookup tables. Also aliased as `translate`.],
  parameters: (
    ("spline", "spline", [Target spline dictionary.]),
    ("offset", "point", [Translation offset vector `(dx, dy)`.])
  ),
)

#fn-doc(
  "scale-spline",
  args: (
    ("spline", "spline"),
    ("factor", "float, array"),
    ("origin", "point", (0.0, 0.0)),
    ("dir", "any", none),
  ),
  ret: "spline",
  [Scales a spline relative to `origin`. Supports negative factors for reflections, as well as directional scaling along an arbitrary vector or angle `dir`. Resets the arc-length lookup table for automatic lazy rebuild. Also aliased as `scale`.],
  parameters: (
    ("spline", "spline", [Target spline dictionary.]),
    ("factor", "float, array", [Scale factor. If `dir` is `none`, a float scales uniformly, or `(sx, sy)` scales along axes. If `dir` is specified, a float scales along `dir`, or `(su, sv)` scales along `dir` and its normal.]),
    ("origin", "point", [Center point of scaling (default: `(0, 0)`).]),
    ("dir", "str, array, angle, none", [Optional direction vector `(dx, dy)`, angle (e.g. `45deg`), or `"x"` / `"y"`. Default: `none`.])
  ),
)

#fn-doc(
  "mirror-spline",
  args: (
    ("spline", "spline"),
    ("origin", "point", (0.0, 0.0)),
    ("axis", "any", "x"),
  ),
  ret: "spline",
  [Mirrors (reflects) a spline across a line passing through `origin` or performs point reflection. Also aliased as `mirror`.],
  parameters: (
    ("spline", "spline", [Target spline dictionary.]),
    ("origin", "point", [Point that the reflection axis/center passes through (default: `(0, 0)`).]),
    ("axis", "str, array, angle, none", [Reflection axis: `"x"` (horizontal line, flips $y$), `"y"` (vertical line, flips $x$), a direction vector `(dx, dy)`, an `angle` (e.g. `45deg`), or `none` for point reflection.]),
  ),
)

```example
let sp = cs.spline-catmull(((0.5, 0.5), (1.5, 2.5), (3, 1.5)))

spline(sp, stroke: 2pt + blue)

// Mirror across x-axis
let mir-x = cs.mirror-spline(sp, axis: "x")
spline(mir-x, stroke: 1.5pt + red)

// Directional scale along (1, 1) direction
let sc-dir = cs.scale-spline(sp, 1.6, origin: (0, 0), dir: (1, 1))
spline(sc-dir, stroke: (paint: purple, thickness: 1.2pt, dash: "dashed"))
```

== Canvas Drawing Functions

#fn-doc(
  "draw.spline",
  args: (
    ("spline-obj", "any"),
    ("name", "str", none),
    ("stroke", "stroke", auto),
    ("fill", "paint", auto),
    ("close", "bool", false),
    ("mark", "any", auto),
    ("..style", "any"),
  ),
  ret: "element",
  [CeTZ canvas drawing element. Accepts either a spline dictionary or an array of points. When a `name` is provided, automatically injects named anchors into CeTZ's coordinate resolution system.],
)

Styles are inherited from CeTZ with `auto` defaults. Pass `stroke`, `fill`, `fill-rule`, `mark`, or `shorten` as supported by CeTZ's merged paths. Use `none` to suppress stroke, fill, or marks explicitly. Stroke dictionaries support paint, thickness, dash, cap, and join. `draw-tangents`, `draw-normals`, and `draw-homotopy-field` forward extra named styles to their line elements; composite decorations expose separate styles for their parts.

`close: true` on an existing open spline adds a straight closing path for rendering. It does not change the spline dictionary, evaluations, or distance anchors. To interpolate a smooth loop, construct it with `closed: true`. Points are numeric 2D canvas coordinates; a third coordinate is discarded. Arbitrary CeTZ anchor coordinates cannot be used as constructor input.

=== Dynamic Named Anchors

When a spline element is assigned a `name` (e.g. `spline(sp, name: "my-curve")`), CeTZ intercepts the coordinate lookup and dynamically evaluates requested anchor queries on the fly without precomputed limits:

#table(
  columns: (1.5fr, 2.5fr),
  stroke: 0.5pt + rgb("#e2e8f0"),
  fill: (col, row) => if row == 0 { rgb("#f1f5f9") } else { none },
  align: (col, row) => if col == 0 { left } else { left },
  [#text(weight: "bold")[Anchor Pattern]], [#text(weight: "bold")[Description]],
  [`"start"`, `"end"`], [First and last endpoints of the spline.],
  [`"mid"`, `"default"`], [Midpoint evaluated at parameter $t = 0.5$ (`"default"` matches `"start"`).],
  [`"pt-0"`, `"pt-1"`, ...], [Original control points or segment boundary endpoints.],
  [`"t(<val>)"`], [Dynamic polynomial parameter space position $t in [0, 1]$ or percentage $X\%$ (e.g. `"t(0.42)"`, `"t(50%)"`, `"t(33.3%)"`).],
  [`"s(<val>)"`], [Dynamic physical arc length position via Gauss-Legendre quadrature (e.g. `"s(0.5)"`, `"s(68.5%)"`, `"s(100%)"`).],
  [`"<pct>%"`], [Shorthand percentage anchor (e.g. `"25%"`, `"50%"`).],
  [`"t-<val>"`, `"s-<val>"`], [Alternate dash syntax (e.g. `"t-50"`, `"t-0_5"`, `"s-75"`, `"s-0_75"`).],
)

```example
let sp = cs.spline-catmull(((0, 0), (1.5, 2.5), (3.5, 0.5), (5, 2)))
spline(sp, name: "c", stroke: 2pt + rgb("#1d3557"))

// Attach labels cleanly using curve normal angles
circle("c.start", radius: 0.12, fill: rgb("#0284c7"))
content("c.start", text(size: 7.5pt, weight: "bold", fill: rgb("#0284c7"))["start"], anchor: cs.spline-label-anchor(sp, 0.0), padding: 0.15)

circle("c.mid", radius: 0.12, fill: rgb("#7c3aed"))
content("c.mid", text(size: 7.5pt, weight: "bold", fill: rgb("#7c3aed"))["mid"], anchor: cs.spline-label-anchor(sp, 0.5), padding: 0.15)

circle("c.end", radius: 0.12, fill: rgb("#0284c7"))
content("c.end", text(size: 7.5pt, weight: "bold", fill: rgb("#0284c7"))["end"], anchor: cs.spline-label-anchor(sp, 1.0), padding: 0.15)

circle("c.pt-1", radius: 0.08, fill: orange)
circle("c.pt-2", radius: 0.08, fill: orange)
```

The practical guide compares equal parameter and equal distance steps visually. Use `.t(X%)` for a fraction of the global parameter and `.s(X%)` for a numerical distance fraction. When placing a label at a distance anchor, compute its normal using `spline-label-anchor-at-distance` at the same absolute distance.

#fn-doc(
  "draw.draw-tangents",
  args: (
    ("spline-obj", "any"),
    ("samples", "int", 10),
    ("scale", "float", 0.4),
    ("stroke", "stroke", 0.8pt + blue),
  ),
  ret: "element",
  [Draws directed unit tangent arrows along the curve.],
)

```example
let sp = cs.spline-catmull(((0, 0), (2, 2), (4, 0)))
spline(sp, stroke: 1.5pt + black)
draw-tangents(sp, samples: 6, scale: 1.2, stroke: 1pt + blue)
```

#fn-doc(
  "draw.draw-normals",
  args: (
    ("spline-obj", "any"),
    ("samples", "int", 10),
    ("scale", "float", 0.4),
    ("stroke", "stroke", 0.8pt + red),
  ),
  ret: "element",
  [Draws perpendicular oriented left normal vectors along the curve.],
)

```example
let sp = cs.spline-catmull(((0, 0), (2, 2), (4, 0)))
spline(sp, stroke: 1.5pt + black)
draw-normals(sp, samples: 6, scale: 0.7, stroke: 1pt + red)
```

#fn-doc(
  "draw.draw-curvature-comb",
  args: (
    ("spline-obj", "any"),
    ("samples", "int", 40),
    ("scale", "float", 0.5),
    ("stroke", "stroke", 0.5pt + gray),
    ("envelope-stroke", "stroke", 0.8pt + blue),
  ),
  ret: "element",
  [Renders CAD-style curvature needles $kappa(s) dot bold(N)(s)$ connected by an envelope curve.],
)

```example
let sp = cs.spline-catmull(((0, 0), (1.5, 2.5), (3.5, 0.5), (5, 2)))
draw-curvature-comb(sp, samples: 35, scale: 0.5, stroke: 0.4pt + gray, envelope-stroke: 1pt + red)
spline(sp, stroke: 2pt + black)
```

#fn-doc(
  "draw.draw-homotopy",
  args: (
    ("spline-a", "spline"),
    ("spline-b", "spline"),
    ("steps", "int", 5),
    ("stroke-fn", "function", none),
    ("mode", "str", "auto"),
    ("samples", "int, auto", auto),
  ),
  ret: "element",
  [Draws a family of intermediate curves under homotopy deformation. Supports `mode: "auto"`, `"segment"`, or `"arc-length"` to control whether curves are morphed by Bézier control handles or physical arc length.],
)

#fn-doc(
  "draw.draw-homotopy-field",
  args: (
    ("spline-a", "spline"),
    ("spline-b", "spline"),
    ("samples", "int", 8),
    ("stroke", "stroke", 0.8pt + blue),
    ("mark", "dictionary", (end: ">")),
    ("mode", "str", "arc-length"),
  ),
  ret: "element",
  [Draws directed deformation vector field arrows connecting curve A to curve B. Supports `mode: "arc-length"` (default: arrows distributed at equal physical curve distances) or `"segment"` (arrows distributed in parameter space).],
)

== Control Handles and Low-Level Helpers

`cs.draw.draw-control-polygon(sp, stroke: (paint: luma(160), thickness: 0.6pt, dash: "dashed"), pt-radius: 0.05, pt-fill: luma(120))` draws each cubic's endpoint handles and the original input polygon. For B-splines, the original polygon is not the same as the extracted cubic handles.

```example-vertical
let sp = cs.spline-bspline(((0, 0), (1, 2), (3, 2), (4, 0)))
draw-control-polygon(sp, pt-radius: 0.06, pt-fill: orange)
spline(sp, stroke: 1.5pt + blue)
```

#pagebreak()
=== Low-Level Reference

These helpers support custom algorithms. All names are exported under `cs`. In the signatures below, `sp` is a spline, `ks` a knot vector, and `d` an absolute distance. Single-cubic evaluators share the arguments `(s, e, c1, c2, u)`, abbreviated as `..args` in these reference cards. `..options` denotes the named options described in the card.

#let helper-card(title, signatures, description) = (height: auto) => block(
  breakable: false,
  width: 100%,
  height: height,
  inset: 9pt,
  radius: 3pt,
  stroke: 0.5pt + luma(200),
  fill: rgb("#fafbfd"),
)[
  #text(font: "Liberation Sans", size: 9pt, weight: "bold", fill: rgb("#1a4971"))[#title]
  #v(4pt)
  #show raw: set text(font: "Liberation Mono", size: 7.4pt)
  #raw(signatures, block: true)
  #v(4pt)
  #text(size: 8.6pt)[#description]
]

// Measure at the actual column width, then give both cards in each row
// the taller card's height. Relative heights cannot size an auto grid row.
#let helper-grid(..cards) = layout(size => {
  let gutter = 10pt
  let card-width = (size.width - gutter) / 2
  let cells = ()
  for row in cards.pos().chunks(2) {
    let height = calc.max(..row.map(card => measure(card(), width: card-width).height))
    cells += row.map(card => card(height: height))
  }
  grid(columns: (1fr, 1fr), gutter: gutter, ..cells)
})

#helper-grid(
  helper-card("Spline records", "make-spline(..fields)\nis-spline(value)\nassert-spline(value, name: \"spline\")", [Construct a record, test its package marker, or assert that marker. Field defaults are listed in the mathematical notes. Custom geometry is the caller's responsibility.]),
  helper-card("Coordinates and segments", "clean-point(pt)\nclean-points(pts)\nsegment-count(sp)\nget-segment(sp, idx)", [Convert numeric points to 2D floating-point tuples, count segments, or retrieve a zero-based segment. Extra coordinates are discarded.]),
  helper-card("Cubic position and derivatives", "cubic-point(..args)\ncubic-derivative(..args)\ncubic-second-derivative(..args)\ncubic-split(..args)\nsubdivide-segment(seg, count)", [Use the five shared cubic arguments above. The first three evaluate position, velocity, and acceleration. Splitting returns two cubic tuples meeting at `u`. `subdivide-segment` takes a cubic tuple and a positive integer count; it returns equal-parameter pieces of the same curve, not equal-distance pieces.]),
  helper-card("Cubic tangent, normal, and curvature", "cubic-tangent(..args)\ncubic-normal(..args)\ncubic-curvature(..args)\ncubic-tangent-angle(..args)\ncubic-normal-angle(..args)", [Use the same five arguments. Return a unit tangent, oriented left normal, signed curvature, or the corresponding Typst angle.]),
  helper-card("Arc length and cached tables", "segment-arc-length(s, e, c1, c2,\n  u1: 0, u2: 1)\nbuild-arc-length-lut(sp, ..options)\nensure-lut(sp, ..options)\nwith-lut(sp, ..options)", [Segment length is numerical and signed for reversed limits. Table helpers accept `samples-per-segment: 10`, a positive integer. They build a table, retrieve or build one, or attach it to a copy.]),
  helper-card("Frames at an absolute distance", "spline-normal-at-distance(sp, d)\nspline-tangent-at-distance(sp, d)\nspline-tangent-angle-at-distance(sp, d)", [Evaluate the left normal, unit tangent, or tangent angle at distance `d`. Distance clamps to the curve's range. Normal and label angles are documented with the analytical API.]),
  helper-card("Knot-domain tools", "generate-clamped-knots(n, p)\ngenerate-periodic-knots(n, p)\ncox-de-boor(u, p, ks, pts)\ncox-de-boor-derivative(u, p, ks, pts)", [Generate knots for `n` original points and degree `p`, or evaluate in the original knot domain. Periodic evaluation repeats the first `p` control points.]),
  helper-card("Cubic extraction", "catmull-to-bezier-segments(pts,\n  ..constructor-options)\nbspline-to-bezier-segments(pts,\n  ..constructor-options)", [Accept the corresponding constructor's options and return the cubic tuple array instead of a spline record. Higher-degree B-splines retain the documented approximation limits.]),
)

#pagebreak()
= Examples Gallery

== Opening a Seam with Fixed Outer Arcs

Blue dots mark the cuts. The source arcs outside them stay unchanged. A curvature-matched bridge replaces the detour between them. Place cuts away from sharp peaks, otherwise the bridge inherits their tight curvature.

Gray shows the two-lobed source; purple shows the morph into a single loop. Black marks the shared base point. Only the final bridge is guaranteed to be $G^2$.

```example-vertical
let pts = (
  (0, -0.7), (0.9, -0.5), (1.1, 0.5), (0.8, 1.05), (0.2, 0.2),
  (0, -0.7),
  (-0.2, 0.2), (-0.8, 1.25), (-1.1, 0.5), (-0.6, -0.3), (0, -0.7),
)
let source = cs.spline-catmull(pts)
// Cut inside the shoulders, before the high-curvature peaks.
let (left, cut-left) = cs.cubic-split(..source.segments.at(2), 0.7)
let (cut-right, right) = cs.cubic-split(..source.segments.at(7), 0.2)
let prefix = (..source.segments.slice(0, 2), left)
let suffix = (right, ..source.segments.slice(8))
let bridge = cs.spline-transition(left.at(1), right.at(0),
  start-tangent: cs.cubic-tangent(..left, 1),
  end-tangent: cs.cubic-tangent(..right, 0),
  start-curvature: cs.cubic-curvature(..left, 1),
  end-curvature: cs.cubic-curvature(..right, 0))
// Six removed pieces correspond to six pieces of the bridge.
let removed = (cut-left, ..source.segments.slice(3, 7), cut-right)
let refined = bridge.segments.map(s => cs.subdivide-segment(s, 2)).join()
let a = cs.make-spline(segments: (..prefix, ..removed, ..suffix))
let b = cs.make-spline(segments: (..prefix, ..refined, ..suffix))
for (i, t) in (0, 0.25, 0.5, 0.75, 1).enumerate() {
  scope({
    translate((i * 2.6, 0))
    content((0, 1.65), [t = #t])
    spline(source, stroke: 0.4pt + luma(210))
    spline(cs.homotopy(a, b, t, mode: "segment"),
    stroke: 1pt + rgb("#92215e"))
    circle(pts.first(), radius: 0.065, fill: black, stroke: none)
    circle(left.at(1), radius: 0.055, fill: blue, stroke: none)
    circle(right.at(0), radius: 0.055, fill: blue, stroke: none)
  })
}
```

#pagebreak()
== Aerodynamic Airfoil Profile & Curvature Comb

An illustrative airfoil outline, rather than a physical flow model. The comb shows where geometric curvature changes abruptly or becomes large; it does not calculate pressure or aerodynamic acceleration. Try reducing `scale` if the needles obscure the profile.

```example-vertical
let upper-pts = ((0, 0), (0.35, 0.65), (1.2, 0.88), (2.8, 0.68), (4.5, 0.22), (5.5, 0))
let lower-pts = ((0, 0), (0.5, -0.35), (1.8, -0.38), (3.4, -0.22), (5.5, 0))

let upper = cs.spline-catmull(upper-pts, alpha: 0.5)
let lower = cs.spline-catmull(lower-pts, alpha: 0.5)

// Curvature comb on suction surface
draw-curvature-comb(
  upper,
  samples: 45,
  scale: 0.6,
  stroke: 0.4pt + luma(180),
  envelope-stroke: 1.2pt + rgb("#ef4444"),
  fill: rgb("#ef444415"),
)

// Airfoil body
spline(upper, name: "suction", stroke: 2pt + rgb("#0f172a"))
spline(lower, name: "pressure", stroke: 2pt + rgb("#0f172a"))

// Chord reference line
line("suction.start", "suction.end", stroke: (paint: gray, thickness: 0.6pt, dash: "dashed"))

// Annotations
circle("suction.start", radius: 0.08, fill: rgb("#0284c7"))
content("suction.start", text(size: 7pt, weight: "bold")[Leading Edge], anchor: "north-east", padding: 0.15)

circle("suction.end", radius: 0.08, fill: rgb("#0284c7"))
content("suction.end", text(size: 7pt, weight: "bold")[Trailing Edge], anchor: "north-west", padding: 0.15)
```

#pagebreak()
== High-Speed Racetrack Corner & Banking Lanes

Generating a racing line chicane with parallel track boundaries and curbs using `cs.offset`. Braking, apex, and acceleration points are positioned at numerical arc-length distances using `"s(X%)"` anchors.

```example-vertical
let track-pts = ((-4, -1.5), (-1.5, 1.4), (1, -1.0), (3.5, 1.6), (6.5, 0.2))
let racing-line = cs.spline-catmull(track-pts, alpha: 0.5)

// Track borders via parallel offset
let outer-kerb = cs.offset(racing-line, 0.9)
let inner-kerb = cs.offset(racing-line, -0.9)
let left-lane = cs.offset(racing-line, 0.45)
let right-lane = cs.offset(racing-line, -0.45)

spline(outer-kerb, stroke: 1.8pt + rgb("#334155"))
spline(left-lane, stroke: (paint: rgb("#cbd5e1"), thickness: 0.8pt, dash: "dashed"))
spline(racing-line, name: "race", stroke: 2.2pt + rgb("#e63946"))
spline(right-lane, stroke: (paint: rgb("#cbd5e1"), thickness: 0.8pt, dash: "dashed"))
spline(inner-kerb, stroke: 1.8pt + rgb("#334155"))

// Tangent vectors showing vehicle heading
draw-tangents(racing-line, samples: 7, scale: 0.7, stroke: 1.2pt + rgb("#0284c7"))

// Arc-length key positions oriented along curve normals
circle("race.s(20%)", radius: 0.1, fill: rgb("#f59e0b"))
content("race.s(20%)", text(size: 6.5pt, weight: "bold", fill: rgb("#b45309"))[Braking Zone (s = 20%)], anchor: cs.spline-label-anchor-at-distance(racing-line, cs.spline-arc-length(racing-line) * 0.2), padding: 0.12)

circle("race.s(50%)", radius: 0.12, fill: rgb("#10b981"))
content("race.s(50%)", text(size: 7pt, weight: "bold", fill: rgb("#047857"))[Corner Apex (s = 50%)], anchor: cs.spline-label-anchor-at-distance(racing-line, cs.spline-arc-length(racing-line) * 0.5, side: -1), padding: 0.15)

circle("race.s(80%)", radius: 0.1, fill: rgb("#3b82f6"))
content("race.s(80%)", text(size: 6.5pt, weight: "bold", fill: rgb("#1d4ed8"))[Exit Throttle (s = 80%)], anchor: cs.spline-label-anchor-at-distance(racing-line, cs.spline-arc-length(racing-line) * 0.8), padding: 0.12)
```

#pagebreak()
== Mechanical Cam Profile & Roller Follower

A closed $C^2$ cam profile evaluated with `draw-curvature-comb`. The needle spikes $kappa(s) dot bold(N)(s)$ and envelope verify acceleration smoothness, while a roller follower is positioned along the normal contact point.

```example-vertical
let pts = (
  (0, 1.6), (1.8, 2.9), (3.2, 1.2), (2.5, -1.5),
  (0, -2.2), (-2.5, -1.5), (-3.2, 1.2), (-1.8, 2.9),
)
let cam = cs.spline-catmull(pts, alpha: 0.5, closed: true)

// Curvature comb
draw-curvature-comb(
  cam,
  samples: 60,
  scale: 0.8,
  stroke: 0.4pt + luma(170),
  envelope-stroke: 1.2pt + rgb("#ef4444"),
  fill: rgb("#ef444412"),
)

// Cam body & base circle
spline(cam, name: "cam-body", stroke: 2pt + rgb("#0f172a"), fill: rgb("#f8fafc"))
circle((0, 0), radius: 0.1, fill: black)
circle((0, 0), radius: 0.6, stroke: (paint: gray, thickness: 0.7pt, dash: "dashed"))

// Roller follower at peak displacement (s = 15%)
let follower-contact = "cam-body.s(15%)"
circle(follower-contact, radius: 0.08, fill: rgb("#0284c7"))
line((0, 0), follower-contact, stroke: 0.6pt + rgb("#94a3b8"))
content(follower-contact, text(size: 7pt, weight: "bold", fill: rgb("#0284c7"))[Follower Contact], anchor: cs.spline-label-anchor-at-distance(cam, cs.spline-arc-length(cam) * 0.15), padding: 0.15)
```

#pagebreak()
== Shape Morphing (Homotopy Family & Flow Field)

Continuous linear homotopy $(1-t) A + t B$ morphing between an elliptical teardrop profile and an undulating 4-lobed profile. The arrows connect corresponding sample positions and show displacement; they do not represent a physical flow or flux.

```example-vertical
let circle-pts = ((0, 2), (2, 0), (0, -2), (-2, 0))
let lobe-pts = ((0, 2.5), (0.8, 0.8), (2.5, 0), (0.8, -0.8), (0, -2.5), (-0.8, -0.8), (-2.5, 0), (-0.8, 0.8))

let base-shape = cs.spline-catmull(circle-pts, closed: true)
let target-shape = cs.spline-catmull(lobe-pts, closed: true)

// Deformation arrows and intermediate morph family
draw-homotopy-field(base-shape, target-shape, samples: 16, stroke: 0.6pt + rgb("#94a3b8"))
draw-homotopy(
  base-shape,
  target-shape,
  steps: 4,
  stroke-fn: (t) => 0.9pt + rgb(int(15 + t * 200), int(120 - t * 60), int(180 - t * 100)),
)

spline(base-shape, stroke: 2pt + rgb("#0284c7"))
spline(target-shape, stroke: 2pt + rgb("#ef4444"))
```

#pagebreak()
== Knot Exponent Comparison ($alpha$)

Comparison of uniform ($alpha = 0.0$), centripetal ($alpha = 0.5$), and chordal ($alpha = 1.0$) Catmull-Rom parameterization over unevenly spaced control points. Compare the different bulges around the closely spaced points. Centripetal parameterization avoids within-segment cusps for distinct consecutive points; a uniform curve need not exhibit a cusp for every input.

```example-vertical
let pts = ((-3.5, 0), (-1.2, 3), (-0.8, 0.2), (0.8, 0.2), (1.2, 3), (3.5, 0))
let sp-uni = cs.spline-catmull(pts, alpha: 0.0)
let sp-cent = cs.spline-catmull(pts, alpha: 0.5)
let sp-chord = cs.spline-catmull(pts, alpha: 1.0)

spline(sp-uni, stroke: 1.5pt + rgb("#ef4444"))
spline(sp-cent, stroke: 2.2pt + rgb("#0f172a"))
spline(sp-chord, stroke: 1.5pt + rgb("#059669"))

for p in pts { circle(p, radius: 0.08, fill: black) }

// Legend
rect((0.2, -0.7), (4.8, -1.9), stroke: 0.5pt + gray, fill: rgb("#fffffffa"), radius: 3pt)
line((0.4, -0.9), (1.1, -0.9), stroke: 1.5pt + rgb("#ef4444"))
content((1.3, -0.9), anchor: "west", text(size: 7.5pt)[Uniform (alpha = 0.0)])
line((0.4, -1.3), (1.1, -1.3), stroke: 2.2pt + rgb("#0f172a"))
content((1.3, -1.3), anchor: "west", text(size: 7.5pt)[Centripetal (alpha = 0.5)])
line((0.4, -1.7), (1.1, -1.7), stroke: 1.5pt + rgb("#059669"))
content((1.3, -1.7), anchor: "west", text(size: 7.5pt)[Chordal (alpha = 1.0) - Smooth])
```

#pagebreak()
== Turbomachinery Rotor Symmetry via Rotational Transforms

A single master blade profile rotated symmetrically around a central hub using `cs.rotate-spline`. Because Bézier control handles transform rigidly under affine transformations, symmetry and arc lengths are preserved exactly.

```example-vertical
let blade-pts = ((0.6, 0.1), (1.3, 0.8), (2.4, 0.7), (3.2, 0.1))
let blade = cs.spline-catmull(blade-pts, alpha: 0.5)

// Central hub
circle((0, 0), radius: 0.6, stroke: 1.5pt + rgb("#0f172a"), fill: rgb("#f1f5f9"))
circle((0, 0), radius: 0.15, fill: rgb("#0f172a"))

// 6-blade rotor cascade
for i in range(6) {
  let rot-blade = cs.rotate-spline(blade, i * 60deg, origin: (0, 0))
  let clr = rgb(int(20 + i * 35), 80, int(180 - i * 20))
  spline(rot-blade, stroke: 1.8pt + clr)
}
```

#pagebreak()
= Mathematical Notes

== Spline Data Representation

Every curve in `cetz-spline` is represented by an immutable dictionary:

```typst
#let make-spline(
  type: "catmull-rom",       // "catmull-rom" | "bspline" | "homotopy" | "offset"
  pts: (),                   // Array of original input points
  closed: false,             // bool
  meta: (:),                 // Spline parameters (alpha, degree, knots, etc.)
  segments: (),              // Array of native CeTZ cubic Bézier segments ((s, e, c1, c2), ...)
  lut: none,                 // Cached arc-length lookup table
)
```

Each segment inside `segments` follows CeTZ's standard Bézier tuple:
$ (bold(s), bold(e), bold(c)_1, bold(c)_2) $
where $bold(s)$ is the starting point, $bold(e)$ is the end point, and $bold(c)_1, bold(c)_2$ are control handles.

== Centripetal Catmull-Rom Parameterization

For four consecutive interpolation points $bold(P)_0, bold(P)_1, bold(P)_2, bold(P)_3$, knot intervals are computed as:
$ t_0 = 0, quad t_(i+1) = t_i + ||bold(P)_(i+1) - bold(P)_i||^alpha $
where:
- $alpha = 0.0$: Uniform Catmull-Rom. Susceptible to self-intersections and cusps when distance between adjacent points varies significantly.
- $alpha = 0.5$: Centripetal Catmull-Rom (default). Proven by Yuksel et al. (2011) to be cusp-free and self-intersection-free within segments.
- $alpha = 1.0$: Chordal Catmull-Rom. Knots are proportional to Euclidean chord length.

The Bézier control points between $bold(P)_1$ and $bold(P)_2$ are obtained by evaluating the endpoint derivatives:
$ bold(B)_0 = bold(P)_1 $
$ bold(B)_1 = bold(P)_1 + frac(t_2 - t_1, 3) [ frac(t_2 - t_1, t_2 - t_0) frac(bold(P)_1 - bold(P)_0, t_1 - t_0) + frac(t_1 - t_0, t_2 - t_0) frac(bold(P)_2 - bold(P)_1, t_2 - t_1) ] $
$ bold(B)_2 = bold(P)_2 - frac(t_2 - t_1, 3) [ frac(t_3 - t_2, t_3 - t_1) frac(bold(P)_2 - bold(P)_1, t_2 - t_1) + frac(t_2 - t_1, t_3 - t_1) frac(bold(P)_3 - bold(P)_2, t_3 - t_2) ] $
$ bold(B)_3 = bold(P)_2 $

== Curvature and Normal Vectors

The unit tangent vector is $bold(T)(u) = frac(C'(u), ||C'(u)||)$. The oriented left unit normal vector $bold(N)(u)$ points 90 degrees counter-clockwise from $bold(T)(u)$:
$ bold(N)(u) = (-T_y(u), T_x(u)) $

Signed scalar curvature $kappa(u)$ is:
$ kappa(u) = frac(x'(u) y''(u) - y'(u) x''(u), (x'(u)^2 + y'(u)^2)^(3/2)) $
Curvature is positive when the curve bends to the left (counter-clockwise) and negative when bending to the right (clockwise).

== Arc-Length Quadrature and Inversion

Curve speed $||C'(t)||$ varies along polynomial splines. Arc length between parameters $a$ and $b$ is evaluated using 5-point Gauss-Legendre quadrature:
$ integral_a^b ||C'(u)|| d u approx frac(b - a, 2) sum_(i=1)^5 w_i ||C'(frac(a+b, 2) + frac(b-a, 2) x_i)|| $

with weights and abscissae:
$ x_1 = 0, quad w_1 = frac(128, 225) approx 0.568889 $
$ x_(2,3) = plus.minus sqrt(frac(5 - 2 sqrt(10/7), 9)) approx plus.minus 0.538469, quad w_(2,3) = frac(322 + 13 sqrt(70), 900) approx 0.478629 $
$ x_(4,5) = plus.minus sqrt(frac(5 + 2 sqrt(10/7), 9)) approx plus.minus 0.906180, quad w_(4,5) = frac(322 - 13 sqrt(70), 900) approx 0.236927 $

The implementation adaptively compares each interval with two half intervals, up to a bounded refinement depth. These are numerical estimates, not exact lengths or certified error bounds. Cached lookup tables avoid repeated work when explicitly attached with `cs.with-lut(sp)`.

To map physical distance $s$ back to parameter $t$, a bracketed Newton iteration is performed, with bisection when the Newton step leaves the bracket:
$ u_(k+1) = u_k - frac(s(u_k) - s_("target"), ||C'(u_k)||) $


== Parameterization and Continuity

Global $t$ assigns equal parameter intervals to the stored cubic segments. It does not preserve the original nonuniform B-spline knot parameter or the Catmull–Rom knot times. Position is continuous at joins, but derivatives with respect to global $t$ can jump. For nonuniform Catmull–Rom splines, tangent direction is continuous at regular joins; tangent magnitude need not be. Curvature and second derivatives can also jump. At a join, evaluation uses the segment on the right, except at $t = 1$.

The left normal is defined by orientation, even at inflections; it is not the principal oriented left normal, which changes sign with curvature. At a stationary point the mathematical tangent and curvature may be undefined. The implementation tries a nearby derivative for the tangent, then uses $(1, 0)$ as a fallback; curvature returns zero below its speed threshold. Treat those values as drawing conventions.

== Approximation Limits

B-splines of degree one through three convert to cubic segments exactly up to floating-point rounding. Higher degrees use piecewise cubic Hermite approximation with `degree - 2` pieces per knot span; no error tolerance is currently exposed. Custom interior knot multiplicity may not exceed the effective degree: discontinuous curves are rejected.

`cs.offset` approximates a normal offset by matching endpoint positions and scaled tangent handles. A single split may improve a segment with differing endpoint curvatures, but does not guarantee an error bound, remove intersections, or construct joins at corners. At distances near a curvature radius, the true offset can develop singularities. Use modest distances and inspect the result.

The centripetal guarantee concerns individual regular segments with distinct consecutive points, not global intersections between different segments. Repeated points are handled numerically, but are outside that guarantee. See #link("https://www.cemyuksel.com/research/catmullrom_param/catmullrom.pdf")[Yuksel, Schaefer, and Keyser, _On the Parameterization of Catmull–Rom Curves_] for the precise result.

#pagebreak()
== Endpoint Constraints and Geometric Continuity

For a cubic Hermite segment, prescribed positions $bold(P)_0$, $bold(P)_1$ and derivatives $bold(v)_0$, $bold(v)_1$ determine its poles:
$ bold(B)_0 = bold(P)_0, quad bold(B)_1 = bold(P)_0 + bold(v)_0 / 3, quad bold(B)_2 = bold(P)_1 - bold(v)_1 / 3, quad bold(B)_3 = bold(P)_1. $
After these constraints are fixed, its endpoint curvatures are consequences of the geometry, not independent parameters.

For `spline-transition`, unit tangent $bold(T)$, speed $v$, and signed curvature $kappa$ specify the endpoint acceleration $bold(a) = kappa v^2 bold(N)$, with zero tangential component. The start and end position, velocity, and acceleration form six scalar constraints per coordinate. Three equal-duration cubic spans have just enough freedom to meet those constraints while matching position, velocity, and acceleration at their two internal joins.

The implementation uses constant jerk vectors $bold(j)_0$, $bold(j)_1$, $bold(j)_2$ on intervals of duration $h = 1/3$. Define endpoint residuals:
$ bold(A) = 3 (bold(a)_1 - bold(a)_0), $
$ bold(V) = 18 (bold(v)_1 - bold(v)_0 - bold(a)_0), $
$ bold(P) = 162 (bold(P)_1 - bold(P)_0 - bold(v)_0 - bold(a)_0 / 2). $
Integrating the three spans gives the linear system:
$ bold(j)_0 + bold(j)_1 + bold(j)_2 = bold(A), $
$ 5 bold(j)_0 + 3 bold(j)_1 + bold(j)_2 = bold(V), $
$ 19 bold(j)_0 + 7 bold(j)_1 + bold(j)_2 = bold(P). $
Solving this system and integrating each constant jerk yields the stored cubic segments. There is no higher-degree-to-cubic approximation in this constructor.

For regular planar curves with consistent traversal, $G^0$ means matching positions, $G^1$ adds matching unit tangents, and $G^2$ adds matching signed curvature. Parametric $C^1$ additionally requires equal derivative magnitudes; $C^2$ requires the full acceleration vectors to match. Matching curvature alone does not match its rate of change and does not imply $G^3$. The #link("https://engineeringtechnology.org/engineering-graphics/cad-siemens-nx/nx-surface-modeling/surface-continuity-g0-g1-g2-etc/")[NX continuity illustrations] offer a visual comparison of these geometric conditions; the constructions here apply to planar curves.
