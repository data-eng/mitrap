# MI-TRAP Data Service

The MI-TRAP Data Service offers the following services:

* Upload space, where the laptops from the different installations upload data in their native format, as acquired by the instruments. The upload space of each installation is isolated from the rest (and from the overall system) to minimize risk should the laptop of one installation be compromised. The installation laptops upload their data every hour.
* Homogenization of all the different formats into Influx Line Protocol, a text-based format that is appropriate for long-term archiving and can also be directly ingested in InfluxDB.
* Analytics and visualization: Data is loaded into InfluxDB with a retainment period of 6 months. The data within the retainment period is served via Grafana which visualizes the results from complex, analytical queries.


## Supported measurements and formats

Parsers for the following measurements are available:

 * Black carbon mass concetration
 * CO2 concentration
 * Flow Meter Valves
 * PM2.5 mass concetration
 * Ultrafine particle number concetration and size distribution


### CO2 concentration

The following parsers are available:

 * `co2_com1`: Data acquired from GMP252 using custom software
    Sample line: `2025-10-15,00:00:00,CO2=   421 ppm`
 * `co2_modbus`: Data acquired from GMP252 using Vaisala modbus
   Sample line: `2025-11-13 08:03:25; CO2=427.4059 ppm; T=25.55132 °C`
   where °C has the degree symbol encoded in ISO-8859-1
 * `co2`: Data acquired from GMP343 using custom software
   Sample line: `2025-05-21,00:00:00,[447.4]`


