// manual.typ
// Complete Reference Manual and Example Gallery for cetz-spline

#import "@preview/cetz:0.5.3"
#import "src/lib.typ" as cs

#set document(
  title: "cetz-spline: Advanced Curve Geometry & Splines for CeTZ",
  author: "Typst Community Contributor",
)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: context {
    let i = counter(page).get().first()
    if i > 1 [
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8pt, fill: luma(120), font: "Liberation Sans", weight: "bold")[cetz-spline 0.1.0]],
        align(right)[#text(size: 8pt, fill: luma(120), font: "Liberation Sans")[Reference Manual & Guide]],
      )
      #line(length: 100%, stroke: 0.4pt + luma(200))
    ]
  },
  footer: context {
    let i = counter(page).get().first()
    if i > 1 [
      #line(length: 100%, stroke: 0.4pt + luma(200))
      #grid(
        columns: (1fr, 1fr),
        align(left)[#text(size: 8pt, fill: luma(120))[Documentation]],
        align(right)[#text(size: 8pt, fill: luma(120))[Page #i]],
      )
    ]
  },
)

#set text(font: "Liberation Serif", size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.7em)
#show raw: set text(font: "Liberation Mono", size: 9pt)

// Styling helpers
#let primary = rgb("#1d3557")
#let secondary = rgb("#457b9d")
#let accent = rgb("#e63946")
#let bg-box = rgb("#f8f9fa")

#let code-box(title, body) = block(
  width: 100%,
  stroke: 0.6pt + luma(200),
  radius: 4pt,
  fill: bg-box,
  inset: 10pt,
  [
    #if title != none [
      #text(weight: "bold", size: 9pt, fill: primary)[#title]
      #v(4pt)
    ]
    #body
  ]
)

#let api-doc(name, sig, desc, args: (:)) = block(
  width: 100%,
  stroke: (left: 3pt + secondary),
  inset: (left: 10pt, y: 6pt),
  above: 8pt,
  below: 8pt,
  [
    #text(weight: "bold", size: 11pt, fill: primary)[#raw(name)]
    #h(6pt)
    #text(fill: luma(100), size: 9pt)[#raw(sig)]
    #v(2pt)
    #desc
    #if args.len() > 0 [
      #v(3pt)
      #text(weight: "semibold", size: 9pt)[Arguments:]
      #list(
        ..args.pairs().map(((k, v)) => [
          #raw(k): #v
        ])
      )
    ]
  ]
)

