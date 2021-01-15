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

use $outdir/combined_covid_pneumonia.dta, replace
drop patient_id
gen new_patient_id = _n

cap log close
log using $outdir/cox_models.txt, replace t
global crude i.case
global age_sex i.case i.male age1 age2 age3

tempname measures
	postfile `measures' ///
		str20(outcome) str25(analysis) str10(adjustment) ptime_covid num_events_covid rate_covid /// 
		ptime_pneumonia num_events_pneumonia rate_pneumonia hr lc uc ///
		using $tabfigdir/cox_model_summary, replace

foreach v in stroke dvt pe heart_failure mi aki t1dm t2dm {

	
	noi di "Starting analysis for `v' Outcome ..." 
	
	forvalues i = 1/3 {
	
	preserve
	
	local skip_1 = 0
	local skip_2 = 0
	local skip_3 = 0
	
	* Apply exclusion for AKI and diabetes outcomes 
	if "`v'" == "aki" {	
	drop if aki_exclusion_flag == 1
	local skip_2 = 1 
	local skip_3 = 1 
	}
	
	if "`v'" == "t1dm" | "`v'" == "t2dm" {
	drop if previous_diabetes == 1
	local skip_2 = 1 
	local skip_3 = 1 
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
		
		foreach adjust in crude age_sex {
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
			local rate_pneum = `r(rate)'
			local ptime_pneum = `r(ptime)'
			local events_pneum .
			if `r(failures)' == 0 | `r(failures)' > 5 local events_pneum `r(failures)'

			post `measures'  ("`v'") ("`out'") ("`adjust'")  ///
							(`ptime_covid') (`events_covid') (`rate_covid') (`ptime_pneum') (`events_pneum')  (`rate_pneum')  ///
							(`hr') (`lc') (`uc')
			
			}
		}
restore			
}
	
}


postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_summary, replace

export delimited using $tabfigdir/cox_model_summary.csv, replace

log close
