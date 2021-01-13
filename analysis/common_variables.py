from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


common_variables = dict(
    # Outcomes
    # History of outcomes
    recent_dvt=patients.satisfying(
        "recent_dvt_gp OR recent_dvt_hospital",
        recent_dvt_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
        recent_dvt_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
    ),
    recent_pe=patients.satisfying(
        "recent_pe_gp OR recent_pe_hospital",
        recent_pe_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
        recent_pe_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
    ),
    recent_stroke=patients.satisfying(
        "recent_stroke_gp OR recent_stroke_hospital",
        recent_stroke_gp=patients.with_these_clinical_events(
            stroke,
            between=["patient_index_date - 3 months", "patient_index_date"],
            return_expectations={"incidence": 0.05},
        ),
        recent_stroke_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=stroke_hospital,
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
    ),
    recent_mi=patients.satisfying(
        "recent_mi_gp OR recent_mi_hospital",
        recent_mi_gp=patients.with_these_clinical_events(
            mi_codes,
            between=["patient_index_date - 3 months", "patient_index_date"],
            return_expectations={"incidence": 0.05},
        ),
        recent_mi_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                mi_codes_hospital, include=["1"]
            ),
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
    ),
    recent_heart_failure=patients.satisfying(
        "recent_heart_failure_gp OR recent_heart_failure_hospital",
        recent_heart_failure_gp=patients.with_these_clinical_events(
            heart_failure_codes,
            between=["patient_index_date - 3 months", "patient_index_date"],
            return_expectations={"incidence": 0.05},
        ),
        recent_heart_failure_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                heart_failure_codes_hospital, include=["1"]
            ),
            between=["patient_index_date - 3 months", "patient_index_date"],
        ),
    ),
    previous_diabetes=patients.with_these_clinical_events(
        combine_codelists(diabetes_t1_codes, diabetes_t2_codes, diabetes_unknown_codes),
        on_or_before="patient_index_date",
        return_expectations={"incidence": 0.05},
    ),
    ## DVT
    dvt_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_gp, include=["dvt"]),
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    dvt_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(
            vte_codes_hospital, include=["dvt"]
        ),
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    dvt_ons=patients.with_these_codes_on_death_certificate(
        filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    dvt=patients.satisfying("dvt_gp OR dvt_hospital OR dvt_ons"),
    dvt_no_gp=patients.satisfying("dvt_hospital OR dvt_ons"),
    dvt_cens_gp=patients.satisfying(
        "(dvt_gp AND NOT recent_dvt) OR dvt_hospital OR dvt_ons"
    ),
    # dvt_date=patients.minimum_of("dvt_gp", "dvt_hospital", "dvt_ons"),
    # PE
    pe_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_gp, include=["pe"]),
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    pe_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(
            vte_codes_hospital, include=["pe"]
        ),
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    pe_ons=patients.with_these_codes_on_death_certificate(
        filter_codes_by_category(vte_codes_hospital, include=["pe"]),
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    pe=patients.satisfying("pe_gp OR pe_hospital OR pe_ons"),
    pe_no_gp=patients.satisfying("pe_hospital OR pe_ons"),
    pe_cens_gp=patients.satisfying(
        "(pe_gp AND NOT recent_pe) OR pe_hospital OR pe_ons"
    ),
    # pe_date=patients.minimum_of("pe_gp", "pe_hospital", "pe_ons"),
    ## Stroke
    stroke_gp=patients.with_these_clinical_events(
        stroke,
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    stroke_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=stroke_hospital,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    stroke_ons=patients.with_these_codes_on_death_certificate(
        stroke_hospital,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    stroke=patients.satisfying("stroke_gp OR stroke_hospital OR stroke_ons"),
    stroke_no_gp=patients.satisfying("stroke_hospital OR stroke_ons"),
    stroke_cens_gp=patients.satisfying(
        "(stroke_gp AND NOT recent_stroke) OR stroke_hospital OR stroke_ons"
    ),
    # stroke_date=patients.minimum_of("stroke_gp", "stroke_hospital", "stroke_ons"),
    # Acute kidney injury
    aki_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=aki_codes,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    aki_ons=patients.with_these_codes_on_death_certificate(
        aki_codes,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    aki=patients.satisfying("aki_hospital OR aki_ons"),
    # MI
    mi_gp=patients.with_these_clinical_events(
        mi_codes,
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    mi_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(mi_codes_hospital, include=["1"]),
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    mi_ons=patients.with_these_codes_on_death_certificate(
        filter_codes_by_category(mi_codes_hospital, include=["1"]),
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    mi=patients.satisfying("mi_gp OR mi_hospital OR mi_ons"),
    mi_no_gp=patients.satisfying("mi_hospital OR mi_ons"),
    mi_cens_gp=patients.satisfying(
        "(mi_gp AND NOT recent_mi) OR mi_hospital OR mi_ons"
    ),
    # Heart failure
    heart_failure_gp=patients.with_these_clinical_events(
        heart_failure_codes,
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    heart_failure_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(
            heart_failure_codes_hospital, include=["1"]
        ),
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    heart_failure_ons=patients.with_these_codes_on_death_certificate(
        filter_codes_by_category(heart_failure_codes_hospital, include=["1"]),
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    heart_failure=patients.satisfying(
        "heart_failure_gp OR heart_failure_hospital OR heart_failure_ons"
    ),
    heart_failure_no_gp=patients.satisfying(
        "heart_failure_hospital OR heart_failure_ons"
    ),
    heart_failure_cens_gp=patients.satisfying(
        """
          (heart_failure_gp AND NOT recent_heart_failure)
        OR heart_failure_hospital OR heart_failure_ons
        """
    ),
    # Diabetes
    t1dm_gp=patients.with_these_clinical_events(
        diabetes_t1_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t2dm_gp=patients.with_these_clinical_events(
        diabetes_t2_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    unknown_diabetes_gp=patients.with_these_clinical_events(
        diabetes_unknown_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t1dm_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=diabetes_t1_codes_hospital,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t2dm_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=diabetes_t2_codes_hospital,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t1dm_ons=patients.with_these_codes_on_death_certificate(
        diabetes_t1_codes_hospital,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t2dm_ons=patients.with_these_codes_on_death_certificate(
        diabetes_t2_codes_hospital,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    oad_lastyear_meds=patients.with_these_medications(
        oad_med_codes,
        between=["patient_index_date - 1 year", "patient_index_date + 1 days"],
        return_expectations={"incidence": 0.05},
    ),
    insulin_lastyear_meds=patients.with_these_medications(
        insulin_med_codes,
        between=["patient_index_date - 1 year", "patient_index_date + 1 days"],
        return_expectations={"incidence": 0.05},
    ),
    type1_agg=patients.satisfying("t1dm_gp OR t1dm_hospital OR t1dm_ons"),
    type2_agg=patients.satisfying("t2dm_gp OR t2dm_hospital OR t2dm_ons"),
    t1dm=patients.satisfying(
        """
            (type1_agg AND NOT
            type2_agg)
        OR
            (((type1_agg AND type2_agg) OR
            (type1_agg AND unknown_diabetes_gp AND NOT type2_agg) OR
            (unknown_diabetes_gp AND NOT type1_agg AND NOT type2_agg))
            AND
            (insulin_lastyear_meds AND NOT
            oad_lastyear_meds))
        """,
        return_expectations={"incidence": 0.05},
    ),
    t2dm=patients.satisfying(
        """
            (type2_agg AND NOT
            type1_agg)
        OR
            (((type1_agg AND type2_agg) OR
            (type2_agg AND unknown_diabetes_gp AND NOT type1_agg) OR
            (unknown_diabetes_gp AND NOT type1_agg AND NOT type2_agg))
            AND
            (oad_lastyear_meds))
        """,
        return_expectations={"incidence": 0.05},
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
        "2020-02-01",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
            "incidence": 1,
        },
    ),
    stp=patients.registered_practice_as_of(
        "2020-02-01",
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
        "2020-02-01",
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
        "2020-02-01",
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
        return_expectations={"incidence": 0.05},
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