// Title block
#align(center)[
  #v(1cm)
  #text(size: 26pt, weight: "bold", fill: primary)[cetz-spline]
  #v(4pt)
  #text(size: 14pt, fill: secondary)[Advanced Curve Geometry & Splines for CeTZ]
  #v(12pt)
  #grid(
    columns: (auto, auto, auto, auto),
    gutter: 18pt,
    [#text(weight: "bold")[Version:] 0.1.0],
    [#text(weight: "bold")[Typst:] #sym.gt.eq 0.11.0],
    [#text(weight: "bold")[CeTZ:] 0.5.3],
    [#text(weight: "bold")[License:] MIT],
  )
  #v(1cm)
]

#outline(indent: 1.5em)
#pagebreak()

= 1. Project Overview & Philosophy

`cetz-spline` provides a mathematically rigorous, extensible spline evaluation and geometric visualization library for Typst and CeTZ.

=== Design Principles:

1. *Zero Redundancy with CeTZ Core*:
   CeTZ already contains robust 2D/3D vector mathematics (`cetz.vector`), basic cubic Bézier evaluation (`cubic-point`, `cubic-derivative`), and de Casteljau subdivision (`cetz.bezier.split`). `cetz-spline` directly builds upon these foundations without re-inventing basic primitives.

2. *Focus on Novel Geometric Capabilities*:
   - *Centripetal & Chordal Catmull-Rom Parameterization* ($alpha = 0.5, 1.0$) to eliminate cusps, self-intersections, and overshoot artifacts (CeTZ only supports uniform $alpha = 0$).
   - *Second Derivatives & Curvature Fields*: Acceleration $C''(u)$, Frenet unit normal $bold(N)(u)$, and signed curvature $kappa(u)$.
   - *Arbitrary-Degree B-Splines*: Clamped and periodic B-splines via Cox-de Boor recursion with exact cubic Bézier decomposition.
   - *High-Precision Arc Length*: 5-point Gauss-Legendre quadrature with Newton-Raphson distance inversion ($s |-> t$).
   - *Homotopy & Morphing Operators*: Topological loop deformations, intermediate parameter families, and directional deformation vector fields.
   - *Geometric Visualizers*: CAD-style curvature combs, velocity tangent fields, and normal fields.

---

= 2. Quick Start Guide

== Installation & Import

To use `cetz-spline` with local package resolution:

```typst
#import "@preview/cetz:0.5.3"
#import "@local/cetz-spline:0.1.0" as cs
```

== Minimal Working Example

Creating a centripetal Catmull-Rom spline and visualizing it with CeTZ:

#grid(
  columns: (3fr, 2fr),
  gutter: 12pt,
  [
```typst
#cetz.canvas({
  import cetz.draw: *
  import cs.draw: spline

  let pts = (
    (0.0, 0.0),
    (1.5, 2.5),
    (3.5, 0.5),
    (5.0, 2.0),
  )
  let sp = cs.spline-catmull(pts, alpha: 0.5)

  spline(sp, name: "my-curve", stroke: 2pt + blue)
  circle("my-curve.pt-1", radius: 0.15, fill: red)
  circle("my-curve.mid", radius: 0.15, fill: orange)
})
```
  ],
  align(center + horizon)[
    #cetz.canvas({
      import cetz.draw: *
      import cs.draw: spline

      let pts = ((0.0, 0.0), (1.5, 2.5), (3.5, 0.5), (5.0, 2.0))
      let sp = cs.spline-catmull(pts, alpha: 0.5)

      spline(sp, name: "my-curve", stroke: 2pt + rgb("#1d3557"))
      circle("my-curve.pt-1", radius: 0.15, fill: rgb("#e63946"))
      circle("my-curve.mid", radius: 0.15, fill: rgb("#f4a261"))
    })
  ]
)

---

= 3. Core Mathematical Concepts

== 3.1. The Spline Dictionary Representation

Every curve in `cetz-spline` is represented as an immutable dictionary:

```typst
#let make-spline(
  type: "catmull-rom",       // "catmull-rom" | "bspline" | "homotopy" | "offset"
  pts: (),                   // Array of original control points
  closed: false,             // bool
  meta: (:),                 // Metadata: (alpha: 0.5, degree: 3, ...)
  segments: (),              // Native CeTZ Bézier segments: ((s, e, c1, c2), ...)
  lut: none,                 // Cached arc-length lookup table
)
```

Each segment inside `segments` follows CeTZ's standard format:
$ (bold(s), bold(e), bold(c)_1, bold(c)_2) $
where $bold(s)$ is the starting point, $bold(e)$ is the end point, $bold(c)_1$ is the first control point, and $bold(c)_2$ is the second control point.

== 3.2. Why Centripetal ($alpha = 0.5$) Parameterization Matters

