from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv, combine_codelists
from common_variables import common_variable_define
from codelists import *


prev_3mths_start = "2019-11-01"
start_date = "2020-02-01"
start_mar  = "2020-03-01"
start_apr  = "2020-04-01"
start_may  = "2020-05-01"
start_jun  = "2020-06-01"
start_jul  = "2020-07-01"
start_aug  = "2020-08-01"
start_sep  = "2020-09-01"
start_oct  = "2020-10-01"
end_date  = "2020-11-01"

common_variables = common_variable_define(prev_3mths_start, start_date, start_mar, start_apr, start_may, start_jun, start_jul, start_aug, start_sep, start_oct, end_date)

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "exponential_increase",
        "incidence": 0.7,
    },
    population=patients.satisfying(
        """
            has_follow_up
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
		AND NOT stp = ""
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2019-02-01", "2020-02-01"
        ),
    ),
    **common_variables
)
