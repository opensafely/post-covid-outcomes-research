from match import match

pneumonia = {
    "case_csv": "input_covid",
    "match_csv": "input_pneumonia",
    "matches_per_case": 1,
    "match_variables": {
        "sex": "category",
        "age": 5,
        "stp": "category",
        "indexdate": "month_only",
    },
    "index_date_variable": "indexdate",
    "date_exclusion_variables": {
        "previous_vte_gp": "before",
        "previous_vte_hospital": "before",
        "previous_stroke_gp": "before",
        "previous_stroke_hospital": "before",
    },
}
match(pneumonia)
control_2019 = {
    "case_csv": "input_covid",
    "match_csv": "input_control_2019",
    "matches_per_case": 2,
    "match_variables": {"sex": "category", "age": 5, "stp": "category",},
    "replace_match_index_date_with_case": True,
    "index_date_variable": "indexdate",
    "date_exclusion_variables": {
        "previous_vte_gp": "before",
        "previous_vte_hospital": "before",
        "previous_stroke_gp": "before",
        "previous_stroke_hospital": "before",
    },
}
match(control_2019)
control_2020 = {
    "case_csv": "input_covid",
    "match_csv": "input_control_2020",
    "matches_per_case": 2,
    "match_variables": {"sex": "category", "age": 5, "stp": "category",},
    "replace_match_index_date_with_case": True,
    "index_date_variable": "indexdate",
    "date_exclusion_variables": {
        "previous_vte_gp": "before",
        "previous_vte_hospital": "before",
        "previous_stroke_gp": "before",
        "previous_stroke_hospital": "before",
    },
}
match(control_2020)
