********************************************************************************
*
*	Do-file:		302_competing_events.do
*
*	Programmed by:	John 
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
log using $outdir/competing_events.txt, replace t

tempname measures
	postfile `measures' ///
		str20(comparator) str20(outcome) str25(analysis) str10(adjustment) ptime_covid num_events_covid rate_covid /// 
		ptime_comparator num_events_comparator rate_comparator hr lc uc ///
		using $tabfigdir/cox_model_summary, replace
		
foreach an in pneumonia gen_population {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

global crude i.case
global age_sex i.case i.male age1 age2 age3

global full i.case i.male age1 age2 age3 i.stp i.ethnicity i.imd i.obese4cat /// 
	i.smoke htdiag chronic_respiratory_disease i.asthmacat chronic_cardiac_disease ///
	i.diabcat i.cancer_exhaem_cat i.cancer_haem_cat i.reduced_kidney_function_cat2  ///
	chronic_liver_disease stroke dementia other_neuro organ_transplant spleen ///
	ra_sle_psoriasis other_immunosuppression hist_dvt hist_pe hist_stroke hist_mi hist_aki hist_heart_failure	///
	


foreach v in stroke dvt pe heart_failure mi aki t2dm {

	
	noi di "Starting analysis for `v' Outcome ..." 
	
	forvalues i = 1/3 {
	
	preserve
	
	local skip_1 = 0
	local skip_2 = 0
	local skip_3 = 0
	
	* Apply exclusion for AKI and diabetes outcomes 
	if "`v'" == "t1dm" | "`v'" == "t2dm" {
	drop if previous_diabetes == 1
	local skip_2 = 1 
	local skip_3 = 1 
	}	
	
	if "`v'" == "aki" {
	drop if aki_exclusion_flag == 1
	}
	
	if `i' == 1 {
	local out `v'
	local end_date `v'_end_date
	}
	
	if `i' == 2 {
	local out `v'_no_gp
	local end_date `v'_no_gp_end_date
	}
	
	if `i' == 3 {
	local out `v'_cens_gp
	local end_date `v'_cens_gp_end_date
	}
	
		if `skip_`i'' == 0 {
		
		noi di "$group: stset in `a'" 
		
		stset `end_date' , id(new_patient_id) failure(`out') enter(indexdate)  origin(indexdate)
		
		foreach adjust in crude age_sex full {
		    
			if "`adjust'" == "full" & "`v'" == "t2dm" {
			* remove diabetes
		global full i.case i.male age1 age2 age3 i.stp i.ethnicity i.imd i.obese4cat /// 
			i.smoke htdiag chronic_respiratory_disease i.asthmacat chronic_cardiac_disease ///
			i.cancer_exhaem_cat i.cancer_haem_cat i.reduced_kidney_function_cat2  ///
			chronic_liver_disease stroke dementia other_neuro organ_transplant spleen ///
			ra_sle_psoriasis other_immunosuppression hist_dvt hist_pe hist_stroke hist_mi hist_aki hist_heart_failure	///
			}
			
			
			stcox $`adjust', vce(robust)
			
			
			matrix b = r(table)
			local hr= b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]

			stptime if case == 1
			local rate_covid = `r(rate)'
			local ptime_covid = `r(ptime)'
			local events_covid .
			if `r(failures)' == 0 | `r(failures)' > 5 local events_covid `r(failures)'
			
			stptime if case == 0
			local rate_comparator = `r(rate)'
			local ptime_comparator = `r(ptime)'
			local events_comparator .
			if `r(failures)' == 0 | `r(failures)' > 5 local events_comparator `r(failures)'

			post `measures'  ("`an'") ("`v'") ("`out'") ("`adjust'")  ///
							(`ptime_covid') (`events_covid') (`rate_covid') (`ptime_comparator') (`events_comparator')  (`rate_comparator')  ///
							(`hr') (`lc') (`uc')
			
			}
		}
restore			
}
	
}


}
postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_summary, replace

export delimited using $tabfigdir/cox_model_summary.csv, replace

log close











webuse hypoxia, clear
stset dftime, failure(failtype==1)
stcompet cuminc = ci, by(disrec) compet1(2)

gen cum = cuminc if failtype==1
separate cum, by(disrec) veryshortlabel

// Get maxima for time & cumulatives
forvalues i = 0/1{
 sum dftime if disrec ==`i', meanonly
 local tmax`i' = r(max)
 sum cum`i', meanonly
 local cmax`i' = r(max)
}
/* Add 3 fake data points */
set obs 112  // current is 109
replace cum0 = 0 in 110
replace cum1 = 0 in 110
replace _t = 0 in   110
replace cum0 = `cmax0'   in 111
replace  _t = `tmax0'    in 111
replace cum1 = `cmax1'   in 112
replace  _t = `tmax1'    in 112


twoway ///
(line cum0 _t, sort c(J)) ///
(line cum1 _t, sort c(J)) 
