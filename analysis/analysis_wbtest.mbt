///|
test "histogram conserves probability mass" {
  let points = [
    @core.Vec2::new(-1.0, -1.0),
    @core.Vec2::new(0.0, 0.0),
    @core.Vec2::new(1.0, 1.0),
  ]
  let hist = Histogram2D::from_points(points, 4, 4)
  inspect(hist.total_density(), content="1")
  inspect(hist.count(0, 0) > 0, content="true")
  inspect(hist.to_csv().contains("ix,iy,count,density"), content="true")
}

///|
test "histogram identifies identical and disjoint cells" {
  let first = Histogram2D::new(2, 2, -1.0, 1.0, -1.0, 1.0)
  let second = Histogram2D::new(2, 2, -1.0, 1.0, -1.0, 1.0)
  first.add(@core.Vec2::new(-0.5, -0.5))
  second.add(@core.Vec2::new(0.5, 0.5))
  inspect(first.intersection(first), content="1")
  inspect(first.intersection(second), content="0")
  inspect(first.chi_square(second) > 0.0, content="true")
}

///|
test "distribution comparison is zero for identical points" {
  let points = [
    @core.Vec2::new(-1.0, 0.0),
    @core.Vec2::new(0.0, 1.0),
    @core.Vec2::new(1.0, 0.0),
  ]
  let result = compare(points, points, 4, 0.5)
  inspect(result.energy_distance, content="0")
  inspect(result.mmd_rbf, content="0")
  inspect(result.histogram_intersection, content="1")
  inspect(result.quality_score > 0.9, content="true")
}

///|
test "summary and quantiles expose boundary statistics" {
  let points = [
    @core.Vec2::new(-2.0, -1.0),
    @core.Vec2::new(0.0, 0.0),
    @core.Vec2::new(2.0, 3.0),
  ]
  let summary = summarize(points)
  inspect(summary.count, content="3")
  inspect(quantile_axis(points, 0, 0.0), content="-2")
  inspect(quantile_axis(points, 1, 1.0), content="3")
  inspect(duplicate_ratio(points), content="0")
  inspect(mean_nearest_neighbor_distance(points) > 0.0, content="true")
  inspect(
    summary_markdown("demo", summary).contains("Duplicate ratio"),
    content="true",
  )
}
