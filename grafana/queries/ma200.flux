from(bucket: "${bucket}")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "ma200" and r.installation == "${AQH_Station}")
    |> filter(fn: (r) => r._field == "uvbcc" or r._field == "bluebcc" or r._field == "redbcc" or r._field == "greenbcc" or r._field == "irbcc")
     |> map(fn: (r) => ({
      r with _value: r._value / 1000.0
    }))
    |> keep( columns: [ "id", "_field", "_value", "_time"] )
