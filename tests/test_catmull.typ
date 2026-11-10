// tests/test_catmull.typ
#import "../src/core/types.typ": is-spline, segment-count
#import "../src/core/catmull_rom.typ": spline-catmull, catmull-to-bezier-segments
#import "../src/core/bspline.typ": spline-bspline, bspline-to-bezier-segments
#import "../src/core/bezier.typ": spline-eval

#let approx-eq(a, b, eps: 1e-4) = {
  calc.abs(a - b) < eps
}

// Test 1: Catmull-Rom open clamped segment count
#{
  let pts = ((0.0, 0.0), (1.0, 2.0), (3.0, 1.0), (4.0, 3.0))
  let sp = spline-catmull(pts, alpha: 0.5, closed: false)
  assert(is-spline(sp))
  // 4 points open should yield 3 segments
  assert(sp.segments.len() == 3, message: "Expected 3 segments, got " + str(sp.segments.len()))

  // Spline start and end should match first and last points
  let p-start = spline-eval(sp, 0.0)
  let p-end = spline-eval(sp, 1.0)
  assert(approx-eq(p-start.at(0), 0.0) and approx-eq(p-start.at(1), 0.0))
  assert(approx-eq(p-end.at(0), 4.0) and approx-eq(p-end.at(1), 3.0))

  // Internal knot evaluation: at t = 1/3, should pass through point 1 (1.0, 2.0)
  let p-1 = spline-eval(sp, 1.0 / 3.0)
  assert(approx-eq(p-1.at(0), 1.0) and approx-eq(p-1.at(1), 2.0))

  // At t = 2/3, should pass through point 2 (3.0, 1.0)
  let p-2 = spline-eval(sp, 2.0 / 3.0)
  assert(approx-eq(p-2.at(0), 3.0) and approx-eq(p-2.at(1), 1.0))
}

// Test 2: Catmull-Rom closed periodic
#{
  let pts = ((0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0))
  let sp = spline-catmull(pts, alpha: 0.5, closed: true)
  // 4 points closed should yield 4 segments
  assert(sp.segments.len() == 4, message: "Expected 4 segments, got " + str(sp.segments.len()))
  let p-start = spline-eval(sp, 0.0)
  let p-end = spline-eval(sp, 1.0)
  assert(approx-eq(p-start.at(0), p-end.at(0)) and approx-eq(p-start.at(1), p-end.at(1)))
}

// Test 3: Alpha parameter variations (uniform, centripetal, chordal)
#{
  let pts = ((0.0, 0.0), (1.0, 5.0), (2.0, 0.0))
  let sp-uni = spline-catmull(pts, alpha: 0.0)
  let sp-cent = spline-catmull(pts, alpha: 0.5)
  let sp-chord = spline-catmull(pts, alpha: 1.0)
  assert(sp-uni.segments.len() == 2)
  assert(sp-cent.segments.len() == 2)
  assert(sp-chord.segments.len() == 2)
}

// Test 4: B-Spline clamped cubic
#{
  let pts = ((0.0, 0.0), (1.0, 3.0), (2.0, -1.0), (4.0, 2.0), (6.0, 0.0))
  let sp-b = spline-bspline(pts, degree: 3, closed: false)
  assert(is-spline(sp-b))
  let p-start = spline-eval(sp-b, 0.0)
  let p-end = spline-eval(sp-b, 1.0)
  assert(approx-eq(p-start.at(0), 0.0) and approx-eq(p-start.at(1), 0.0))
  assert(approx-eq(p-end.at(0), 6.0) and approx-eq(p-end.at(1), 0.0))
}

Catmull-Rom and B-spline tests passed!
