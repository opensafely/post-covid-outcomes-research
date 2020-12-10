from match import match
from sys import argv

matching_dict = {
    "control_2019": {
        "match_csv": "input_control_2019",
        "replace_match_index_date_with_case": "1_year_earlier",
        "date_exclusion_variables": {"died_date_ons": "before"},
    },
    "control_2020": {
        "match_csv": "input_control_2020",
        "replace_match_index_date_with_case": "no_offset",
        "date_exclusion_variables": {"died_date_ons": "before"},
    },
}


match(
    case_csv="input_covid",
    matches_per_case=5,
    match_variables={
        "sex": "category",
        "age": 1,
        "stp": "category",
    },
    closest_match_variables=["age"],
    index_date_variable="exposure_discharge",
    output_suffix=f"_{argv[1]}",
    output_path="output",
    **matching_dict[argv[1]],
)
