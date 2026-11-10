// manual.typ
// Reference Manual for cetz-spline
// Follows the official CeTZ documentation architecture

#import "@preview/cetz:0.5.3"
#import "src/lib.typ" as cs

#set document(
  title: "cetz-spline Manual",
  author: "Typst Community Contributor",
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
    [#text(weight: "bold")[Compiler:] #sym.gt.eq 0.11.0],
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

- *Centripetal and Chordal Catmull-Rom Parameterization* ($alpha = 0.5, 1.0$): CeTZ only implements uniform Catmull-Rom ($alpha = 0$), which produces self-intersections and loops around sharp corners. Centripetal parameterization mathematically prevents cusps and local self-intersections.
- *Second Derivatives and Curvature Fields*: Continuous acceleration vectors $C''(u)$, Frenet unit normal fields $bold(N)(u)$, and signed scalar curvature $kappa(u)$.
- *Arbitrary-Degree B-Splines*: Cox-de Boor recursion with exact conversion to cubic Bézier segments for clamped and periodic knot vectors.
- *High-Precision Arc Length*: 5-point Gauss-Legendre numerical quadrature with Newton-Raphson distance inversion ($s |-> t$).
- *Parallel Offset Curves*: Normal-offset curves $C(u) + d dot bold(N)(u)$ with curvature-scaled tangent matching.
- *Homotopies and Deformation Vector Fields*: Morphing families $(1-t) A + t B$ and directional deformation vectors connecting curves at equal arc-length fractions.
- *CAD-Style Geometric Visualizers*: Curvature needles and envelope curves, velocity vectors, normal fields, and control polygons.

== CeTZ Integration Audit

The following table summarizes the boundary between CeTZ core and `cetz-spline`:

#table(
  columns: (auto, auto, auto, 1fr),
  stroke: (x, y) => if y == 0 { (bottom: 1pt + black) } else { (bottom: 0.3pt + luma(200)) },
  fill: (x, y) => if y == 0 { rgb("#f5f5f5") } else { none },
  inset: (x: 6pt, y: 4.5pt),
  [#strong[Capability]], [#strong[Origin]], [#strong[Location]], [#strong[Description]],
  [Vector math], [CeTZ], [`cetz.vector`], [Vector addition, subtraction, scaling, length, dot product.],
  [Bézier point evaluation], [CeTZ], [`cetz.util.bezier.cubic-point`], [Evaluates $C(u)$ at parameter $u in [0, 1]$.],
  [Velocity vector], [CeTZ], [`cetz.util.bezier.cubic-derivative`], [Evaluates $C'(u) = frac(d C, d u)$.],
  [Curve subdivision], [CeTZ], [`cetz.util.bezier.split`], [De Casteljau subdivision at parameter $u$.],
  [*Second derivative*], [*cetz-spline*], [`cs.cubic-second-derivative`], [Acceleration vector $C''(u) = frac(d^2 C, d u^2)$.],
  [*Curvature $kappa(u)$*], [*cetz-spline*], [`cs.cubic-curvature`], [Signed scalar curvature $frac(x' y'' - y' x'', (x'^2 + y'^2)^(3/2))$.],
  [*Frenet normal $bold(N)(u)$*], [*cetz-spline*], [`cs.cubic-normal`], [Unit normal vector field $(-T_y, T_x)$.],
  [*Centripetal Catmull-Rom*], [*cetz-spline*], [`cs.spline-catmull`], [Yuksel (2011) $alpha = 0.5$ knot allocation; prevents cusps.],
  [*Arbitrary B-Splines*], [*cetz-spline*], [`cs.spline-bspline`], [Cox-de Boor recursion with exact Bézier decomposition.],
  [*Arc-length quadrature*], [*cetz-spline*], [`cs.spline-arc-length`], [5-point Gauss-Legendre quadrature for exact curve length.],
  [*Arc-length inversion*], [*cetz-spline*], [`cs.spline-t-for-distance`], [Newton-Raphson solver for physical distance $s |-> t$.],
  [*Parallel offset curves*], [*cetz-spline*], [`cs.offset`], [Parallel normal offset with curvature-matched velocity.],
  [*Affine transforms*], [*cetz-spline*], [`cs.rotate-spline`], [Rotation, translation, directional scaling, and mirroring/reflections.],
  [*Homotopy morphing*], [*cetz-spline*], [`cs.homotopy`], [Topological loop deformation and intermediate families.],
  [*Curvature combs*], [*cetz-spline*], [`cs.draw.draw-curvature-comb`], [CAD-style curvature needles with envelope spline.],
)

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
circle("c.mid", radius: 0.15, fill: orange)
circle("c.end", radius: 0.12, fill: black)
```

== Named Anchors

When `name: "..."` is passed to `cs.draw.spline`, the following named anchors are injected:
- `"start"`, `"end"`: curve extremities
- `"mid"`: midpoint at global parameter $t = 0.5$
- `"pt-<idx>"`: original control points (`"pt-0"`, `"pt-1"`, ...)
- `"t(X%)"`: position at parameter ratio (e.g. `"t(25%)"`, `"t(50%)"`, `"t(75%)"`)
- `"s(X%)"`: position at exact physical arc-length ratio (e.g. `"s(50%)"`)
- `"50%"`, `"25%"`, `"75%"`: standard CeTZ path percentage anchors

= Mathematical Concepts

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

The unit tangent vector is $bold(T)(u) = frac(C'(u), ||C'(u)||)$. The Frenet unit normal vector $bold(N)(u)$ points 90 degrees counter-clockwise from $bold(T)(u)$:
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

To map physical distance $s$ back to parameter $t$, Newton-Raphson iteration is performed:
$ u_(k+1) = u_k - frac(s(u_k) - s_("target"), ||C'(u_k)||) $

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
    ("boundary", "str", [Boundary condition for open curves: `"clamped"` (virtual ghost points) or `"natural"`.]),
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
  [Constructs a B-spline of arbitrary degree via Cox-de Boor recursion, decomposed into cubic Bézier segments.],
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
  [Computes Frenet unit normal vector $bold(N)(t) = (-T_y, T_x)$.],
)

#fn-doc(
  "spline-curvature",
  args: (("spline", "spline"), ("t", "float")),
  ret: "float",
  [Computes signed scalar curvature $kappa(t) = frac(x' y'' - y' x'', (x'^2 + y'^2)^(3/2))$.],
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
  args: (("spline-a", "spline"), ("spline-b", "spline"), ("t", "float")),
  ret: "spline",
  [Computes intermediate morphed spline under linear homotopy $(1-t) A + t B$. When segment counts differ, both curves are automatically resampled by arc length.],
)

#fn-doc(
  "offset",
  args: (
    ("spline", "spline"),
    ("distance", "float"),
    ("subdivide", "bool", true),
  ),
  ret: "spline",
  [Computes a parallel offset curve displaced along the normal field $C(u) + d dot bold(N)(u)$ with curvature-matched velocity.],
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
    ("stroke", "stroke", 1pt + black),
    ("fill", "paint", none),
    ("close", "bool", false),
  ),
  ret: "element",
  [CeTZ canvas drawing element. Accepts either a spline dictionary or an array of points. Registers named anchors for CeTZ coordinate lookups.],
)

#fn-doc(
  "draw.draw-tangents",
  args: (
    ("spline-obj", "any"),
    ("samples", "int", 10),
    ("scale", "float", 0.4),
    ("stroke", "stroke", 0.8pt + blue),
  ),
  ret: "element",
  [Draws directed velocity / tangent arrows along the curve.],
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
  [Draws perpendicular Frenet normal vectors along the curve.],
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
  ),
  ret: "element",
  [Draws a family of intermediate curves under homotopy deformation.],
)

#fn-doc(
  "draw.draw-homotopy-field",
  args: (
    ("spline-a", "spline"),
    ("spline-b", "spline"),
    ("samples", "int", 8),
    ("stroke", "stroke", 0.8pt + blue),
  ),
  ret: "element",
  [Draws directed deformation vector field arrows connecting curve A to curve B.],
)

#pagebreak()
= Examples Gallery

== Loop Homotopy ($f tilde.equiv f'$)

Deforming a loop $f$ continuously through intermediate curves into a smaller homotopic loop $f'$ with deformation arrows.

```example-vertical
let f = cs.spline-catmull(((0, 0), (1.2, 2.5), (3, 2.2), (3.5, 0.5), (2, -1), (0, 0)), closed: true)
let f-prime = cs.spline-catmull(((0, 0), (0.8, 1.2), (1.8, 1), (2, 0.2), (1, -0.4), (0, 0)), closed: true)

draw-homotopy-field(f, f-prime, samples: 10, stroke: 0.6pt + rgb("#a8dadc"))
draw-homotopy(f, f-prime, steps: 4, stroke-fn: (t) => 0.8pt + rgb(int(20 + t * 180), 60, int(80 + t * 80)))

spline(f, stroke: 2pt + rgb("#1d3557"))
spline(f-prime, stroke: 1.5pt + rgb("#e63946"))
circle((0, 0), radius: 0.1, fill: black)
content((0, -0.4), text(size: 8pt)[$x_0$])
content((1.8, 2.7), text(size: 8pt)[$f$])
content((1.8, 1.3), text(size: 8pt)[$f'$])
```

== Loop Concatenation ($f * g$)

Two loops sharing the base point $x_0$, traversing $f$ in $[0, 1/2]$ and $g$ in $[1/2, 1]$.

```example-vertical
let left = cs.spline-catmull(((0, 0), (-1.2, 1.8), (-2.4, 0.2), (-1.5, -1.2), (0, 0)), closed: true)
let right = cs.spline-catmull(((0, 0), (1.2, 1.8), (2.4, 0.2), (1.5, -1.2), (0, 0)), closed: true)

spline(left, stroke: 2pt + rgb("#457b9d"), fill: rgb("#457b9d15"))
spline(right, stroke: 2pt + rgb("#e76f51"), fill: rgb("#e76f5115"))
circle((0, 0), radius: 0.1, fill: black)
content((0, -0.4), text(size: 8pt)[$x_0$])
content((-1.5, 0.6), text(size: 8pt)[$f$])
content((1.5, 0.6), text(size: 8pt)[$g$])
```

#pagebreak()
== Seam Detachment (Ablösen der Nahtstelle)

Homotopy that detaches the internal junction seam away from base point $x_0$, showing that loop concatenation is associative up to homotopy.

```example-vertical
let outer = cs.spline-catmull(((-2, 0), (-1, 2), (1, 2), (2, 0), (1, -1.2), (-1, -1.2)), closed: true)
let seam = cs.spline-catmull(((0, -1.2), (0, 0), (0, 1.8)))
let detached = cs.spline-catmull(((0, -0.5), (0.3, 0.2), (0, 1.8)))

spline(outer, stroke: 2pt + rgb("#264653"))
draw-homotopy(seam, detached, steps: 3, stroke-fn: (t) => 0.8pt + rgb(160, int(80 * t), 130))
spline(seam, stroke: (paint: rgb("#e63946"), thickness: 1.5pt, dash: "dashed"))
spline(detached, stroke: 1.8pt + rgb("#2a9d8f"))
circle((0, -1.2), radius: 0.1, fill: black)
content((0, -1.6), text(size: 8pt)[$x_0$])
```

#pagebreak()
== Mechanical Cam Profile Curvature Analysis

Evaluating curvature continuity of a cam curve using `draw-curvature-comb`. Needle spikes $kappa(s) dot bold(N)(s)$ and the outer envelope indicate $C^2$ acceleration continuity.

```example-vertical
let pts = (
  (0, 1.5), (1.8, 2.8), (3.2, 1.2), (2.5, -1.5),
  (0, -2.2), (-2.5, -1.5), (-3.2, 1.2), (-1.8, 2.8),
)
let cam = cs.spline-catmull(pts, alpha: 0.5, closed: true)

draw-curvature-comb(cam, samples: 60, scale: 0.8, stroke: 0.4pt + luma(160), envelope-stroke: 1.2pt + red, fill: rgb("#e6394612"))
spline(cam, stroke: 2pt + rgb("#1d3557"), fill: rgb("#f1faee"))
circle((0, 0), radius: 0.1, fill: black)
circle((0, 0), radius: 0.5, stroke: (paint: gray, thickness: 0.8pt, dash: "dashed"))
```

#pagebreak()
== Highway Lane Banding

Generating parallel roadway lanes from a centerline spline using `cs.offset`.

```example-vertical
let pts = ((-4, -1.2), (-1.5, 1.2), (1, -0.6), (3.5, 1.4), (6, 0))
let center = cs.spline-catmull(pts, alpha: 0.5)

let left = cs.offset(center, 0.8)
let right = cs.offset(center, -0.8)
let left-lane = cs.offset(center, 0.4)
let right-lane = cs.offset(center, -0.4)

spline(left, stroke: 2pt + black)
spline(left-lane, stroke: (paint: orange, thickness: 1pt, dash: "dashed"))
spline(center, stroke: 1.5pt + red)
spline(right-lane, stroke: (paint: orange, thickness: 1pt, dash: "dashed"))
spline(right, stroke: 2pt + black)
draw-tangents(center, samples: 5, scale: 0.4, stroke: 1.2pt + blue)
```

#pagebreak()
== Knot Exponent Comparison ($alpha$)

Comparison of uniform ($alpha = 0.0$), centripetal ($alpha = 0.5$), and chordal ($alpha = 1.0$) interpolation over sharp non-uniform points. Centripetal parameterization eliminates the loop artifact visible in the uniform curve.

```example-vertical
let pts = ((-3.5, 0), (-1.2, 3), (-0.8, 0.2), (0.8, 0.2), (1.2, 3), (3.5, 0))
let sp-uni = cs.spline-catmull(pts, alpha: 0.0)
let sp-cent = cs.spline-catmull(pts, alpha: 0.5)
let sp-chord = cs.spline-catmull(pts, alpha: 1.0)

spline(sp-uni, stroke: 1.5pt + red)
spline(sp-cent, stroke: 2.2pt + rgb("#1d3557"))
spline(sp-chord, stroke: 1.5pt + teal)

for p in pts { circle(p, radius: 0.08, fill: black) }

// Legend
rect((0.2, -0.7), (4.4, -1.9), stroke: 0.5pt + gray, fill: rgb("#fffffffa"))
line((0.4, -0.9), (1.1, -0.9), stroke: 1.5pt + red)
content((1.3, -0.9), anchor: "west", text(size: 7.5pt)[Uniform (alpha = 0.0) - Cusps])
line((0.4, -1.3), (1.1, -1.3), stroke: 2.2pt + rgb("#1d3557"))
content((1.3, -1.3), anchor: "west", text(size: 7.5pt)[Centripetal (alpha = 0.5) - Cusp-free])
line((0.4, -1.7), (1.1, -1.7), stroke: 1.5pt + teal)
content((1.3, -1.7), anchor: "west", text(size: 7.5pt)[Chordal (alpha = 1.0) - Smooth])
```
