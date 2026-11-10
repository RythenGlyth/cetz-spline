#set page(
  width: 23cm,
  height: 7cm,
  margin: (x: 0.8cm, y: 0.5cm),
  fill: rgb("#f8fafc"),
)
#set text(font: "Liberation Sans", size: 9pt)

#import "@preview/cetz:0.5.3"
#import "../src/lib.typ" as cs

#align(center + horizon)[
  #cetz.canvas({
    import cetz.draw: *
    import cs.draw: *

    // Main sweeping curve points
    let pts = (
      (0.6, 1.4),
      (3.2, 3.8),
      (6.8, 1.2),
      (10.6, 4.3),
      (14.5, 1.6),
      (17.8, 3.8),
      (20.2, 2.0),
    )

    let sp = cs.spline-catmull(pts, alpha: 0.5)

    // Parallel offset ribbon (outer casing)
    let off-top = cs.offset(sp, 0.55)
    let off-bot = cs.offset(sp, -0.55)
    spline(off-top, stroke: 1.2pt + rgb("#94a3b8"))
    spline(off-bot, stroke: 1.2pt + rgb("#94a3b8"))

    // Curvature comb along the central spline
    draw-curvature-comb(
      sp,
      samples: 90,
      scale: 0.75,
      stroke: 0.4pt + rgb("#cbd5e1"),
      envelope-stroke: 1.4pt + rgb("#ef4444"),
      fill: rgb("#ef444415"),
    )

    // Control polygon
    draw-control-polygon(sp, stroke: (paint: rgb("#94a3b8"), thickness: 0.6pt, dash: "dashed"))

    // Main spline curve
    spline(sp, name: "main-crv", stroke: 2.8pt + rgb("#0f172a"))

    // Tangent velocity vectors
    draw-tangents(sp, samples: 7, scale: 0.9, stroke: 1.4pt + rgb("#0284c7"))

    // Arc-length callouts at s = 25%, 50%, 75%
    for (pct, label, side) in ((25, "s = 25%", -1), (50, "s = 50%", 1), (75, "s = 75%", -1)) {
      let anc = "main-crv.s(" + str(pct) + "%)"
      let dist = (pct / 100.0) * cs.spline-arc-length(sp)
      let lbl-anc = cs.spline-label-anchor-at-distance(sp, dist, side: side)
      circle(anc, radius: 0.12, fill: rgb("#10b981"), stroke: 1.5pt + white)
      content(
        anc,
        box(fill: rgb("#fffffffa"), outset: 2pt, radius: 2pt, stroke: 0.4pt + rgb("#cbd5e1"))[
          #text(size: 7pt, weight: "bold", fill: rgb("#065f46"))[#label]
        ],
        anchor: lbl-anc,
        padding: 0.14,
      )
    }

    // Endpoint anchors
    circle("main-crv.start", radius: 0.14, fill: rgb("#0284c7"), stroke: 1.5pt + white)
    content(
      "main-crv.start",
      text(size: 8pt, weight: "bold", fill: rgb("#0369a1"))["start"],
      anchor: 45deg,
      padding: 0.15,
    )

    circle("main-crv.end", radius: 0.14, fill: rgb("#0284c7"), stroke: 1.5pt + white)
    content(
      "main-crv.end",
      text(size: 8pt, weight: "bold", fill: rgb("#0369a1"))["end"],
      anchor: 135deg,
      padding: 0.15,
    )
  })
]
