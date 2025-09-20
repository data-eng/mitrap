source /home/mitrap/.influx.env

for f in /mnt/incoming/mitrap001/mitrap1/CO2/Data/COM1_Log_2025-09-* ; do
	echo "Parsing $f"
	bash ~debian/live/parsers/co2_com1.sh $f temp 'Athens - Aristotelous - CE' CO2
	echo "Writing $f"
	/usr/bin/influx write --bucket mitrap006 --org mitrap --token $MITRAP_WRITE_TOKEN --file temp
	rm temp
done

