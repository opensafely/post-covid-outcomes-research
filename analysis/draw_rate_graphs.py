import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

color_cycle = ["#ff7f00", "#3579b1", "#3b86c4", "#4e92ca", "#629fd0", "#76abd6"]
old_names = ["0 days", "30 days", "60 days", "90 days", "120 days"]
new_names = ["0-29 days", "30-59 days", "60-89 days", "90-119 days", "120+ days"]
groups = ["covid", "pneumonia"]
titles = [
    "a) Patients hospitalised with COVID-19",
    "b) Patients hospitalised with pneumonia in 2019",
    "c) Patients positive for SARS-CoV-2, not hospitalised",
]


df = pd.DataFrame()
for f in groups:
    df = df.append(pd.read_csv(f"released_output/rates_summary_{f}.csv"))
df = df.replace(to_replace=dict(zip(old_names, new_names)))
# suffix = df["outcome"].str.split("_", n=1, expand=True)[1]
# print(suffix)
# df["outcome_group"] = ""
# df.loc[df["outcome"].str.contains("_cens_gp"), "outcome_group"] = "_cens_gp"
# df.loc[df["outcome"].str.contains("_no_gp"), "outcome_group"] = "_no_gp"
df = df.set_index(["group", "outcome", "time"])
df = df.loc[df["variable"] == "Overall"]
print(df)


def plot_rates(outcome_group, rows):
    fig, axes = plt.subplots(ncols=2, nrows=1, sharey=True, figsize=[12, 6])
    for i, ax in enumerate(axes.flat):
        df_to_plot = df.loc[df.index.isin(rows, level=1)]
        df_to_plot = df_to_plot.loc[groups[i]]
        df_to_plot = df_to_plot * 10
        df_to_plot = df_to_plot.unstack(level=-1)
        errlo = df_to_plot["rate_ppm"] - df_to_plot["lc_ppm"]
        errhi = df_to_plot["uc_ppm"] - df_to_plot["rate_ppm"]
        errlo_arr = errlo.values[:, np.newaxis, :]
        errhi_arr = errhi.values[:, np.newaxis, :]
        yerr = np.append(errlo_arr, errhi_arr, axis=1).T
        data = df_to_plot["rate_ppm"]
        data = data[["Full period"] + new_names]
        data.plot(kind="bar", ax=ax, width=0.8, yerr=yerr, color=color_cycle)
        ax.set_title(titles[i], loc="left")
        ax.legend(loc=2).set_title("Time since index date")
        ax.set_xticklabels(labels)
        ax.set_ylabel("Rate of each outcome (per 10,000 person months)")
        ax.grid(b=True, axis="y", color="#666666", linestyle="-", alpha=0.1)
        plt.tight_layout()
    plt.savefig(f"output/rate_graphs{outcome_group}.svg")


outcome_groups = {
    "_cens_gp": [
        "stroke_cens_gp",
        "dvt_cens_gp",
        "pe_cens_gp",
        "heart_failure_cens_gp",
        "mi_cens_gp",
        "aki",
        "t2dm",
    ],
    "_all": ["stroke", "dvt", "pe", "heart_failure", "mi", "aki", "t2dm"],
    "_no_gp": [
        "stroke_no_gp",
        "dvt_no_gp",
        "pe_no_gp",
        "heart_failure_no_gp",
        "mi_no_gp",
        "aki",
        "t2dm",
    ],
}
labels = ["Stroke", "DVT", "PE", "Heart failure", "MI", "AKI", "T2DM"]
for group, rows in outcome_groups.items():
    plot_rates(group, rows)