Given consecutive control points $bold(P)_0, bold(P)_1, bold(P)_2, bold(P)_3$, knot intervals are computed as:
$ t_0 = 0, quad t_(i+1) = t_i + ||bold(P)_(i+1) - bold(P)_i||^alpha $
- $alpha = 0.0$: *Uniform Catmull-Rom* (known for sharp loops, self-intersections, and overshoot at sharp corners).
- $alpha = 0.5$: *Centripetal Catmull-Rom* (theoretically proven to never self-intersect within segments and prevents cusps).
- $alpha = 1.0$: *Chordal Catmull-Rom* (follows chord length, gentler curves).

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    import cs.draw: *

    let pts = ((0.0, 0.0), (1.0, 3.5), (1.5, 0.2), (4.0, 0.0))
    let sp-uni = cs.spline-catmull(pts, alpha: 0.0)
    let sp-cent = cs.spline-catmull(pts, alpha: 0.5)
    let sp-chord = cs.spline-catmull(pts, alpha: 1.0)

    spline(sp-uni, stroke: 1.5pt + rgb("#e63946"))
    spline(sp-cent, stroke: 2pt + rgb("#1d3557"))
    spline(sp-chord, stroke: 1.5pt + rgb("#2a9d8f"))

    for pt in pts {
      circle(pt, radius: 0.08, fill: black)
    }

    // Legend
    rect((4.2, 2.5), (6.8, 1.0), stroke: 0.5pt + gray, fill: rgb("#ffffffcc"))
    line((4.4, 2.2), (5.0, 2.2), stroke: 1.5pt + rgb("#e63946"))
    content((5.1, 2.2), anchor: "west", text(size: 8pt)[Uniform ($alpha = 0$)])
    line((4.4, 1.8), (5.0, 1.8), stroke: 2pt + rgb("#1d3557"))
    content((5.1, 1.8), anchor: "west", text(size: 8pt)[Centripetal ($alpha = 0.5$)])
    line((4.4, 1.4), (5.0, 1.4), stroke: 1.5pt + rgb("#2a9d8f"))
    content((5.1, 1.4), anchor: "west", text(size: 8pt)[Chordal ($alpha = 1.0$)])
  })
]

== 3.3. Exact Arc-Length vs. Parametric $t$

Parametric speed $||C'(t)||$ along polynomial splines is rarely constant. Placing objects at uniform intervals in $t$ causes crowding where the curve moves slowly and sparse spacing where it accelerates.
`cetz-spline` evaluates true geometric arc length via 5-point Gauss-Legendre quadrature:
$ s(u) = integral_0^u ||C'(tau)|| d tau approx frac(u, 2) sum_(i=1)^5 w_i ||C'(frac(u(1 + x_i), 2))|| $
Inversion $s |-> t$ uses quadratically convergent Newton-Raphson:
$ u_(k+1) = u_k - frac(s(u_k) - s_("target"), ||C'(u_k)||) $

---

= 4. Complete API Reference

== 4.1. Spline Constructors

#api-doc(
  "spline-catmull",
  "(points, alpha: 0.5, closed: false, boundary: \"clamped\")",
  [Constructs an $alpha$-parameterized Catmull-Rom spline through the specified points.],
  args: (
    "points": [Array of 2D coordinates `((x0, y0), (x1, y1), ...)`],
    "alpha": [Knot exponent: `0.0` (uniform), `0.5` (centripetal, default), `1.0` (chordal)],
    "closed": [Whether curve forms a closed periodic loop (`bool`)],
    "boundary": [Ghost point boundary condition: `"clamped"` (default) or `"natural"`],
  )
)

#api-doc(
  "spline-bspline",
  "(points, degree: 3, closed: false, knots: none)",
  [Constructs an arbitrary-degree B-spline using Cox-de Boor recursion and exact Bézier decomposition.],
  args: (
    "points": [Array of control polygon vertices],
    "degree": [Polynomial degree (default 3 for cubic B-spline)],
    "closed": [Whether curve forms a closed periodic loop],
    "knots": [Optional explicit knot vector, or `none` for standard clamped/periodic knots],
  )
)

== 4.2. Analytical Evaluation

#api-doc("spline-eval", "(spline, t)", [Evaluates position $C(t) in bb(R)^2$ for global parameter $t in [0, 1]$.])
#api-doc("spline-derivative", "(spline, t)", [Computes velocity / first derivative $C'(t) = frac(d C, d t)$.])
#api-doc("spline-second-derivative", "(spline, t)", [Computes acceleration / second derivative $C''(t) = frac(d^2 C, d t^2)$.])
#api-doc("spline-tangent", "(spline, t)", [Computes unit tangent vector $bold(T)(t) = frac(C'(t), ||C'(t)||)$.])
#api-doc("spline-normal", "(spline, t)", [Computes Frenet unit normal vector $bold(N)(t) = (-T_y, T_x)$.])
#api-doc("spline-curvature", "(spline, t)", [Computes signed scalar curvature $kappa(t) = frac(x' y'' - y' x'', (x'^2 + y'^2)^(3/2))$.])

