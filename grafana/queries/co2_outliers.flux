import "math"

win = 6 + 6
shiftPrev = 6
pointInterval = 30s

base =
  from(bucket: "${bucket}")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "co2" and r.installation == "${AQH_Station}")
    |> filter(fn: (r) => r._field == "value")
    |> aggregateWindow(every: 30s, fn: mean, createEmpty: false)
    |> keep(columns: ["_time","_value"])
    |> sort(columns: ["_time"])

rollMean =
  base
    |> movingAverage(n: win)
    |> timeShift(duration: -180s)
    |> rename(columns: {_value: "mean_excl"})

rollE2 =
  base
    |> map(fn: (r) => ({ r with _value: r._value*r._value }))
    |> movingAverage(n: win)
    |> timeShift(duration: -180s)
    |> rename(columns: {_value: "e2_excl"})

joined1 = join(
  tables: {o: base, m: rollMean},
  on: ["_time"],
  method: "inner"
)

joined2 = join(
    tables: {jm: joined1, e: rollE2},
    on: ["_time"],
    method: "inner"
)

joined =
  joined2
  |> map(fn: (r) => {
      std = math.sqrt(x: r.e2_excl - r.mean_excl*r.mean_excl)
      outlier = if math.abs(x: r._value - r.mean_excl) > 3.0*std then true else false
      return {_time: r._time, _value: r._value, outlier: outlier}
    })
    |> filter(fn: (r) => r.outlier == false)
    |> drop(columns: ["outlier"]) 

joined
