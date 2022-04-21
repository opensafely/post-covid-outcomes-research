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
*	Purpose: Logistic regression models for primary analysis (reviewer comment)
*
*	Note:			
********************************************************************************

clear
do `c(pwd)'/analysis/global.do

cap log close
log using $outdir/logistic_models.txt, replace t

tempname measures
	postfile `measures' ///
		str20(comparator) str20(outcome) str25(analysis) str10(adjustment) ///
		 hr lc uc ///
		using $tabfigdir/logistic_summary, replace
		
foreach an in pneumonia gen_population {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

global crude i.case
global age_sex i.case i.male age1 age2 age3
	
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

		
		foreach adjust in crude age_sex {
			
			logistic `out' $`adjust', vce(robust) 
			
			matrix b = r(table)
		 
			local or = b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]
			

			post `measures'  ("`an'") ("`v'") ("`out'") ("`adjust'")  ///
							(`or') (`lc') (`uc')
			
			}
		}
restore			
}
	
}


}
postclose `measures'

* Change postfiles to csv
use $tabfigdir/logistic_summary, replace

export delimited using $tabfigdir/logistic_summary.csv, replace

log close
