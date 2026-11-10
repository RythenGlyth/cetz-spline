// cetz-spline: Root export entry point
// Advanced mathematical splines, centripetal Catmull-Rom, curvature combs,
// arc-length parameterization, and homotopies for CeTZ.

#import "core/types.typ": (
  make-spline,
  is-spline,
  assert-spline,
  clean-point,
  clean-points,
  segment-count,
  get-segment,
)

#import "core/bezier.typ": (
  cubic-point,
  cubic-derivative,
  cubic-second-derivative,
  cubic-tangent,
  cubic-normal,
  cubic-curvature,
  cubic-split,
  spline-eval,
  spline-derivative,
  spline-second-derivative,
  spline-tangent,
  spline-normal,
  spline-curvature,
)

#import "core/catmull_rom.typ": (
  catmull-to-bezier-segments,
  spline-catmull,
)

#import "core/bspline.typ": (
  generate-clamped-knots,
  generate-periodic-knots,
  cox-de-boor,
  cox-de-boor-derivative,
  bspline-to-bezier-segments,
  spline-bspline,
)

#import "core/arc_length.typ": (
  segment-arc-length,
  build-arc-length-lut,
  ensure-lut,
  with-lut,
  spline-arc-length,
  spline-t-for-distance,
  spline-point-at-distance,
)

#import "core/ops.typ": (
  resample,
  homotopy,
  offset,
  rotate-spline,
  rotate,
  translate-spline,
  translate,
  scale-spline,
  scale,
  mirror-spline,
  mirror,
)

// Canvas drawing module
#import "draw.typ" as draw
#import "draw.typ": (
  spline,
  draw-tangents,
  draw-normals,
  draw-curvature-comb,
  draw-control-polygon,
  draw-homotopy,
  draw-homotopy-field,
)
