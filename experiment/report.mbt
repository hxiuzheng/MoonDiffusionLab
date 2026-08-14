///|
/// 将一个聚合结果编码为稳定的 JSON 对象。
pub fn result_json(result : ExperimentResult) -> String {
  "{" +
  "\"name\":\"" +
  result.name +
  "\", " +
  "\"dataset\":\"" +
  dataset_label(result.dataset) +
  "\", " +
  "\"sampler\":\"" +
  sampler_label(result.sampler) +
  "\", " +
  "\"repeats\":" +
  result.repeats.to_string() +
  ", " +
  "\"mean_wasserstein\":" +
  result.mean_wasserstein.to_string() +
  ", " +
  "\"std_wasserstein\":" +
  result.std_wasserstein.to_string() +
  ", " +
  "\"min_wasserstein\":" +
  result.min_wasserstein.to_string() +
  ", " +
  "\"max_wasserstein\":" +
  result.max_wasserstein.to_string() +
  ", " +
  "\"mean_error\":" +
  result.mean_error.to_string() +
  ", " +
  "\"variance_error\":" +
  result.variance_error.to_string() +
  ", " +
  "\"mean_coverage\":" +
  result.mean_coverage.to_string() +
  ", " +
  "\"pass_rate\":" +
  result.pass_rate.to_string() +
  ", " +
  "\"best_seed\":" +
  result.best_seed.to_string() +
  "}"
}

///|
/// 输出带表头的聚合 CSV。
pub fn results_csv(results : Array[ExperimentResult]) -> String {
  let mut out = "name,dataset,sampler,repeats,mean_wasserstein,std_wasserstein,min_wasserstein,max_wasserstein,mean_error,variance_error,mean_coverage,pass_rate,best_seed\n"
  for result in results {
    out += result.name +
      "," +
      dataset_label(result.dataset) +
      "," +
      sampler_label(result.sampler) +
      "," +
      result.repeats.to_string() +
      "," +
      result.mean_wasserstein.to_string() +
      "," +
      result.std_wasserstein.to_string() +
      "," +
      result.min_wasserstein.to_string() +
      "," +
      result.max_wasserstein.to_string() +
      "," +
      result.mean_error.to_string() +
      "," +
      result.variance_error.to_string() +
      "," +
      result.mean_coverage.to_string() +
      "," +
      result.pass_rate.to_string() +
      "," +
      result.best_seed.to_string() +
      "\n"
  }
  out
}

///|
/// 以均值 Wasserstein 距离升序输出比较表。
pub fn results_markdown(results : Array[ExperimentResult]) -> String {
  let ordered = results.copy()
  ordered.sort_by(fn(a, b) {
    if a.mean_wasserstein < b.mean_wasserstein {
      -1
    } else if a.mean_wasserstein > b.mean_wasserstein {
      1
    } else {
      0
    }
  })
  let mut out = "| Rank | Case | Mean W1 | Std W1 | Coverage | Pass rate | Best seed |\n"
  out += "|---:|---|---:|---:|---:|---:|---:|\n"
  for i, result in ordered {
    out += "| " +
      (i + 1).to_string() +
      " | " +
      result.name +
      " | " +
      result.mean_wasserstein.to_string() +
      " | " +
      result.std_wasserstein.to_string() +
      " | " +
      result.mean_coverage.to_string() +
      " | " +
      result.pass_rate.to_string() +
      " | " +
      result.best_seed.to_string() +
      " |\n"
  }
  out
}

///|
/// 选择平均 Wasserstein 最小的案例；空列表返回 None。
pub fn best_result(results : Array[ExperimentResult]) -> ExperimentResult? {
  if results.length() == 0 {
    return None
  }
  let mut best = results[0]
  for result in results[1:] {
    if result.mean_wasserstein < best.mean_wasserstein {
      best = result
    }
  }
  Some(best)
}

///|
/// 计算一组案例的平均通过率。
pub fn average_pass_rate(results : Array[ExperimentResult]) -> Double {
  if results.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for result in results {
    total += result.pass_rate
  }
  total / results.length().to_double()
}
