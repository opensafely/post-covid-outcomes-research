from cohortextractor import patients
from common_variables import study

study.population = patients.satisfying(
    """
        registration_history
    AND hospitalised_covid
    """,
    registration_history=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
    ),
    hospitalised_covid=patients.admitted_to_hospital(
        returning="primary_diagnosis",
        # with_these_diagnoses=pneumonia_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "2020-03-01"},
            "category": {"ratios": {"I21": 0.5, "C34": 0.5}},
        },
    ),
)
study.covid_admission_discharge_date = patients.admitted_to_hospital(
    returning="date_discharged",  # defaults to "binary_flag"
    # with_these_diagnoses=pneumonia_codelist,  # optional
    on_or_after="2020-02-01",
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={"date": {"earliest": "2020-03-01"}},
)