== 4.3. Arc-Length Operations

#api-doc("spline-arc-length", "(spline, t1: 0.0, t2: 1.0)", [Computes total arc length, or segment distance between $t_1$ and $t_2$, via 5-point Gauss-Legendre quadrature.])
#api-doc("spline-t-for-distance", "(spline, distance)", [Inverts arc length $s |-> t$ using Newton-Raphson iteration.])
#api-doc("spline-point-at-distance", "(spline, distance)", [Evaluates curve point at exact physical distance $s$ along the curve.])

== 4.4. Geometric Transformations

#api-doc("resample", "(spline, count)", [Resamples the curve into `count` points spaced uniformly by physical arc length.])
#api-doc("homotopy", "(spline-a, spline-b, t)", [Computes the intermediate morphed spline at homotopy parameter $t in [0, 1]$. Resamples automatically if segment counts differ.])
#api-doc("offset", "(spline, distance, subdivide: true)", [Computes a parallel offset curve displaced along the normal field $C_("offset")(u) = C(u) + d dot bold(N)(u)$ with curvature-scaled tangent matching.])

== 4.5. CeTZ Canvas Drawing Commands

#api-doc("draw.spline", "(spline-obj, name: none, stroke: 1pt + black, fill: none, close: false)", [Primary CeTZ canvas element wrapper. Registers named anchors: `"start"`, `"end"`, `"mid"`, `"pt-<idx>"`, `"t(50%)"`, `"s(50%)"`, `"50%"`.])
#api-doc("draw.draw-tangents", "(spline-obj, samples: 10, scale: 0.4, stroke: blue)", [Draws directed tangent/velocity arrows along the curve.])
#api-doc("draw.draw-normals", "(spline-obj, samples: 10, scale: 0.4, stroke: red)", [Draws perpendicular normal vectors along the curve.])
#api-doc("draw.draw-curvature-comb", "(spline-obj, samples: 40, scale: 0.5, stroke: gray, envelope-stroke: blue)", [Renders CAD-style curvature needles $kappa dot bold(N)$ connected by an envelope curve.])
#api-doc("draw.draw-control-polygon", "(spline-obj, stroke: dashed, pt-radius: 0.05)", [Draws the Bézier control polygon handles and vertices.])
#api-doc("draw.draw-homotopy", "(spline-a, spline-b, steps: 5, stroke-fn: (t) => ...)", [Draws a family of intermediate curves under homotopy deformation.])
#api-doc("draw.draw-homotopy-field", "(spline-a, spline-b, samples: 8, stroke: blue)", [Draws directed deformation vector field arrows connecting curve A to curve B.])

---

= 5. Comprehensive Examples Gallery

== Example 1: The Three Topological Panels

