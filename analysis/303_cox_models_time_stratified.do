********************************************************************************
*
*	Do-file:		202_cox_models.do
*
*	Programmed by:	John & Alex
*
*	Data used:		None
*
*	Data created:   None
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			
********************************************************************************

clear
do `c(pwd)'/analysis/global.do

cap log close
log using $outdir/cox_models_time_strat.txt, replace t

tempname measures
	postfile `measures' ///
		str20(comparator) str20(outcome) str25(analysis) str10(adjustment) str10(time) hr lc uc ///
		using $tabfigdir/cox_model_summary_time_strat, replace
		
foreach an in pneumonia gen_population {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

global crude i.case
global age_sex i.case i.male age1 age2 age3

global full i.case i.male age1 age2 age3 i.stp i.ethnicity i.imd i.obese4cat_withmiss /// 
	i.smoke htdiag chronic_respiratory_disease i.asthmacat chronic_cardiac_disease ///
	i.diabcat i.cancer_exhaem_cat i.cancer_haem_cat i.reduced_kidney_function_cat2  ///
	i.chronic_liver_disease  i.dementia i.other_neuro i.organ_transplant i.spleen ///
	i.ra_sle_psoriasis i.other_immunosuppression i.hist_dvt i.hist_pe i.hist_stroke i.hist_mi i.hist_aki i.hist_heart_failure	
	


foreach v in stroke dvt pe heart_failure mi aki t2dm {

	
	noi di "Starting analysis for `v' Outcome ..." 
	
	preserve
	
	local out `v'_cens_gp
	local end_date `v'_cens_gp_end_date
	
	* Apply exclusion for AKI and diabetes outcomes 
	if "`v'" == "t2dm" {
	drop if previous_diabetes == 1
	local out `v'
	local end_date `v'_end_date
	}	
	
	if "`v'" == "aki" {
	drop if aki_exclusion_flag == 1
	local out `v'_cens_gp
	local end_date `v'_cens_gp_end_date
	}

		noi di "$group: stset in `a'" 
		
		stset `end_date' , id(new_patient_id) failure(`out') enter(indexdate)  origin(indexdate)
		
		* STSPLIT 
		stsplit time , at(30(30)120)
		
		
		foreach adjust in full {
		    
			if "`adjust'" == "full" & "`v'" == "t2dm" {
			* remove diabetes
	global full i.case i.male age1 age2 age3 i.stp i.ethnicity i.imd i.obese4cat_withmiss /// 
	i.smoke htdiag chronic_respiratory_disease i.asthmacat chronic_cardiac_disease ///
	 i.cancer_exhaem_cat i.cancer_haem_cat i.reduced_kidney_function_cat2  ///
	i.chronic_liver_disease i.dementia i.other_neuro i.organ_transplant i.spleen ///
	i.ra_sle_psoriasis i.other_immunosuppression i.hist_dvt i.hist_pe i.hist_stroke i.hist_mi i.hist_aki i.hist_heart_failure	
			}
				forvalues t = 0(30)120 {
			stcox $`adjust' if time == `t' , vce(robust)
			matrix b = r(table)
			local hr= b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]
			
			estat phtest, detail
		
			post `measures'  ("`an'") ("`v'") ("`out'") ("`adjust'") ("`t'") ///
							(`hr') (`lc') (`uc')
			}
		}
restore		
}
		
}


postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_summary_time_strat, replace

export delimited using $tabfigdir/cox_model_summary_time_strat.csv, replace

log close
