# MI-TRAP Data Service

The MI-TRAP Data Service offers the following services:

* Upload space, where the laptops from the different installations upload data in their native format, as acquired by the instruments. The upload space of each installation is isolated from the rest (and from the overall system) to minimize risk should the laptop of one installation be compromised. The installation laptops upload their data every hour.
* Homogenization of all the different formats into Influx Line Protocol, a text-based format that is appropriate for long-term archiving and can also be directly ingested in InfluxDB.
* Analytics and visualization: Data is loaded into InfluxDB with a retainment period of 6 months. The data within the retainment period is served via Grafana which visualizes the results from complex, analytical queries.


## Supported measurements and formats

Parsers for the following measurements are available:

 * Black carbon mass concentration
 * CO2 particle number concentration
 * Elemental concentration
 * Flow Meter Valves
 * Organic fraction concentration
 * Particle mass concetration and size distribution
 * Ultrafine particle number concentration and size distribution


### CO2 particle number concentration

The following parsers are available:

 * `co2_com1`: Data acquired from GMP252 using custom software. \
    Sample line: `2025-11-13,08:03:25,CO2=   427 ppm`
 * `co2_modbus`: Data acquired from GMP252 using Vaisala modbus. \
   Sample line: `2025-11-13 08:03:25; CO2=427.4059 ppm; T=25.55132 °C` \
   where °C has the degree symbol encoded in ISO-8859-1
 * `co2`: Data acquired from GMP343 using custom software. \
   Sample line: `2025-11-13,08:03:25,[427.4]`
 * `co2_licor`: Data acquired from LI-COR gas analyser. \
   Sample line: `08:03:25 427.41 25.55 102.09` \
   where the columns are `time`, `ppm`, `temperature`, `pressure` 
   and the date for each file in given at the top of the file.
   Times might be after mightnight to indicate the following date.


### Elemental concentration

The following parser is available:

 * `inorg_xact`: Elemental concentration from the Xact instrument.


### Organic fraction concentration

The following parser is available:

 * `org_acsm`: Data following the IGOR format.


### Particle mass concentration and size distribution

This is a two-step process. The first step homogenizes the data
acquired from different instruments into a CVS with the particle
number concentrations for different particle-diameter bins;
The second step calculates mass concentration by estimating mass from
the median diameter in each size bin.

The following parsers are available for the first step:

 * `pm_grimm`: Data acquired from Grimm OPC.
   This is a multi-line format, where lines starting with `P` give the datetime,
   followed by several lines starting with `C|c` giving the
   concentration distribution for different partcicle diameters.
 * `pm_ops`: Data acquired from TSI OPS (Optical Particle Sizer).
   Standard CSV files, except for several lines of metadata
   at the top of the file before the actual CSV header.
 * `pm_pplus`: Data acquired from ParticlesPlus 9300P-OEM.
   Standard CSV files, except for several lines of metadata
   at the top of the file before the actual CSV header.

All parsers output a CSV with datetime, location, instrument, and
number concentrations for different size bins. The size of each bin
is given in the header.

The `pm25.py` script calculates concentration for particles
up to size 2.5, and adds as the fourth column.


 * Ultrafine particle number concentration and size distribution

The following parsers are available:

 * `uf_cpc3750`, `uf_cpc3752`, `uf_cpc3772`: Data in various formats exported
   by Condensation Particle Counter (CPC) instruments.

 * `nanodust`:

The CPC instruments do not make the solid/ambient distinction, so a valve is
used to alternate between the two measurements. To prepare the final dataframe
the following pipeline is used: (a) Re-format the original file into a CSV,
(b) query the database to find the valve position at each sample, and (c) export
the final CSV and lp files.


