import "strings"
import "array"

aggrw = if uint(v: $__interval) < uint(v: 2h) then 2h else $__interval 
rangeMs = int(v: v.timeRangeStop) - int(v: v.timeRangeStart)

opts =
  if rangeMs < 7200000000000 then { // 2h in nanoseconds
    timeRangeStart: time(v: int(v: v.timeRangeStop) - 7200000000000),
    timeRangeStop:  v.timeRangeStop
  }
  else {
    timeRangeStart: v.timeRangeStart,
    timeRangeStop:  v.timeRangeStop
  }

all_data_0 = from(bucket: "${bucket}")
  |> range(start: opts.timeRangeStart, stop: opts.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "${interp}" and r.installation == "${Station}" and r.valve == "0")
  |> keep(columns: ["_value","_field","_time"])
  |> aggregateWindow(every: aggrw, fn: sum, createEmpty: false)
  
all_data_1 = from(bucket: "${bucket}")
  |> range(start: opts.timeRangeStart, stop: opts.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "${interp}" and r.installation == "${Station}" and r.valve == "1")
  |> keep(columns: ["_value","_field","_time"])
  |> aggregateWindow(every: aggrw, fn: sum, createEmpty: false)
  
all_data_0
  |> map(fn: (r) => ({
      r with
      nm: float(v: strings.replaceAll(v: strings.replaceAll(v: r._field, t: "nm", u: ""), t: "_", u: ".")) 
  }))
  |> map(fn: (r) => ({
     r with nm_bin: r.nm 
  }))
  |> keep(columns: ["_time", "_value", "nm_bin"])

