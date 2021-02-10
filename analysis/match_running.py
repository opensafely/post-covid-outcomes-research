import pandas as pd
from osmatching import match


gen_pop_df = pd.read_csv("output/input_general_population.csv")
gen_pop_df["patient_index_date"] = "2019-02-01"
gen_pop_df.to_csv("output/input_general_population_with_index_date.csv", index=False)

match(
    case_csv="input_covid",
    match_csv="input_general_population_with_index_date",
    matches_per_case=5,
    match_variables={
        "sex": "category",
        "age": 1,
        "stp": "category",
    },
    closest_match_variables=["age"],
    index_date_variable="patient_index_date",
    output_suffix="_general_population",
    output_path="output",
)
