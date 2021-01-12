from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
)
from codelists import *


study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.05,
    },
    index_date="2019-02-01",
    population=patients.satisfying(
        """
            has_follow_up
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        AND NOT stp = ""
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 1 year", "index_date"
        ),
        age=patients.age_as_of(
            "index_date",
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
        imd=patients.address_as_of(
            "index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {"100": 0.1, "200": 0.1}},
            },
        ),
        stp=patients.registered_practice_as_of(
            "index_date",
            returning="stp_code",
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {"STP1": 0.1, "STP2": 0.1}},
            },
        ),
    ),
    everyone=patients.satisfying("1=1", return_expectations={"incidence": 1}),
    covid_hospitalisation=patients.categorised_as(
        {
            "COVID-19 positive": "covid_positive AND NOT covid_hospitalised",
            "COVID-19 hospitalised": "covid_hospitalised",
            "General population": "DEFAULT",
        },
        return_expectations={
            "incidence": 1,
            "category": {
                "ratios": {
                    "COVID-19 positive": 0.1,
                    "COVID-19 hospitalised": 0.1,
                    "General population": 0.8,
                }
            },
        },
        covid_positive=patients.with_test_result_in_sgss(
            pathogen="SARS-CoV-2",
            test_result="positive",
            between=["2020-01-01", "last_day_of_month(index_date)"],
            date_format="YYYY-MM-DD",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        covid_hospitalised=patients.admitted_to_hospital(
            with_these_diagnoses=covid_codelist,
            between=["2020-01-01", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.20},
        ),
    ),
    stroke=patients.satisfying(
        "stroke_gp OR stroke_hospital OR stroke_ons",
        stroke_gp=patients.with_these_clinical_events(
            stroke,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        stroke_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=stroke_hospital,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        stroke_ons=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    DVT=patients.satisfying(
        "dvt_gp OR dvt_hospital OR dvt_ons",
        dvt_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        dvt_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        dvt_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    PE=patients.satisfying(
        "pe_gp OR pe_hospital OR pe_ons",
        pe_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        pe_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        pe_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    AKI=patients.satisfying(
        "aki_hospital OR aki_ons",
        aki_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=aki_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        aki_ons=patients.with_these_codes_on_death_certificate(
            aki_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    MI=patients.satisfying(
        "mi_gp OR mi_hospital OR mi_ons",
        mi_gp=patients.with_these_clinical_events(
            mi_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        mi_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                mi_codes_hospital, include=["1"]
            ),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        mi_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(mi_codes_hospital, include=["1"]),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    heart_failure=patients.satisfying(
        "heart_failure_gp OR heart_failure_hospital OR heart_failure_ons",
        heart_failure_gp=patients.with_these_clinical_events(
            heart_failure_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        heart_failure_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                heart_failure_codes_hospital, include=["1"]
            ),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        heart_failure_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(heart_failure_codes_hospital, include=["1"]),
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    ketoacidosis=patients.satisfying(
        "ketoacidosis_hospital OR ketoacidosis_ons",
        ketoacidosis_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=ketoacidosis_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
        ketoacidosis_ons=patients.with_these_codes_on_death_certificate(
            ketoacidosis_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.05},
        ),
    ),
    died=patients.died_from_any_cause(
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.1},
    ),
)


measures = [
    Measure(
        id="died_rate",
        numerator="died",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="DVT_rate",
        numerator="DVT",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="PE_rate",
        numerator="PE",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="stroke_rate",
        numerator="stroke",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="MI_rate",
        numerator="MI",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="heart_failure_rate",
        numerator="heart_failure",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="AKI_rate",
        numerator="AKI",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
    Measure(
        id="ketoacidosis_rate",
        numerator="ketoacidosis",
        denominator="population",
        group_by=["covid_hospitalisation"],
    ),
]
