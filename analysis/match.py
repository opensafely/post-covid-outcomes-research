import os
import copy
import random
from datetime import datetime
import pandas as pd


def import_csvs(match_dict):
    """
    Imports the two csvs specified under case_csv and match_csv.
    Also adds some variables ready for matching and sets the correct data
    types for the matching variables.
    """
    cases = pd.read_csv(
        os.path.join("..", "output", f"{match_dict['case_csv']}.csv"),
        index_col="patient_id",
    )
    matches = pd.read_csv(
        os.path.join("..", "output", f"{match_dict['match_csv']}.csv"),
        index_col="patient_id",
    )

    ## Drop cases from match population
    matches = matches.drop(cases.index)

    cases["set_id"] = -9
    matches["set_id"] = -9
    matches["randomise"] = 1
    random.seed(999)
    matches["randomise"] = matches["randomise"].apply(lambda x: x * random.random())

    ## Set data types for matching variables
    month_only = []
    for var, match_type in match_dict["match_variables"].items():
        if match_type == "category":
            cases[var] = cases[var].astype("category")
            matches[var] = matches[var].astype("category")
        ## Extract month from month_only variables
        elif match_type == "month_only":
            month_only.append(var)
            cases[f"{var}_m"] = cases[var].str.slice(start=5, stop=7).astype("category")
            matches[f"{var}_m"] = (
                matches[var].str.slice(start=5, stop=7).astype("category")
            )
    for var in month_only:
        del match_dict["match_variables"][var]
        match_dict["match_variables"][f"{var}_m"] = "category"

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


def get_bool_index(match_type, value, match_var, matches):
    """
    Compares the value in the given case variable to the variable in
    the match dataframe, to generate a boolean index. Comparisons vary
    accoding to the specification in the match_dict.
    """
    if match_type == "category":
        bool_index = matches[match_var] == value
    elif isinstance(match_type, int):
        bool_index = abs(matches[match_var] - value) <= match_type
    # elif match_type == "month_only":
    #     bool_index = matches[f"{match_var}_m"] == value
    else:
        raise Exception(f"Matching type '{match_type}' not yet implemented")
    return bool_index


def pre_calculate_indices(cases, matches, match_variables):
    """
    Loops over each of the values in the case table for each of the match
    variables and generates a boolean index against the match table. These are
    returned in a dict.
    """
    indices_dict = {}
    for match_var in match_variables:
        match_type = match_variables[match_var]
        indices_dict[match_var] = {}

        values = cases[match_var].unique()
        for value in values:
            index = get_bool_index(match_type, value, match_var, matches)
            indices_dict[match_var][value] = index
    return indices_dict


def get_eligible_matches(case_row, matches, match_variables, indices):
    """
    Loops over the match_variables and combines the boolean indices
    from pre_calculate_indices into a single bool index. Also removes previously
    matched patients.
    """
    eligible_matches = pd.Series(data=True, index=matches.index)
    for match_var in match_variables:
        variable_bool = indices[match_var][case_row[match_var]]
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


def greedily_pick_matches(match_dict, matched_rows, case_row):
    """
    Cuts the eligible_matches list to the number of matches specified in
    the match_dict. This is a greedy matching method, so if closest_match_columns
    are specified, it sorts on those variables to get the closest available matches
    for that case. It always also sorts on random variable.
    """
    sort_columns = []
    if "closest_match_columns" in match_dict:
        for var in match_dict["closest_match_columns"]:
            matched_rows[f"{var}_delta"] = abs(matched_rows[var] - case_row[var])
            sort_columns.append(f"{var}_delta")

    sort_columns.append("randomise")
    matched_rows = matched_rows.sort_values(sort_columns)
    matched_rows = matched_rows.head(match_dict["matches_per_case"])
    return matched_rows.index


def get_date_offset(offset_str):
    """
    Parses the string given by match_dict["replace_match_index_date_with_case"]
    to determine the unit and lenght of offset.
    Returns a pr.DateOffset of the appropriate length.
    """
    if offset_str == "no_offset":
        offset = None
    else:
        length = int(offset_str.split("_")[0])
        unit = offset_str.split("_")[1]
        if unit in ("year", "years"):
            offset = pd.DateOffset(years=length)
        elif unit in ("month", "months"):
            offset = pd.DateOffset(months=length)
        elif unit in ("day", "days"):
            offset = pd.DateOffset(days=length)
        else:
            raise Exception(f"Date offset '{unit}' not implemented")
    return offset


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

    indices = pre_calculate_indices(cases, matches, match_dict["match_variables"])

    if "index_date_variable" in match_dict:
        index_date_var = match_dict["index_date_variable"]

    if "replace_match_index_date_with_case" in match_dict:
        offset_str = match_dict["replace_match_index_date_with_case"]
        date_offset = get_date_offset(offset_str)

    if "date_exclusion_variables" in match_dict:
        case_exclusions = date_exclusions(
            cases,
            match_dict["date_exclusion_variables"],
            cases,
            index_date_var,
        )
        cases = cases.loc[~case_exclusions]

    for case_id, case_row in cases.iterrows():
        ## Get eligible matches
        eligible_matches = get_eligible_matches(
            case_row, matches, match_dict["match_variables"], indices
        )
        matched_rows = matches.loc[eligible_matches]

        ## Index date based match exclusions (faster to do this after get_eligible_matches)
        if "date_exclusion_variables" in match_dict:
            exclusions = date_exclusions(
                matched_rows,
                match_dict["date_exclusion_variables"],
                case_row,
                index_date_var,
            )
            matched_rows = matched_rows.loc[~exclusions]

        ## Pick random matches
        matched_rows = greedily_pick_matches(match_dict, matched_rows, case_row)

        ## Label matches with case ID
        matches.loc[matched_rows, "set_id"] = case_id
        ## And cases only if there are matches
        if len(matches.loc[matched_rows, "set_id"]) > 0:
            cases.loc[case_id, "set_id"] = case_id

        ## Set index_date of the match where needed
        if "replace_match_index_date_with_case" in match_dict:
            if offset_str == "no_offset":
                matches.loc[matched_rows, index_date_var] = case_row[index_date_var]
            elif offset_str.split("_")[2] == "earlier":
                matches.loc[matched_rows, index_date_var] = (
                    case_row[index_date_var] - date_offset
                )
            elif offset_str.split("_")[2] == "later":
                matches.loc[matched_rows, index_date_var] = (
                    case_row[index_date_var] + date_offset
                )

    ## Drop unmatched cases/matches
    matched_cases = cases.loc[cases["set_id"] != -9]
    matched_matches = matches.loc[matches["set_id"] != -9]

    ## Write to csvs
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

    return matched_matches
