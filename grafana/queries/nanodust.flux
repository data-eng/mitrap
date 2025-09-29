import "strings"

from(bucket: "${bucket}")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nanodust" and r.installation == "${AQH_Station}")
  |> filter(fn: (r) => r._field == "mode" or r._field == "pn")
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> filter(fn: (r) => exists r.mode and exists r.pn)
  |> map(fn: (r) => ({
        _time: r._time,
        _value: float(v: r.pn),
        _field: strings.trim(v: r.mode, cutset: " \t\n")
  }))
  |> group(columns: ["_field"])
