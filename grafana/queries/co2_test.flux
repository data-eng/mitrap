
from(bucket: "mitrap006")
    |> range(start: -6h, stop: -1h)
    |> filter(fn: (r) => r._measurement == "co2" and r.installation == "Athens - Patission - HR")
    |> filter(fn: (r) => r._field == "value")
    |> aggregateWindow(every: 30s, fn: mean, createEmpty: false)
    |> keep(columns: ["_time","_value"])
    |> sort(columns: ["_time"])

