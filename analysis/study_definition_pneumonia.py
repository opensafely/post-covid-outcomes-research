from cohortextractor import (
    StudyDefinition,
    patients,
    codelist,
    codelist_from_csv,
    combine_codelists,
)
from common_variables import common_variable_define
from codelists import *

dynamic_date_variables = dict(
    index_date="2019-02-01",
    patient_index_date=patients.admitted_to_hospital(
        returning="date_discharged",
        with_these_diagnoses=pneumonia_codelist,
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
)

common_variables = common_variable_define(dynamic_date_variables)

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.7,
    },
    population=patients.satisfying(
        """
            has_follow_up
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        AND exposure_hospitalisation
        AND NOT stp = ""
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "patient_index_date - 1 year", "patient_index_date"
        ),
    ),
    exposure_hospitalisation=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=pneumonia_codelist,
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    exposure_hosp_primary_dx=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_primary_diagnoses=pneumonia_codelist,
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    date_icu_admission=patients.admitted_to_icu(
        find_first_match_in_period=True,
        on_or_after="index_date",
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    **dynamic_date_variables,
    **common_variables
)
