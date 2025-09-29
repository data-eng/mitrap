from(bucket: "mitrap006")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "co2" and r.installation == "${AQH_Station}")
    |> filter(fn: (r) => r._field == "value")
    |> aggregateWindow(every: 30s, fn: mean, createEmpty: false)
    |> keep(columns: ["_time","_value"])
    |> sort(columns: ["_time"])

