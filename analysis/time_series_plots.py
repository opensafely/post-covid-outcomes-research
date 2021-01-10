import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.dates import AutoDateLocator, ConciseDateFormatter
from study_definition_measures import measures


def import_timeseries(measure):
    path = f"output/measure_{measure.id}.csv"
    df = pd.read_csv(path, usecols=["date", measure.numerator] + measure.group_by)
    df["date"] = pd.to_datetime(df["date"])
    df = df.set_index(["date"] + measure.group_by)
    df = df.unstack(measure.group_by)
    df.columns = df.columns.droplevel()
    return df.iloc[:, ::-1]


def grammar_decider(word):
    if word == "died":
        return "who died"
    return f"with a recorded {word.replace('_', ' ')}"


fig, axes = plt.subplots(ncols=4, nrows=2, sharex=False, figsize=[22, 8])
for i, ax in enumerate(axes.flat):
    if i < len(measures):
        m = measures[i]
        df = import_timeseries(m)
        df.plot(
            kind="bar",
            stacked=True,
            ax=ax,
            width=0.85,
            alpha=0.9,
            color=["#176dde", "#e6e600", "#ffad33"],
        )
        ax.grid(which="both", axis="y", color="#666666", linestyle="-", alpha=0.2)
        title = f"{chr(97 + i)}) People {grammar_decider(m.numerator)} each month:"
        labs = [a.get_text().replace("-01 00:00:00", "") for a in ax.get_xticklabels()]
        ax.set_xticklabels(labs)
        ax.set_title(title, loc="left")
        ax.set_ylim = (0, None)
        ax.set_ylabel(f"people {grammar_decider(m.numerator)}")
        handles, labels = ax.get_legend_handles_labels()
        handles, labels = list(reversed(handles)), list(reversed(labels))
        ax.legend(handles, labels, loc=3, prop={"size": 9}).set_title("")
        plt.tight_layout()
plt.savefig("output/event_count_time_series.svg")
