# MI-TRAP Data Service

The MI-TRAP Data Service offers the following services:

* Upload space, where the laptops from the different installations upload data in their native format, as acquired by the instruments. The upload space of each installation is isolated from the rest (and from the overall system) to minimize risk should the laptop of one installation be compromised. The installation laptops upload their data every hour.
* Homogenization of all the different formats into Influx Line Protocol, a text-based format that is appropriate for long-term archiving and can also be directly ingested in InfluxDB.
* Analytics and visualization: Data is loaded into InfluxDB with a retainment period of 6 months. The data within the retainment period is served via Grafana which visualizes the results from complex, analytical queries.



