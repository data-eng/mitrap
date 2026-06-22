# MI-TRAP Utils


## Finalizing a campaign

When a campaign is finalized, its data is moved from the `live` bucket into
a set of buckets containing historical data. A good balance is needed between
having too many buckets and having too much data in one bucket. A policy that
has proven useful is to separate the different CE boxes into different historical
buckets, so that each bucket does not have too much temporally overlapping data.
Since all queries constrain the time range to the campaign period, this makes
effective use of influxdb's time index.

The current setup is as follows:
 * Bucket `pkg000`: CE boxes `mitrap000` and `mitrap001` and the HR stations from
   the respective campaigns. Currently `mitrap006` (Athens) and
   `mitrap011` (Copenhagen).
 * Bucket `pkg002`: CE boxes `mitrap004` and `mitrap005` and the HR stations from
   the respective campaigns. Currently `mitrap009` (Rotterdam).
 * Bucket `pkg003`: CE boxes `mitrap002` and `mitrap003` and the HR stations from
   the respective campaigns. Currently `mitrap010` (Florence).


### Finalization: Data package

Each of the data packages above has its own directory where the data package
is prepared and kept, besides any subsequent re-packaging and publishing.
Each package directory has the following structure:

 1 One toml file per campaign, with the relevant sections from the live
   configuration file. Since the CE boxes keep their `mitrapXXX` identifier
   across campaigns, these cannot be combined into a single toml.
 2 A set of directories `<campaign>_raw/mitrapXXX` with copies of the original
   data. Only the usuful files are copied over from the `incoming/` and `web/`
   data-sync directories and their paths are normalized and sanitized (spaces
   and other problematic filenames are renamed).
 3 A file `NOTES.text` that records the mapping from `incoming/` and `web/` to
   the `raw` directories as well as manual intervention performed besides the
   automated processing by the `finalize` utility.
 4 A set of directories `<campaign>_pkg/mitrapXXX` with the mitrap-schema CSV
   and influx line protocol files.

Steps:

 1 Edit `installations.toml` to stop the processing of incoming data.
   For HR stations this is not important, but for CE boxes this ensures that
   when the relevant section is re-activated all data from the new campaign
   will be considered new data and processed. In any case, after copying into
   the historical package directory remove any data of the new campaign from
   `backup` so that at the next data-sync cycle they will be considered new.
   Note in `data_fetchers/sync.sh` how the cycle starts with syncing 
   `incoming` with upstream, comparing `incoming` to `backup` to see what
   has changed, and fianlly syncing `incoming` into `backup`.

 2 Manually prepare 1-3 above, copying data and the relevant configuration
   sections. Beware of `permission denied` errors when working with a different
   system user than the data sync user. 

 3 Execute finalize to re-run all processing and make csv and lp files.

 4 Load the lp files into the historical data bucket. Remove this campaign's
   data from the live bucket.




### Finalization: Live dashboard

Steps:
 * Copy the live dashboard to a new dashboard with a name showing that it is
   not active. Eg., `AQM-CE: Florence Lavagnini` was copied into
   `AQM-CE: Florence Lavagnini (Nov 2025 - Feb 2026)`.



