agrw = if uint(v: $__interval) < uint(v: 60m) then 60m else $__interval 

from(bucket: "${bucket}")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "inorg" and r.installation == "${Station}" and r.calibration == "0")
  |> keep(columns: ["_time","_field","_value"])
  |> aggregateWindow(every: agrw, fn:mean, createEmpty: true)

