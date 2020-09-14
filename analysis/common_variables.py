from cohortextractor import filter_codes_by_category, patients
from codelists import *


common_variables = dict(
    dvt=patients.with_these_clinical_events(
        placeholder_codelist, return_first_date_in_period=True, date_format == "YYYY-MM-DD",
    ),
    pe=patients.with_these_clinical_events(
        placeholder_codelist, return_first_date_in_period=True, include_month=True,
    ),
    stroke=patients.with_these_clinical_events(
        stroke, return_first_date_in_period=True, include_month=True,
    ),
    age=patients.age_as_of(
        "2020-02-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        on_or_before="2020-03-01",
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
        },
    ),
    smoking_status_1=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S' OR smoked_last_18_months",
            "E": """
                 (most_recent_smoking_code = 'E' OR (
                   most_recent_smoking_code = 'N' AND ever_smoked
                   )
                 ) AND NOT smoked_last_18_months
            """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="2020-03-01",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="2020-03-01",
        ),
        smoked_last_18_months=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S"]),
            between=["2018-09-01", "2020-03-01"],
        ),
    ),
    hypertension=patients.with_these_clinical_events(
        hypertension_codes,
        return_first_date_in_period=True,
        on_or_before="2020-06-08",
        include_month=True,
    ),
    # heart failure
    # other heart disease
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        on_or_before="2020-06-08",
        return_first_date_in_period=True,
        include_month=True,
    ),
    hba1c_mmol_per_mol_1=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        between=["2018-12-01", "2020-03-01"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),
    hba1c_percentage_1=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        between=["2018-12-01", "2020-03-01"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    stp=patients.registered_practice_as_of(
        "2020-02-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"STP1": 0.5, "STP2": 0.5}},
        },
    ),
    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),
)
