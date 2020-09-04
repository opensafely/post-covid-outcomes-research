from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv
from common_variables import common_variables
from codelists import *


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
        AND hospitalised_covid
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2019-02-01", "2020-02-01"
        ),
    ),
    hospitalised_covid=patients.admitted_to_hospital(
        returning="date_admitted",
        # with_these_diagnoses=covid_codelist,  # optional
        on_or_after="2020-02-01",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-03-01"},
            "category": {"ratios": {"I21": 0.5, "C34": 0.5}},
        },
    ),
    **common_variables
)
