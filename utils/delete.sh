source /home/mitrap/.influx.env

influx delete -t $MITRAP_WRITE_TOKEN -b mitrap006 \
  --start '1970-01-01T00:00:00Z' \
  --stop $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --predicate '_measurement="example-measurement" AND exampleTag="exampleTagValue"'

