# `cetz-spline`

> **Advanced mathematical splines, centripetal Catmull-Rom parameterization, curvature combs, arc-length parameterization, and homotopies for [CeTZ](https://github.com/cetz-package/cetz).**

[![Typst Version](https://img.shields.io/badge/Typst-%3E%3D0.11.0-blue.svg)](https://typst.app)
[![CeTZ Version](https://img.shields.io/badge/CeTZ-0.5.3-green.svg)](https://github.com/cetz-package/cetz)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE-MIT)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen.svg)](test.sh)
[![Documentation](https://img.shields.io/badge/manual-PDF-purple.svg)](manual.pdf)

![cetz-spline Overview](assets/cover.png)

---

## Features

- **Centripetal & Chordal Catmull-Rom Splines ($\alpha = 0.5, 1.0$)**: Eliminates cusps, self-intersections, and overshoot at sharp corners (in contrast to standard uniform $\alpha = 0$).
- **Second Derivatives & Signed Curvature Fields**: Acceleration $C''(u)$, Frenet unit normal field $\mathbf{N}(u)$, and signed curvature $\kappa(u) = \frac{x'y'' - y'x''}{(x'^2 + y'^2)^{3/2}}$.
- **Arbitrary-Degree B-Splines**: Uniform and clamped B-splines via Cox-de Boor recursion with exact cubic Bézier decomposition.
- **High-Precision Arc Length**: 5-point Gauss-Legendre numerical quadrature with Newton-Raphson distance inversion ($s \mapsto t$).
- **Homotopy & Morphing Operators**: Continuous curve deformations, intermediate parameter families, and directional deformation vector fields.
- **Parallel Offset Curves**: Computes parallel offset curves $C(u) + d \cdot \mathbf{N}(u)$ with curvature-scaled tangent matching.
- **CAD-Style Geometric Visualizers**: Curvature combs (spikes $\kappa \cdot \mathbf{N}$ connected by envelope curve), velocity tangent vectors, normal vectors, and control polygons.
- **Seamless CeTZ Canvas Integration & Named Anchors**: Full anchor support (`name.start`, `name.end`, `name.mid`, `name.pt-<idx>`, `name.t(50%)`, `name.s(50%)`).

---

## Installation & Import

```typst
#import "@preview/cetz:0.5.3"
#import "@preview/cetz-spline:0.1.0" as cs
```

Or for local development:
```typst
#import "@local/cetz-spline:0.1.0" as cs
```

---

## Quick Start

```typst
#import "@preview/cetz:0.5.3"
#import "@local/cetz-spline:0.1.0" as cs

#cetz.canvas({
  import cetz.draw: *
  import cs.draw: spline, draw-curvature-comb, draw-tangents

  let pts = ((0.0, 0.0), (1.5, 3.0), (3.5, 0.5), (5.0, 2.5))
  let sp = cs.spline-catmull(pts, alpha: 0.5)

  // Draw CAD curvature comb with shaded area and envelope
  draw-curvature-comb(
    sp,
    samples: 40,
    scale: 0.6,
    stroke: 0.4pt + luma(180),
    envelope-stroke: 1.2pt + red,
    fill: rgb("#e6394615"),
  )

  // Draw main spline with CeTZ named anchors
  spline(sp, name: "my-curve", stroke: 2pt + blue)

  // Access named anchors
  circle("my-curve.pt-1", radius: 0.12, fill: orange)
  circle("my-curve.mid", radius: 0.12, fill: purple)
  circle("my-curve.s(50%)", radius: 0.12, fill: green)
})
```

---

## API Summary

### Spline Constructors
- `cs.spline-catmull(points, alpha: 0.5, closed: false, boundary: "clamped")`: Creates a generalized Catmull-Rom spline ($\alpha = 0.5$ centripetal, $\alpha = 0.0$ uniform, $\alpha = 1.0$ chordal).
- `cs.spline-bspline(points, degree: 3, closed: false, knots: none)`: Creates an arbitrary-degree B-spline via Cox-de Boor recursion.

### Analytical Evaluation
- `cs.spline-eval(spline, t)`: Point on curve $C(t)$ for $t \in [0, 1]$.
- `cs.spline-derivative(spline, t)`: Velocity vector $C'(t)$.
- `cs.spline-second-derivative(spline, t)`: Acceleration vector $C''(t)$.
- `cs.spline-tangent(spline, t)`: Unit tangent vector $\mathbf{T}(t)$.
- `cs.spline-normal(spline, t)`: Unit normal vector $\mathbf{N}(t) = (-T_y, T_x)$.
- `cs.spline-curvature(spline, t)`: Signed curvature $\kappa(t)$.

### Arc Length & Inversion
- `cs.spline-arc-length(spline, t1: 0.0, t2: 1.0)`: True arc length via 5-point Gauss-Legendre quadrature.
- `cs.spline-t-for-distance(spline, s)`: Newton-Raphson distance inversion $s \mapsto t$.
- `cs.spline-point-at-distance(spline, s)`: Point at exact arc-length distance $s$.

### Transformations & Operations
- `cs.rotate-spline(spline, angle, origin: (0, 0))`: Rigid rotation around pivot (`origin`), preserving Bézier geometry and arc lengths (aliased as `rotate`).
- `cs.translate-spline(spline, offset)`: Rigid 2D translation (aliased as `translate`).
- `cs.scale-spline(spline, factor, origin: (0, 0), dir: none)`: Scaling with negative factor and directional scaling support (aliased as `scale`).
- `cs.mirror-spline(spline, origin: (0, 0), axis: "x")`: Reflection across an axis line or point reflection (aliased as `mirror`).
- `cs.resample(spline, count)`: Uniform physical arc-length point resampling.
- `cs.homotopy(spline-a, spline-b, t)`: Intermediate morphed curve at parameter $t \in [0, 1]$.
- `cs.offset(spline, distance, subdivide: true)`: Parallel normal offset curve.

### Drawing Elements (`cs.draw`)
- `cs.draw.spline(spline-obj, name: none, stroke: 1pt + black, fill: none, close: false)`: CeTZ canvas element wrapper with anchor injection.
- `cs.draw.draw-tangents(spline-obj, samples: 10, scale: 0.4, stroke: blue)`: Directed velocity arrows.
- `cs.draw.draw-normals(spline-obj, samples: 10, scale: 0.4, stroke: red)`: Perpendicular Frenet normal vectors.
- `cs.draw.draw-curvature-comb(spline-obj, samples: 40, scale: 0.5, stroke: gray, envelope-stroke: red, fill: none)`: CAD curvature spikes with envelope.
- `cs.draw.draw-control-polygon(spline-obj, stroke: dashed, pt-radius: 0.05)`: Control polygon hull.
- `cs.draw.draw-homotopy(spline-a, spline-b, steps: 5, stroke-fn: (t) => ...)`: Morphed intermediate curve family.
- `cs.draw.draw-homotopy-field(spline-a, spline-b, samples: 8, stroke: blue)`: Directed deformation vector field arrows.

---

## Testing

A test script [`test.sh`](test.sh) is included to run all mathematical unit tests, knot verification, CeTZ canvas tests, and documentation compilation:

```bash
chmod +x test.sh
./test.sh
```

---

## Documentation

A comprehensive, publication-grade manual is available both as Typst source ([`manual.typ`](manual.typ)) and pre-compiled PDF ([`manual.pdf`](manual.pdf)).

To compile locally:
```bash
typst compile --root . manual.typ manual.pdf
```

---

## License

MIT License. See [LICENSE-MIT](LICENSE-MIT).
