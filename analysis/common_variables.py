from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def days_before(s, days):
    date = datetime.strptime(s, "%Y-%m-%d")
    modified_date = date - timedelta(days=days)
    return datetime.strftime(modified_date, "%Y-%m-%d")


def common_variable_define(start_jan, prev_nov, prev_dec, start_date, start_mar, start_apr, start_may, start_jun, start_jul, start_aug, start_sep, start_oct, end_date):
    common_variables = dict(
		af=patients.with_these_clinical_events(
            af_codes,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
        ),
		# 3mth hist of doac/warfarin use
		anticoag_rx_prev_nov=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[prev_nov, prev_dec],
			return_expectations={
                "date": {"earliest": prev_nov},
            }
		),
		anticoag_rx_prev_dec=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[prev_dec, start_jan],
			return_expectations={
                "date": {"earliest": prev_dec},
            }	
		),
		anticoag_rx_jan=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_jan, start_date],
			return_expectations={
                "date": {"earliest": start_jan},
            }
        ),
		anticoag_rx_feb=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_date, start_mar],
			return_expectations={
                "date": {"earliest": start_date},
            }
        ),
		anticoag_rx_mar=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_mar, start_apr],
			return_expectations={
                "date": {"earliest": start_mar},
            }
        ),
		anticoag_rx_apr=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_apr, start_may],
			return_expectations={
                "date": {"earliest": start_apr},
            }
        ),
		anticoag_rx_may=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_may, start_jun],
			return_expectations={
                "date": {"earliest": start_may},
            }
        ),		
		anticoag_rx_jun=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_jun, start_jul],
			return_expectations={
                "date": {"earliest": start_jun},
            }
        ),	
		anticoag_rx_jul=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_jul, start_aug],
			return_expectations={
                "date": {"earliest": start_jul},
            }
        ),	
		anticoag_rx_aug=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_aug, start_sep],
			return_expectations={
                "date": {"earliest": start_aug},
            }
        ),	
		anticoag_rx_sep=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_sep, start_oct],
			return_expectations={
                "date": {"earliest": start_sep},
            }
        ),	
		anticoag_rx_oct=patients.with_these_medications(
           combine_codelists(doac_codes,
                             warfarin_codes),
            return_first_date_in_period=True,
            between=[start_oct, end_date],
			return_expectations={
                "date": {"earliest": start_oct},
            }
        ),
        dvt_gp_feb=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_date,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
		dvt_gp_mar=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_mar,
            return_expectations={
                "date": {"earliest": start_mar},
            },
        ),
		dvt_gp_apr=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_apr,
            return_expectations={
                "date": {"earliest": start_apr},
            },
        ),
		dvt_gp_may=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_may,
            return_expectations={
                "date": {"earliest": start_may},
            },
        ),	
		dvt_gp_jun=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_jun,
            return_expectations={
                "date": {"earliest": start_jun},
            },
        ),
		dvt_gp_jul=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_jul,
            return_expectations={
                "date": {"earliest": start_jul},
            },
        ),
		dvt_gp_aug=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_aug,
            return_expectations={
                "date": {"earliest": start_aug},
            },
        ),
		dvt_gp_sep=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_sep,
            return_expectations={
                "date": {"earliest": start_sep},
            },
        ),
		dvt_gp_oct=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_oct,
            return_expectations={
                "date": {"earliest": start_oct},
            },
        ),
        pe_gp_feb=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_date,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
		pe_gp_mar=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_mar,
            return_expectations={
                "date": {"earliest": start_mar},
            },
        ),
		pe_gp_apr=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_apr,
            return_expectations={
                "date": {"earliest": start_apr},
            },
        ),
		pe_gp_may=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_may,
            return_expectations={
                "date": {"earliest": start_may},
            },
        ),	
		pe_gp_jun=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_jun,
            return_expectations={
                "date": {"earliest": start_jun},
            },
        ),
		pe_gp_jul=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_jul,
            return_expectations={
                "date": {"earliest": start_jul},
            },
        ),
		pe_gp_aug=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_aug,
            return_expectations={
                "date": {"earliest": start_aug},
            },
        ),
		pe_gp_sep=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_sep,
            return_expectations={
                "date": {"earliest": start_sep},
            },
        ),
		pe_gp_oct=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_oct,
            return_expectations={
                "date": {"earliest": start_oct},
            },
        ),
        previous_vte_gp=patients.with_these_clinical_events(
            vte_codes_gp,
            returning="date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        previous_pe_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["pe"]),
            returning="date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        previous_pe_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        previous_dvt_gp=patients.with_these_clinical_events(
            filter_codes_by_category(vte_codes_gp, include=["dvt"]),
            returning="date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        previous_dvt_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        dvt_hospital_feb=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_date,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
        dvt_hospital_mar=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_mar,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_mar},
            },
        ),	
		dvt_hospital_apr=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_apr,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_apr},
            },
        ),	
		dvt_hospital_may=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_may,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_may},
            },
        ),	
		dvt_hospital_jun=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_jun,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_jun},
            },
        ),	
		dvt_hospital_jul=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_jul,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_jul},
            },
        ),	
		dvt_hospital_aug=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_aug,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_aug},
            },
        ),	
		dvt_hospital_sep=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_sep,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_sep},
            },
        ),	
		dvt_hospital_oct=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["dvt"]
            ),  # optional
            on_or_after=start_oct,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_oct},
            },
        ),	
        pe_hospital_feb=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_date,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
        pe_hospital_mar=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_mar,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_mar},
            },
        ),	
		pe_hospital_apr=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_apr,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_apr},
            },
        ),	
		pe_hospital_may=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_may,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_may},
            },
        ),	
		pe_hospital_jun=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_jun,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_jun},
            },
        ),	
		pe_hospital_jul=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_jul,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_jul},
            },
        ),	
		pe_hospital_aug=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_aug,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_aug},
            },
        ),	
		pe_hospital_sep=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_sep,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_sep},
            },
        ),	
		pe_hospital_oct=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["pe"]
            ),  # optional
            on_or_after=start_oct,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_oct},
            },
        ),	
        other_vte_hospital=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=filter_codes_by_category(
                vte_codes_hospital, include=["other"]
            ),  # optional
            on_or_after=start_date,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
        dvt_ons_feb=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_date,
            return_expectations={"date": {"earliest": start_date}},
        ),
		dvt_ons_mar=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_mar,
            return_expectations={"date": {"earliest": start_mar}},
        ),
		dvt_ons_apr=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_apr,
            return_expectations={"date": {"earliest": start_apr}},
        ),
		dvt_ons_may=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_may,
            return_expectations={"date": {"earliest": start_may}},
        ),
		dvt_ons_jun=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_jun,
            return_expectations={"date": {"earliest": start_jun}},
        ),
		dvt_ons_jul=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_jul,
            return_expectations={"date": {"earliest": start_jul}},
        ),
		dvt_ons_aug=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_aug,
            return_expectations={"date": {"earliest": start_aug}},
        ),
		dvt_ons_sep=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_sep,
            return_expectations={"date": {"earliest": start_sep}},
        ),
		dvt_ons_oct=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["dvt"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_oct,
            return_expectations={"date": {"earliest": start_oct}},
        ),
				
        pe_ons_feb=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_date,
            return_expectations={"date": {"earliest": start_date}},
        ),
		pe_ons_mar=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_mar,
            return_expectations={"date": {"earliest": start_mar}},
        ),
		pe_ons_apr=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_apr,
            return_expectations={"date": {"earliest": start_apr}},
        ),
		pe_ons_may=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_may,
            return_expectations={"date": {"earliest": start_may}},
        ),
		pe_ons_jun=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_jun,
            return_expectations={"date": {"earliest": start_jun}},
        ),
		pe_ons_jul=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_jul,
            return_expectations={"date": {"earliest": start_jul}},
        ),
		pe_ons_aug=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_aug,
            return_expectations={"date": {"earliest": start_aug}},
        ),
		pe_ons_sep=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_sep,
            return_expectations={"date": {"earliest": start_sep}},
        ),
		pe_ons_oct=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["pe"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_oct,
            return_expectations={"date": {"earliest": start_oct}},
        ),
				
        other_vte_ons=patients.with_these_codes_on_death_certificate(
            filter_codes_by_category(vte_codes_hospital, include=["other"]),
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_date,
            return_expectations={"date": {"earliest": start_date}},
        ),
        previous_vte_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=vte_codes_hospital,
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        stroke_gp_feb=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_date,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
		stroke_gp_mar=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_mar,
            return_expectations={
                "date": {"earliest": start_mar},
            },
        ),
		stroke_gp_apr=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_apr,
            return_expectations={
                "date": {"earliest": start_apr},
            },
        ),
		stroke_gp_may=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_may,
            return_expectations={
                "date": {"earliest": start_may},
            },
        ),	
		stroke_gp_jun=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_jun,
            return_expectations={
                "date": {"earliest": start_jun},
            },
        ),
		stroke_gp_jul=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_jul,
            return_expectations={
                "date": {"earliest": start_jul},
            },
        ),
		stroke_gp_aug=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_aug,
            return_expectations={
                "date": {"earliest": start_aug},
            },
        ),
		stroke_gp_sep=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_sep,
            return_expectations={
                "date": {"earliest": start_sep},
            },
        ),
		stroke_gp_oct=patients.with_these_clinical_events(
           stroke,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_oct,
            return_expectations={
                "date": {"earliest": start_oct},
            },
        ),
		stroke_hospital_feb=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_date,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_date},
            },
        ),
        stroke_hospital_mar=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_mar,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_mar},
            },
        ),	
		stroke_hospital_apr=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_apr,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_apr},
            },
        ),	
		stroke_hospital_may=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_may,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_may},
            },
        ),	
		stroke_hospital_jun=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_jun,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_jun},
            },
        ),	
		stroke_hospital_jul=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_jul,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_jul},
            },
        ),	
		stroke_hospital_aug=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_aug,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_aug},
            },
        ),	
		stroke_hospital_sep=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_sep,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_sep},
            },
        ),	
		stroke_hospital_oct=patients.admitted_to_hospital(
            returning="date_admitted",
            with_these_diagnoses=stroke_hospital,
            on_or_after=start_oct,
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "date": {"earliest": start_oct},
            },
        ),	
		stroke_ons_feb=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_date,
            return_expectations={"date": {"earliest": start_date}},
        ),
		stroke_ons_mar=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_mar,
            return_expectations={"date": {"earliest": start_mar}},
        ),
		stroke_ons_apr=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_apr,
            return_expectations={"date": {"earliest": start_apr}},
        ),
		stroke_ons_may=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_may,
            return_expectations={"date": {"earliest": start_may}},
        ),
		stroke_ons_jun=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_jun,
            return_expectations={"date": {"earliest": start_jun}},
        ),
		stroke_ons_jul=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_jul,
            return_expectations={"date": {"earliest": start_jul}},
        ),
		stroke_ons_aug=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_aug,
            return_expectations={"date": {"earliest": start_aug}},
        ),
		stroke_ons_sep=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_sep,
            return_expectations={"date": {"earliest": start_sep}},
        ),
		stroke_ons_oct=patients.with_these_codes_on_death_certificate(
            stroke_hospital,
            returning="date_of_death",
            match_only_underlying_cause=False,
            on_or_after=start_oct,
            return_expectations={"date": {"earliest": start_oct}},
        ),		
        previous_stroke_gp=patients.with_these_clinical_events(
            stroke,
            returning="date",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        previous_stroke_hospital=patients.admitted_to_hospital(
            with_these_diagnoses=stroke_hospital,
            returning="date_admitted",
            date_format="YYYY-MM-DD",
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.05,
            },
        ),
        died_date_ons=patients.died_from_any_cause(
            on_or_after=start_date,
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            return_expectations={"date": {"earliest": start_date}},
        ),
        age=patients.age_as_of(
            start_date,
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
            on_or_before=days_before(start_date, 1),
            return_expectations={
                "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
                "incidence": 0.75,
            },
        ),
        bmi=patients.most_recent_bmi(
            on_or_after=days_before(start_date, 3653),
            minimum_age_at_measurement=16,
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "incidence": 0.6,
                "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            },
        ),
        smoking_status=patients.categorised_as(
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
                on_or_before=days_before(start_date, 1),
                returning="category",
            ),
            ever_smoked=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                on_or_before=days_before(start_date, 1),
            ),
            smoked_last_18_months=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S"]),
                between=[days_before(start_date, 548), start_date],
            ),
        ),
        hypertension=patients.with_these_clinical_events(
            hypertension_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        # heart failure
        # other heart disease
        diabetes=patients.with_these_clinical_events(
            diabetes_codes,
            return_first_date_in_period=True,
            include_month=True,
        ),
        hba1c_mmol_per_mol_1=patients.with_these_clinical_events(
            hba1c_new_codes,
            find_last_match_in_period=True,
            between=[days_before(start_date, 730), start_date],
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
            between=[days_before(start_date, 730), start_date],
            returning="numeric_value",
            include_date_of_match=False,
            return_expectations={
                "float": {"distribution": "normal", "mean": 5, "stddev": 2},
                "incidence": 0.95,
            },
        ),
        practice_id=patients.registered_practice_as_of(
            start_date,
            returning="pseudo_id",
            return_expectations={
                "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
                "incidence": 1,
            },
        ),
        stp=patients.registered_practice_as_of(
            start_date,
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
            start_date,
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
            start_date,
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
            return_expectations={
                "rate": "universal",
                "category": {
                    "ratios": {
                        "100": 0.1,
                        "200": 0.2,
                        "300": 0.3,
                        "400": 0.1,
                        "500": 0.1,
                        "600": 0.1,
                        "700": 0.1,
                    }
                },
            },
        ),
    )
    return common_variables
