import pandas as pd
import numpy as np

def read_data(file_path, data_type):

    if data_type == 'ops':
        cols = [
            'timestamp','installation','instrument','name','Temp','Pressure','Rel_Humidity','Errors',
            'Dilution Factor','Dead Time','Median','Mean','Geo_ Mean','Mode','Geo_St_Dev_','Total Conc_',
            'nm_0_337','nm_0_419','nm_0_522','nm_0_650','nm_0_809','nm_1_007','nm_1_254','nm_1_562',
            'nm_1_944','nm_2_421','nm_3_014','nm_3_752','nm_4_672','nm_5_816','nm_7_242','nm_9_016'
        ]
    elif data_type == 'grimm':
        cols = [
            'timestamp','installation','instrument','name',
            'nm0_25','nm0_28','nm0_30','nm0_35','nm0_40','nm0_45','nm0_50','nm0_58',
            'nm0_65','nm0_70','nm0_80','nm1_00','nm1_30','nm1_60'
        ]
    else:
        raise ValueError("Invalid data_type. Choose 'ops' or 'grimm'.")

    try:

        df = pd.read_csv(file_path, header=None, names=cols, sep=',')

        nm_cols = [c for c in df.columns if c.startswith('nm')]
        filtered_cols = ['timestamp', 'name'] + nm_cols
        df = df[filtered_cols]
        return df
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except ValueError as e:
        print(f"Error reading CSV: {e}")


def pm2_5(df, data_type):

    if data_type == 'ops':
        pass

    elif data_type == 'grimm':
        cC = [0.2646, 0.2898, 0.324, 0.3742, 0.4243, 0.4743, 0.5385, 0.614, 0.6745, 0.7483, 0.8944, 1.1402, 1.4422, 1.7889, 2.2361, 2.7386,\
              3.2404, 3.7417, 4.4721, 5.7009, 6.9821, 7.9844, 9.2195, 11.1803, 13.6931, 16.2019, 18.7083, 22.3607, 27.3861, 30.9839] 

        cC_trimmed = cC[:20]

        # Create dictionary for C0-C9, next c0-c9
        cC_dict = {f"C{i}": cC_trimmed[i] for i in range(10)}
        cC_dict.update({f"c{i}": cC_trimmed[i+10] for i in range(10)})

        nm_cols = [c for c in df.columns if c.startswith('nm')]

        grouped = df.groupby('name')

        results = []

        for name, group in grouped:

            group = group.sort_values('timestamp')


            diff = group[nm_cols].diff()*(-1)*10000

            nm_diff_sum= diff.reset_index().drop(columns=["index"]).sum(axis=1)


            volume = nm_diff_sum * np.pi * cC_dict[name]**3 / 6 
            mass = volume * 1.6 / 10**6

            mass = mass.to_frame()
            mass.columns = [name]
            mass['timestamp'] = pd.Series(df['timestamp'].unique()).sort_values().reset_index(drop=True)

            mass = mass.reset_index().drop(columns=['index']).set_index('timestamp')

            results.append(mass)

        bins = pd.concat(results, axis=1)

        return bins.iloc[:,0:8].sum(axis=1)*2 + bins.iloc[:,8:15].sum(axis=1)


ops_data = read_data("ops_3.csv", "ops")
grim_data = read_data("grimm_19.csv", "grimm")


pm25_grimm = pm2_5(grim_data, "grimm")
print(pm25_grimm)