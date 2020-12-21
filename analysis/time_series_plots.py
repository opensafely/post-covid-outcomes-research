import pandas as pd
import matplotlib.pyplot as plt


def import_timeseries(path, name):
    df = pd.read_csv(path, usecols=["date", "covid_hospitalisation", name])
    df["date"] = pd.to_datetime(df["date"])
    df = df.set_index(["date", "covid_hospitalisation"])
    df = df.unstack()
    return df


## Get data
names = ["stroke", "DVT", "PE"]
files = [f"output/measure_{name}_rate.csv" for name in names]
dfs = [import_timeseries(path, name) for path, name in zip(files, names)]
df_to_plot = pd.concat(dfs, axis=1)

## Draw plots
fig, axes = plt.subplots(ncols=1, nrows=3, figsize=[8, 10])
for i, ax in enumerate(axes.flat):
    df_to_plot[names[i]].plot.area(ax=ax)
    title = f"{chr(97 + i)}) Patients with a {names[i]} event each month:"
    ax.set_title(title, loc="left")
    ax.legend().set_title("")
    ax.set_ylim = (0, None)
    ax.set_ylabel(f"patients with a {names[i]} event")

plt.savefig("output/event_count_time_series.svg")
