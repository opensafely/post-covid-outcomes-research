import os
import copy
import random
from datetime import datetime
import pandas as pd
from tqdm import tqdm


def get_dtypes(match_variables):
    """
    Infers the dtypes for the pandas import from the type
    set in the match variables dict. This seemed simpler
    than having to seperately state the dypes in the dict.

    "category" is already specified

    ""

    "month_only" is handled separately as it requires making
    a categorical from the extracted month.
    """
    dtypes = copy.deepcopy(match_variables)
    month_only = []
    for key, value in match_variables.items():
        if isinstance(value, int):
            dtypes[key] = "int64"
        elif value == "month_only":
            del dtypes[key]
            month_only.append(key)
    return dtypes, month_only


def import_csvs(match_dict):
    """
    Imports the two csvs specified under case_csv and match_csv.
    Also adds some variables ready for matching.
    """
    dtypes, month_only = get_dtypes(match_dict["match_variables"])
    cases = pd.read_csv(
        os.path.join("..", "output", f"{match_dict['case_csv']}.csv"),
        index_col="patient_id",
        dtype=dtypes,
    )
    cases["set_id"] = -9
    matches = pd.read_csv(
        os.path.join("..", "output", f"{match_dict['match_csv']}.csv"),
        index_col="patient_id",
        dtype=dtypes,
    )

    matches["set_id"] = -9
    matches["randomise"] = 1
    random.seed(999)
    matches["randomise"] = matches["randomise"].apply(lambda x: x * random.random())

    for var in month_only:
        cases[f"{var}_m"] = cases[var].str.slice(start=5, stop=7).astype("category")
        matches[f"{var}_m"] = matches[var].str.slice(start=5, stop=7).astype("category")

    return cases, matches


def get_bool_index(match_type, case_row, match_var, matches):
    """
    Compares the value in the given case variable to the variable in
    the match dataframe, to generate a boolean index. Comparisons vary
    accoding to the specification in the match_dict.
    """
    if match_type == "category":
        bool_index = matches[match_var] == case_row[match_var]
    elif isinstance(match_type, int):
        bool_index = abs(matches[match_var] - case_row[match_var]) <= match_type
    elif match_type == "month_only":
        bool_index = matches[f"{match_var}_m"] == case_row[f"{match_var}_m"]
    else:
        raise Exception(f"Matching type '{match_type}' not yet implemented")
    return bool_index


def get_eligible_matches(case_row, matches, match_variables):
    """
    Loops over the match_variables and combines the boolean indices
    from get_bool_index into a single bool index. Also removes previously
    matched patients.
    """
    eligible_matches = pd.Series(data=True, index=matches.index)
    for match_var, match_type in match_variables.items():
        variable_bool = get_bool_index(match_type, case_row, match_var, matches)
        eligible_matches = eligible_matches & variable_bool

    unmatched = matches["set_id"] == -9
    eligible_matches = eligible_matches & unmatched
    return eligible_matches


def pick_matches(match_dict, matched_rows, case_row):
    """
    Cuts the eligible_matches list to the number of matches specified
    in the match_dict. It sorts on either just a random variable, or if
    age is specifed as a match variable, sorts on the difference in age
    between the case and the match, to get closer matches.
    """
    if "age" in match_dict["match_variables"]:
        matched_rows["age_delta"] = abs(matched_rows["age"] - case_row["age"])
        matched_rows = matched_rows.sort_values(["age_delta", "randomise"])
    else:
        matched_rows = matched_rows.sort_values("randomise")

    matched_rows = matched_rows.head(match_dict["matches_per_case"])
    return matched_rows.index


def match(match_dict):
    """
    Wrapper function that calls functions to import data, find eligible
    matches, pick the correct number of randomly allocated matches and save
    the results as a csv.
    """
    ## Import_data
    cases, matches = import_csvs(match_dict)

    for case_index, case_row in tqdm(cases.head(100).iterrows()):

        ## Get eligible matches
        eligible_matches = get_eligible_matches(
            case_row, matches, match_dict["match_variables"]
        )
        matched_rows = matches.loc[eligible_matches]
        matched_rows = matched_rows.copy()  # prevents SettingWithCopyWarning

        ## Pick random matches
        matched_rows = pick_matches(match_dict, matched_rows, case_row)

        ## Label matches with case ID
        matches.loc[matched_rows, "set_id"] = case_index
        cases.loc[case_index, "set_id"] = case_index
    return matches.loc[matches["set_id"] != -9].head()
