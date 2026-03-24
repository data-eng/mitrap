agrw = if uint(v: $__interval) < uint(v: 30m) then 30m else $__interval 

from(bucket: "${bucket}")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "pm" and r.installation == "${Station}")
  |> filter(fn: (r) => r._field == "valve_state" or r._field == "pm25")
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> filter(fn: (r) => r.valve_state != 2)
  |> map(fn: (r) => ({
      r with
      id: if r.valve_state == 0 then "Solid" else if r.valve_state == 1 then "Ambient" else if r.valve_state == 2 then "Uncertain" else "Valve missing",
      _value: r.pm25,
  }))
  |> group(columns: ["id"])
  |> keep(columns: ["id","_value", "_time"])
  |> aggregateWindow(every: agrw, fn: mean, createEmpty: true)
  |> map(fn: (r) => ({ r with _value: if r._value > 0 and r._value < 100 then r._value else 1.0/0.0 }) )

