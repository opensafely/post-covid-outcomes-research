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
log using $outdir/follow_up_median.txt, replace t

tempname measures
	postfile `measures' ///
		 str25(comparator) str20(outcome) str25(analysis) str10(median) ///
		using $tabfigdir/follow_up_summary, replace
		
foreach an in pneumonia gen_population {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n


foreach v in stroke dvt pe heart_failure mi aki t2dm {

	
	noi di "Starting analysis for `v' Outcome ..." 
	
	* Apply exclusion for AKI and diabetes outcomes 
	if "`v'" == "aki" {
	drop if aki_exclusion_flag == 1
	}
	
	if "`v'" == "t1dm" | "`v'" == "t2dm" {
	drop if previous_diabetes == 1
	local out `v'
	local end_date `v'_end_date
	}
	else {
	local out `v'_no_gp
	local end_date `v'_no_gp_end_date
	}
	
		noi di "$group: stset in `a'" 
		
		stset `end_date' , id(new_patient_id) failure(`out') enter(indexdate)  origin(indexdate)
		
		stdescribe
		
		post `measures' ("`an'") ("`v'") ("`Cox'") ("`r(t1_med)'") 
	
		
		gen act_end_date = `end_date' - 1 
		
		gen `end_date'2= `end_date'
		replace `end_date'2 = td(01/02/2021) if case == 1 & act_end_date == died_date_ons_date & died_date_ons_date!= `v'_ons
		replace `end_date'2 = td(01/02/2020) if case == 0 & act_end_date == died_date_ons_date & died_date_ons_date!= `v'_ons
		format %td `end_date'2
		
		stset `end_date'2, id(new_patient_id) enter(indexdate)  origin(indexdate) failure(`out') 
	
		stdescribe
		
		post `measures' ("`an'") ("`v'") ("`Competing Risks'") ("`r(t1_med)'") 
			
			}
		}
restore			
}
	
}


}
postclose `measures'

* Change postfiles to csv
use $tabfigdir/follow_up_summary, replace

export delimited using $tabfigdir/follow_up_summary.csv, replace

log close
