// tests/test_cetz_draw.typ
// Integration test for drawing splines, anchors, decorations, and homotopies in CeTZ canvases.

#import "@preview/cetz:0.5.3"
#import "../src/lib.typ" as cs

#set page(width: 20cm, height: 26cm, margin: 1cm)

= `cetz-spline` Drawing Integration Tests

== Test 1: Spline Drawing & Named Anchors

#cetz.canvas({
  import cetz.draw: *
  import cs.draw: spline

  let pts = ((0.0, 0.0), (1.5, 3.0), (3.5, 0.5), (5.0, 2.5))
  let sp = cs.spline-catmull(pts, alpha: 0.5)

  // Draw spline with named anchors
  spline(sp, name: "test-sp", stroke: 2pt + blue)

  // Verify anchors by placing markers
  circle("test-sp.pt-0", radius: 0.15, fill: red)
  circle("test-sp.pt-1", radius: 0.15, fill: green)
  circle("test-sp.pt-2", radius: 0.15, fill: orange)
  circle("test-sp.pt-3", radius: 0.15, fill: purple)
  circle("test-sp.start", radius: 0.08, fill: black)
  circle("test-sp.mid", radius: 0.12, fill: yellow)
  circle("test-sp.end", radius: 0.08, fill: black)
  circle("test-sp.t(50%)", radius: 0.10, fill: red)
  circle("test-sp.s(50%)", radius: 0.10, fill: blue)
})

== Test 2: Decorations (Tangents, Normals, Curvature Comb, Control Polygon)

#cetz.canvas({
  import cetz.draw: *
  import cs.draw: *

  let pts = ((0.0, 1.0), (2.0, 3.0), (4.0, 0.0), (6.0, 2.0))
  let sp = cs.spline-catmull(pts, alpha: 0.5)

  // Curvature comb with envelope
  draw-curvature-comb(sp, samples: 35, scale: 0.6, stroke: 0.5pt + gray, envelope-stroke: 0.8pt + red)

  // Tangents and Normals
  draw-tangents(sp, samples: 6, scale: 0.5, stroke: 1pt + blue)
  draw-normals(sp, samples: 6, scale: 0.5, stroke: 1pt + green.darken(20%))

  // Control polygon
  draw-control-polygon(sp)

  // Main spline
  spline(sp, stroke: 2pt + black)
})

== Test 3: Homotopy & Deformation Vector Field

#cetz.canvas({
  import cetz.draw: *
  import cs.draw: *

  let curve-a = cs.spline-catmull(((0.0, 0.0), (2.0, 3.0), (4.0, 0.0)))
  let curve-b = cs.spline-catmull(((0.0, 0.0), (2.0, -2.0), (4.0, 0.0)))

  // Vector field connecting curves
  draw-homotopy-field(curve-a, curve-b, samples: 10, stroke: 0.7pt + purple.lighten(30%))

  // Intermediate homotopy curves
  draw-homotopy(
    curve-a,
    curve-b,
    steps: 6,
    stroke-fn: (t) => (thickness: 0.8pt, paint: rgb(int(255 * (1.0 - t)), 30, int(255 * t)), dash: "dashed"),
  )

  spline(curve-a, stroke: 2pt + red)
  spline(curve-b, stroke: 2pt + blue)
})

== Test 4: Parallel Offset Curves (Highway Banding)

#cetz.canvas({
  import cetz.draw: *
  import cs.draw: *

  let center-pts = ((0.0, 0.0), (2.0, 2.5), (5.0, 1.0), (7.0, 3.0))
  let center-road = cs.spline-catmull(center-pts, alpha: 0.5)

  let left-kerb = cs.offset(center-road, 0.6)
  let right-kerb = cs.offset(center-road, -0.6)

  spline(left-kerb, stroke: 1.5pt + black)
  spline(center-road, stroke: (paint: gray, thickness: 1pt, dash: "dashed"))
  spline(right-kerb, stroke: 1.5pt + black)
})

== Test 5: Clamped B-Spline

#cetz.canvas({
  import cetz.draw: *
  import cs.draw: *

  let b-pts = ((0.0, 0.0), (1.0, 4.0), (3.0, 4.0), (4.0, 0.0), (6.0, 2.0))
  let b-sp = cs.spline-bspline(b-pts, degree: 3)

  draw-control-polygon(b-sp)
  spline(b-sp, stroke: 2pt + teal)
})
