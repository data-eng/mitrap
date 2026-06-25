agrw = if uint(v: $__interval) < uint(v: 1h) then 1h else $__interval 
//agrw = $__interval 

from(bucket: "${bucket}")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "noxco" and r.installation == "${Station}")
    |> keep(columns: ["_time","_field","_value"])
    |> aggregateWindow(every:agrw, fn:mean, createEmpty:true)

