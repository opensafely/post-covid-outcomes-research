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
    matches = pd.read_csv(
        os.path.join("..", "output", f"{match_dict['match_csv']}.csv"),
        index_col="patient_id",
        dtype=dtypes,
    )

    cases["set_id"] = -9
    matches["set_id"] = -9
    matches["randomise"] = 1
    random.seed(999)
    matches["randomise"] = matches["randomise"].apply(lambda x: x * random.random())

    ## Extract month from month_only variables
    for var in month_only:
        cases[f"{var}_m"] = cases[var].str.slice(start=5, stop=7).astype("category")
        matches[f"{var}_m"] = matches[var].str.slice(start=5, stop=7).astype("category")

    ## Format exclusion variables as dates
    if "date_exclusion_variables" in match_dict:
        for var in match_dict["date_exclusion_variables"]:
            cases[var] = pd.to_datetime(cases[var])
            matches[var] = pd.to_datetime(matches[var])
            cases[match_dict["index_date_variable"]] = pd.to_datetime(
                cases[match_dict["index_date_variable"]]
            )
            if "replace_match_index_date_with_case" not in match_dict:
                matches[match_dict["index_date_variable"]] = pd.to_datetime(
                    matches[match_dict["index_date_variable"]]
                )

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

    not_previously_matched = matches["set_id"] == -9
    eligible_matches = eligible_matches & not_previously_matched
    return eligible_matches


def date_exclusions(df1, date_exclusion_variables, df2, index_date):
    """
    Loops over the exclusion variables and creates a boolean array corresponding
    to where there are exclusion variables that occur before the index date.
    """
    exclusions = pd.Series(data=False, index=df1.index)
    for exclusion_var, before_after in date_exclusion_variables.items():
        if before_after == "before":
            variable_bool = df1[exclusion_var] <= df2[index_date]
        elif before_after == "after":
            variable_bool = df1[exclusion_var] > df2[index_date]
        else:
            raise Exception(f"Date exclusion type '{exclusion_var}' invalid")
        exclusions = exclusions | variable_bool
    return exclusions


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
    Wrapper function that calls functions to:
    - import data
    - find eligible matches
    - pick the correct number of randomly allocated matches
    - make exclusions that are based on index date
      - (this is not currently possible in a study definition, and will only ever be possible
        during matching for studies where the match index date comes from the case)
    - set the set_id as that of the case_id (this excludes them from being matched later)
    - set the index date of the match as that of the case (where desired)
    - save the results as a csv
    """

    ## Import_data
    cases, matches = import_csvs(match_dict)

    if "date_exclusion_variables" in match_dict:
        case_exclusions = date_exclusions(
            cases,
            match_dict["date_exclusion_variables"],
            cases,
            match_dict["index_date_variable"],
        )
        cases = cases.loc[~case_exclusions]

    for case_id, case_row in tqdm(cases.iterrows()):
        ## Get eligible matches
        eligible_matches = get_eligible_matches(
            case_row, matches, match_dict["match_variables"]
        )
        matched_rows = matches.loc[eligible_matches]

        ## Index date based match exclusions
        if "date_exclusion_variables" in match_dict:
            exclusions = date_exclusions(
                matched_rows,
                match_dict["date_exclusion_variables"],
                case_row,
                match_dict["index_date_variable"],
            )
            matched_rows = matched_rows.loc[~exclusions]

        ## Pick random matches (.copy() prevents SettingWithCopyWarning
        ## when setting age_delta in pick_matches)
        matched_rows = pick_matches(match_dict, matched_rows.copy(), case_row)

        ## Label matches with case ID
        matches.loc[matched_rows, "set_id"] = case_id
        if len(matches.loc[matched_rows, "set_id"]) > 0:
            cases.loc[case_id, "set_id"] = case_id

        ## Set index_date of the match where needed
        if "replace_match_index_date_with_case" in match_dict:
            matches.loc[matched_rows, match_dict["index_date_variable"]] = case_row[
                match_dict["index_date_variable"]
            ]

    matched_cases = cases.loc[cases["set_id"] != -9]
    matched_matches = matches.loc[matches["set_id"] != -9]

    matched_cases.to_csv(
        os.path.join(
            "..",
            "output",
            f"{match_dict['case_csv']}_matched_{match_dict['match_csv']}.csv",
        )
    )
    matched_matches.to_csv(
        os.path.join("..", "output", f"{match_dict['match_csv']}_matched.csv")
    )

    return matched_cases, matched_matches
