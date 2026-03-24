agrw = if uint(v: $__interval) < uint(v: 60m) then 60m else $__interval 

from(bucket: "${bucket}")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "pm" and r.installation == "${Station}")
  |> filter(fn: (r) => r._field == "pm25")
  |> aggregateWindow(every: agrw, fn:mean)
  |> keep(columns: ["_field", "_value", "_time"])