Homotopy theory analyzes equivalence classes of continuous loops. The following three panels demonstrate:
1. *Loop Homotopy ($f tilde.equiv f'$)*: A loop deformed smoothly over parameter $t in [0, 1]$ into a contractible loop.
2. *Loop Concatenation ($f * g$)*: Two loops joined at base point $x_0$.
3. *Seam Detachment (Ablösen der Nahtstelle)*: Demonstrating that concatenation is associative up to homotopy.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    import cs.draw: *

    // Panel 1: Loop Homotopy
    group(name: "panel1", {
      let loop-f = cs.spline-catmull(((0.0, 0.0), (1.2, 2.5), (3.0, 2.2), (3.5, 0.5), (2.0, -1.0), (0.0, 0.0)), closed: true)
      let loop-g = cs.spline-catmull(((0.0, 0.0), (0.8, 1.2), (1.8, 1.0), (2.0, 0.2), (1.0, -0.4), (0.0, 0.0)), closed: true)

      draw-homotopy-field(loop-f, loop-g, samples: 12, stroke: 0.5pt + rgb("#a8dadc"))
      draw-homotopy(loop-f, loop-g, steps: 4, stroke-fn: (t) => 0.7pt + rgb(int(29 + t * 180), int(53 + t * 50), int(87 + t * 80)))

      spline(loop-f, stroke: 2pt + rgb("#1d3557"))
      spline(loop-g, stroke: 1.5pt + rgb("#e63946"))
      circle((0.0, 0.0), radius: 0.12, fill: black)
      content((0.0, -0.4), text(size: 9pt, weight: "bold")[$x_0$])
      content((1.8, 2.7), text(size: 9pt, fill: rgb("#1d3557"))[$f$])
      content((1.8, 1.3), text(size: 9pt, fill: rgb("#e63946"))[$f'$])
      content((1.8, -1.5), text(size: 9.5pt, weight: "bold")[(A) Schleifenhomotopie $f tilde.equiv f'$])
    })

    // Panel 2: Concatenation
    group(name: "panel2", {
      translate((5.5, 0.0))
      let loop-left = cs.spline-catmull(((0.0, 0.0), (-1.2, 1.8), (-2.4, 0.2), (-1.5, -1.2), (0.0, 0.0)), closed: true)
      let loop-right = cs.spline-catmull(((0.0, 0.0), (1.2, 1.8), (2.4, 0.2), (1.5, -1.2), (0.0, 0.0)), closed: true)

      spline(loop-left, stroke: 2pt + rgb("#457b9d"), fill: rgb("#457b9d15"))
      spline(loop-right, stroke: 2pt + rgb("#e76f51"), fill: rgb("#e76f5115"))

      circle((0.0, 0.0), radius: 0.12, fill: black)
      content((0.0, -0.4), text(size: 9pt, weight: "bold")[$x_0$])
      content((-1.5, 0.6), text(size: 9.5pt, fill: rgb("#457b9d"))[$f$])
      content((1.5, 0.6), text(size: 9.5pt, fill: rgb("#e76f51"))[$g$])
      content((0.0, -1.5), text(size: 9.5pt, weight: "bold")[(B) Konkatenation $f * g$])
    })

    // Panel 3: Seam Detachment
    group(name: "panel3", {
      translate((11.0, 0.0))
      let outer-loop = cs.spline-catmull(((-2.0, 0.0), (-1.0, 2.0), (1.0, 2.0), (2.0, 0.0), (1.0, -1.2), (-1.0, -1.2)), closed: true)
      let seam-attached = cs.spline-catmull(((0.0, -1.2), (0.0, 0.0), (0.0, 1.8)))
      let seam-detached = cs.spline-catmull(((0.0, -0.5), (0.3, 0.2), (0.0, 1.8)))

      spline(outer-loop, stroke: 2pt + rgb("#264653"))
      draw-homotopy(seam-attached, seam-detached, steps: 3, stroke-fn: (t) => 0.8pt + rgb(180, int(100 * t), 150))
      spline(seam-attached, stroke: (paint: rgb("#e63946"), thickness: 1.5pt, dash: "dashed"))
      spline(seam-detached, stroke: 1.8pt + rgb("#2a9d8f"))

      circle((0.0, -1.2), radius: 0.12, fill: black)
      content((0.0, -1.6), text(size: 9pt, weight: "bold")[$x_0$])
      content((0.0, -2.1), text(size: 9.5pt, weight: "bold")[(C) Ablösen der Nahtstelle])
    })
  })
]

== Example 2: Curvature Analysis of an Asymmetric Cam Profile

In mechanical cam design, $C^2$ continuity guarantees bounded acceleration and jerk. The curvature comb below visually highlights curvature peaks and inflections.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    import cs.draw: *

    let cam-pts = (
      (0.0, 1.5),
      (1.8, 2.8),
      (3.2, 1.2),
      (2.5, -1.5),
      (0.0, -2.2),
      (-2.5, -1.5),
      (-3.2, 1.2),
      (-1.8, 2.8),
    )
    let cam = cs.spline-catmull(cam-pts, alpha: 0.5, closed: true)

    // Curvature comb
    draw-curvature-comb(
      cam,
      samples: 60,
      scale: 0.8,
      stroke: 0.4pt + luma(150),
      envelope-stroke: 1.2pt + rgb("#e63946"),
      fill: rgb("#e6394612"),
    )

    // Central cam
    spline(cam, stroke: 2.2pt + rgb("#1d3557"), fill: rgb("#f1faee"))

    // Center of rotation
    circle((0.0, 0.0), radius: 0.12, fill: black)
    circle((0.0, 0.0), radius: 0.6, stroke: (paint: gray, thickness: 0.8pt, dash: "dashed"))
    content((0.0, -0.3), text(size: 8pt)[Shaft axis])
  })
]

