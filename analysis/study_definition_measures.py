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
    everyone=patients.satisfying("1=1", return_expectations={"incidence": 0.7}),
    covid_hospitalisation=patients.categorised_as(
        {
            "General population": "NOT hospitalised_with_covid",
            "Hospitalised with COVID-19": "hospitalised_with_covid",
            "": "DEFAULT",
        },
        return_expectations={
            "incidence": 0.95,
            "category": {
                "ratios": {
                    "General population": 0.8,
                    "Hospitalised with COVID-19": 0.2,
                }
            },
        },
        hospitalised_with_covid=patients.admitted_to_hospital(
            with_these_diagnoses=covid_codelist,
            between=["2019-01-01", "last_day_of_month(index_date)"],
            return_expectations={"incidence": 0.20},
        ),
    ),
    stroke_ons=patients.with_these_codes_on_death_certificate(
        stroke_hospital,
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.05},
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
    ),
    dvt_ons=patients.with_these_codes_on_death_certificate(
        filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.05},
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
    ),
    pe_ons=patients.with_these_codes_on_death_certificate(
        filter_codes_by_category(vte_codes_hospital, include=["pe"]),
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.05},
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
    ),
    died_stroke=patients.categorised_as(
        {
            "Stroke on death certificate": "stroke_ons",
            "Stroke not on death certificate": "NOT stroke_ons",
            "": "DEFAULT",
        },
        return_expectations={
            "incidence": 0.95,
            "category": {
                "ratios": {
                    "Stroke on death certificate": 0.2,
                    "Stroke not on death certificate": 0.8,
                }
            },
        },
    ),
    died_DVT=patients.categorised_as(
        {
            "DVT on death certificate": "dvt_ons",
            "DVT not on death certificate": "NOT dvt_ons",
            "": "DEFAULT",
        },
        return_expectations={
            "incidence": 0.95,
            "category": {
                "ratios": {
                    "DVT on death certificate": 0.2,
                    "DVT not on death certificate": 0.8,
                }
            },
        },
    ),
    died_PE=patients.categorised_as(
        {
            "PE on death certificate": "pe_ons",
            "PE not on death certificate": "NOT pe_ons",
            "": "DEFAULT",
        },
        return_expectations={
            "incidence": 0.95,
            "category": {
                "ratios": {
                    "PE on death certificate": 0.2,
                    "PE not on death certificate": 0.8,
                }
            },
        },
    ),
    died=patients.died_from_any_cause(
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={"incidence": 0.1},
    ),
)


measures = [
    Measure(
        id="stroke_rate",
        numerator="stroke",
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
        id="died_stroke_rate",
        numerator="died",
        denominator="population",
        group_by=["covid_hospitalisation", "died_stroke"],
    ),
    Measure(
        id="died_DVT_rate",
        numerator="died",
        denominator="population",
        group_by=["covid_hospitalisation", "died_DVT"],
    ),
    Measure(
        id="died_PE_rate",
        numerator="died",
        denominator="population",
        group_by=["covid_hospitalisation", "died_PE"],
    ),
]
