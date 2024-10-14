import pandas as pd

# Reading the CSV file
df = pd.read_csv('data/MA200.csv')

df_cols_to_keep = pd.read_csv('data/Columns_to_keep.csv')

df = df[df_cols_to_keep.columns]
df = df.drop(columns=['Date local (yyyy/MM/dd)', 'Time local (hh:mm:ss)', 'Timezone offset (mins)'])

df['time'] = pd.to_datetime(df['Date / time local'])
df = df.drop('Date / time local', axis=1)
df = df.dropna(subset=['time'])

print(max(df['time']))
print(min(df['time']))

df.columns = df.columns.str.replace(' ', '_').str.lower()
df.columns = df.columns.str.replace(r'\s*\(.*?\)', '', regex=True).str.strip()
df.columns = df.columns.str.rstrip('_')

print(df.dtypes)

df.to_csv('data/MA200_filtered.csv')

'''families = {'flows': ['flow_setpoint', 'flow_total', 'flow1', 'flow2'],
            'sample': ['sample_temp', 'sample_rh', 'sample_dewpoint'],
            'uv': ['uv_bc1', 'uv_bc2', 'uv_bcc', 'uv_atn1', 'uv_atn2', 'uv_k'],
            'ir': ['ir_atn1', 'ir_atn2', 'ir_k', 'ir_bc1', 'ir_bc2', 'ir_bcc'],
            'blue': ['blue_atn1', 'blue_atn2', 'blue_k', 'blue_bc1', 'blue_bc2', 'blue_bcc'],
            'green': ['green_atn1', 'green_atn2', 'green_k', 'green_bc1', 'green_bc2', 'green_bcc'],
            'red': ['red_atn1', 'red_atn2', 'red_k', 'red_bc1', 'red_bc2', 'red_bcc'],
            'info': ['gps_lat', 'gps_long', 'status', 'battery_remaining', 'tape_position', 'readable_status'],
            'internal': ['internal_pressure', 'internal_temp']}'''


families = {'flows': ['flow_setpoint', 'flow_total', 'flow1', 'flow2'],
            'sample': ['sample_temp', 'sample_rh', 'sample_dewpoint'],
            'uv': ['uv_bc1', 'uv_bc2', 'uv_bcc', 'uv_atn1'],
            'ir': ['ir_atn1',  'ir_bc1', 'ir_bc2', 'ir_bcc'],
            'blue': ['blue_atn1', 'blue_bc1', 'blue_bc2', 'blue_bcc'],
            'green': ['green_atn1', 'green_bc1', 'green_bc2', 'green_bcc'],
            'red': ['red_atn1',  'red_bc1', 'red_bc2', 'red_bcc'],
            'info': ['gps_lat', 'gps_long', 'status', 'battery_remaining', 'tape_position'],
            'internal': ['internal_pressure', 'internal_temp'],
            'string_values': ['uv_atn2', 'uv_k', 'blue_atn2', 'blue_k', 'green_atn2', 'green_k', 'red_atn2', 'red_k',
                              'ir_atn2', 'ir_k', 'readable_status']}


influx_lines = []

# Loop over each family and their associated measurements
for family, measurements in families.items():
    for measurement in measurements:
        # Create line protocol format
        for index, row in df.iterrows():

            if pd.isna(row[measurement]) or row[measurement] == '"':
                continue

            # Convert time to nanoseconds since epoch
            timestamp_ns = int(row['time'].timestamp() * 1e9)
            if pd.api.types.is_numeric_dtype(type(row[measurement])):
                line = f'{family},instrument=MA200 {measurement}={row[measurement]} {timestamp_ns}'
            else:
                line = f'{family},instrument=MA200 {measurement}="{row[measurement]}" {timestamp_ns}'
            influx_lines.append(line)

# Display the resulting line protocol format
print("\nInfluxDB Line Protocol Format:")
'''for line in influx_lines:
    print(line)'''

with open('data/influx_csv.txt', 'w', newline='') as file:
    for line in influx_lines:
        file.write(f"{line}\n")

print("Data written to data.txt")