== Example 3: Parallel Offset Curves & Highway Banding

Generating parallel roadway lanes, kerbs, and lane markers from a single centerline trajectory using `cs.offset`.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    import cs.draw: *

    let highway-pts = (
      (-5.0, -1.5),
      (-2.0, 1.5),
      (1.0, -0.8),
      (4.0, 1.8),
      (7.0, 0.0),
    )
    let center = cs.spline-catmull(highway-pts, alpha: 0.5)

    let left-edge = cs.offset(center, 1.0)
    let right-edge = cs.offset(center, -1.0)
    let left-lane = cs.offset(center, 0.5)
    let right-lane = cs.offset(center, -0.5)

    // Road surface band
    spline(left-edge, stroke: 2pt + black)
    spline(left-lane, stroke: (paint: rgb("#f4a261"), thickness: 1pt, dash: "dashed"))
    spline(center, stroke: 1.5pt + rgb("#e63946"))
    spline(right-lane, stroke: (paint: rgb("#f4a261"), thickness: 1pt, dash: "dashed"))
    spline(right-edge, stroke: 2pt + black)

    // Direction arrows along highway
    draw-tangents(center, samples: 6, scale: 0.4, stroke: 1.2pt + rgb("#1d3557"))
  })
]

== Example 4: Centripetal vs. Chordal vs. Uniform Comparison

Demonstrating the effect of knot exponent $alpha$ when interpolating sharp, non-uniform point configurations.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    import cs.draw: *

    let sharp-pts = (
      (-4.0, 0.0),
      (-1.5, 3.5),
      (-1.0, 0.2),
      (1.0, 0.2),
      (1.5, 3.5),
      (4.0, 0.0),
    )

    let sp-uniform = cs.spline-catmull(sharp-pts, alpha: 0.0)
    let sp-centripetal = cs.spline-catmull(sharp-pts, alpha: 0.5)
    let sp-chordal = cs.spline-catmull(sharp-pts, alpha: 1.0)

    spline(sp-uniform, stroke: 1.5pt + rgb("#e63946"))
    spline(sp-centripetal, stroke: 2.2pt + rgb("#1d3557"))
    spline(sp-chordal, stroke: 1.5pt + rgb("#2a9d8f"))

    for pt in sharp-pts {
      circle(pt, radius: 0.1, fill: black)
    }

    // Legend
    rect((0.5, -0.8), (4.5, -2.2), stroke: 0.5pt + gray, fill: rgb("#ffffffea"))
    line((0.8, -1.1), (1.6, -1.1), stroke: 1.5pt + rgb("#e63946"))
    content((1.8, -1.1), anchor: "west", text(size: 8.5pt)[Uniform ($alpha = 0.0$) - Loops/Cusps])
    line((0.8, -1.5), (1.6, -1.5), stroke: 2.2pt + rgb("#1d3557"))
    content((1.8, -1.5), anchor: "west", text(size: 8.5pt)[Centripetal ($alpha = 0.5$) - Cusp-free])
    line((0.8, -1.9), (1.6, -1.9), stroke: 1.5pt + rgb("#2a9d8f"))
    content((1.8, -1.9), anchor: "west", text(size: 8.5pt)[Chordal ($alpha = 1.0$) - Smooth])
  })
]
