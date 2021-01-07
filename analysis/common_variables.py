from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def common_variable_define(dynamic_date_variables):
    common_variables = dict(
        # Outcomes
        ## DVT
        dvt_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after="patient_index_date",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        dvt_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),
            on_or_after="patient_index_date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        dvt_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            match_only_underlying_cause=False,
            on_or_after="patient_index_date",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        dvt=patients.satisfying("dvt_gp OR dvt_hospital OR dvt_ons"),
        # dvt_date=patients.minimum_of("dvt_gp", "dvt_hospital", "dvt_ons"),
        # PE
        pe_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after="patient_index_date",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        pe_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),
            on_or_after="patient_index_date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        pe_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            match_only_underlying_cause=False,
            on_or_after="patient_index_date",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        pe=patients.satisfying("pe_gp OR pe_hospital OR pe_ons"),
        # pe_date=patients.minimum_of("pe_gp", "pe_hospital", "pe_ons"),
        ## Stroke
        stroke_gp=patients.with_these_clinical_events(
            stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after="patient_index_date",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        stroke_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after="patient_index_date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        stroke_ons=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            match_only_underlying_cause=False,
            on_or_after="patient_index_date",
            return_expectations={"date": {"earliest": "index_date"}},
        ),
        stroke=patients.satisfying("stroke_gp OR stroke_hospital OR stroke_ons"),
        # stroke_date=patients.minimum_of("stroke_gp", "stroke_hospital", "stroke_ons"),
        # History of outcomes
        previous_dvt=patients.categorised_as(
            {
                "0": "DEFAULT",
                "1": """
                            (historic_dvt_gp OR historic_dvt_hospital) 
                    AND NOT (recent_dvt_gp OR recent_dvt_hospital)
                    """,
                "2": "recent_dvt_gp OR recent_dvt_hospital",
            },
            return_expectations={
                "category": {"ratios": {"0": 0.7, "1": 0.1, "2": 0.2}}
            },
            historic_dvt_gp=patients.with_these_clinical_events(
                filter_codes_by_category(vte_codes_gp, include=["dvt"]),
                on_or_before="patient_index_date - 3 months",
            ),
            recent_dvt_gp=patients.with_these_clinical_events(
                filter_codes_by_category(vte_codes_gp, include=["dvt"]),
                between=["patient_index_date - 3 months", "patient_index_date"],
            ),
            historic_dvt_hospital=patients.admitted_to_hospital(
                with_these_diagnoses=filter_codes_by_category(
                    vte_codes_hospital, include=["dvt"]
                ),
                on_or_before="patient_index_date - 3 months",
            ),
            recent_dvt_hospital=patients.admitted_to_hospital(
                with_these_diagnoses=filter_codes_by_category(
                    vte_codes_hospital, include=["dvt"]
                ),
                between=["patient_index_date - 3 months", "patient_index_date"],
            ),
        ),
        previous_pe=patients.categorised_as(
            {
                "0": "DEFAULT",
                "1": """
                            (historic_pe_gp OR historic_pe_hospital) 
                    AND NOT (recent_pe_gp OR recent_pe_hospital)
                    """,
                "2": "recent_pe_gp OR recent_pe_hospital",
            },
            return_expectations={
                "category": {"ratios": {"0": 0.7, "1": 0.1, "2": 0.2}}
            },
            historic_pe_gp=patients.with_these_clinical_events(
                filter_codes_by_category(vte_codes_gp, include=["pe"]),
                on_or_before="patient_index_date - 3 months",
            ),
            recent_pe_gp=patients.with_these_clinical_events(
                filter_codes_by_category(vte_codes_gp, include=["pe"]),
                between=["patient_index_date - 3 months", "patient_index_date"],
            ),
            historic_pe_hospital=patients.admitted_to_hospital(
                with_these_diagnoses=filter_codes_by_category(
                    vte_codes_hospital, include=["pe"]
                ),
                on_or_after="patient_index_date - 3 months",
            ),
            recent_pe_hospital=patients.admitted_to_hospital(
                with_these_diagnoses=filter_codes_by_category(
                    vte_codes_hospital, include=["pe"]
                ),
                between=["patient_index_date - 3 months", "patient_index_date"],
            ),
        ),
        previous_stroke=patients.categorised_as(
            {
                "0": "DEFAULT",
                "1": """
                            (historic_pe_gp OR historic_pe_hospital) 
                    AND NOT (recent_pe_gp OR recent_pe_hospital)
                    """,
                "2": "recent_pe_gp OR recent_pe_hospital",
            },
            return_expectations={
                "category": {"ratios": {"0": 0.7, "1": 0.1, "2": 0.2}}
            },
            historic_stroke_gp=patients.with_these_clinical_events(
                stroke,
                on_or_after="patient_index_date - 3 months",
            ),
            recent_stroke_gp=patients.with_these_clinical_events(
                stroke,
                between=["patient_index_date - 3 months", "patient_index_date"],
                return_expectations={"incidence": 0.05},
            ),
            historic_stroke_hospital=patients.admitted_to_hospital(
                with_these_diagnoses=stroke_hospital,
                on_or_after="patient_index_date - 3 months",
            ),
            recent_stroke_hospital=patients.admitted_to_hospital(
                with_these_diagnoses=stroke_hospital,
                between=["patient_index_date - 3 months", "patient_index_date"],
            ),
        ),
        died_date_ons=patients.died_from_any_cause(
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            return_expectations={
                "date": {"earliest": "index_date"},
                "incidence": 0.1,
            },
        ),
        age=patients.age_as_of(
            "patient_index_date",
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
            on_or_before="patient_index_date",
            return_expectations={
                "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
                "incidence": 0.75,
            },
        ),
        practice_id=patients.registered_practice_as_of(
            "patient_index_date",
            returning="pseudo_id",
            return_expectations={
                "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
                "incidence": 1,
            },
        ),
        stp=patients.registered_practice_as_of(
            "patient_index_date",
            returning="stp_code",
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "STP1": 0.1,
                        "STP2": 0.1,
                        "STP3": 0.1,
                        "STP4": 0.1,
                        "STP5": 0.1,
                        "STP6": 0.1,
                        "STP7": 0.1,
                        "STP8": 0.1,
                        "STP9": 0.1,
                        "STP10": 0.1,
                    }
                },
            },
        ),
        region=patients.registered_practice_as_of(
            "patient_index_date",
            returning="nuts1_region_name",
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "North East": 0.1,
                        "North West": 0.1,
                        "Yorkshire and The Humber": 0.1,
                        "East Midlands": 0.1,
                        "West Midlands": 0.1,
                        "East": 0.1,
                        "London": 0.2,
                        "South East": 0.1,
                        "South West": 0.1,
                    },
                },
            },
        ),
        imd=patients.address_as_of(
            "patient_index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "100": 0.1,
                        "200": 0.1,
                        "300": 0.1,
                        "400": 0.1,
                        "500": 0.1,
                        "600": 0.1,
                        "700": 0.1,
                        "800": 0.1,
                        "900": 0.1,
                        "1000": 0.1,
                    }
                },
            },
        ),
        af=patients.with_these_clinical_events(
            af_codes,
            on_or_before="patient_index_date",
        ),
        anticoag_rx=patients.with_these_medications(
            combine_codelists(doac_codes, warfarin_codes),
            between=["patient_index_date - 3 months", "patient_index_date"],
            return_expectations={
                "date": {
                    "earliest": "index_date - 3 months",
                    "latest": "index_date",
                }
            },
        ),
        creatinine=patients.with_these_clinical_events(
            creatinine_codes,
            find_last_match_in_period=True,
            on_or_before="patient_index_date",
            returning="numeric_value",
            include_date_of_match=True,
            include_month=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
                "date": {"earliest": "2019-02-28", "latest": "2020-02-29"},
                "incidence": 0.95,
            },
        ),
        dialysis=patients.with_these_clinical_events(
            dialysis_codes,
            on_or_before="patient_index_date",
            return_first_date_in_period=True,
            include_month=True,
        ),
    )
    return common_variables
