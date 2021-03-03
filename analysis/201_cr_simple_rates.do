********************************************************************************
*
*	Do-file:		201_cr_simple_rates.do
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
do `c(pwd)'/analysis/global.do
global group `1'

use $outdir/cohort_rates_$group, clear 

if "$group" == "covid" | "$group" == "pneumonia"  { 
global stratifiers "agegroup male ethnicity af anticoag_rx long_hosp_stay"
}
else {
global stratifiers "agegroup male ethnicity af anticoag_rx"
}

tempname measures
																	 
	postfile `measures' str16(group) str25(outcome) str12(time) str20(variable) category personTime numEvents rate lc uc using $tabfigdir/rates_summary_$group, replace


foreach v in stroke dvt pe heart_failure mi aki t1dm t2dm {

	forvalues i = 1/3 {
	
	 preserve
	cap drop time
	
	local skip_1 = 0
	local skip_2 = 0
	local skip_3 = 0
	* Apply exclusion for diabetes outcomes 
	if "`v'" == "t1dm" | "`v'" == "t2dm" {
	drop if previous_diabetes == 1
	local skip_2 = 1 
	local skip_3 = 1 
	}	
	
	if "`v'" == "aki" {
	drop if aki_exclusion_flag == 1
	}
	
	if `i' == 1 {
	local out  `v'
	local end_date  `v'_end_date
	}
	
	if `i' == 2 {
	local out `v'_no_gp
	local end_date `v'_no_gp_end_date
	}
	
	if `i' == 3 {
	local out  `v'_cens_gp
	local end_date `v'_cens_gp_end_date
	}
	
	if `skip_`i'' == 0 {
		stset `end_date' , id(patient_id) failure(`out') enter(indexdate)  origin(indexdate)
		
		* Overall rate 
		stptime  
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' ("$group") ("`out'") ("Full period") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
		
		* Stratified - additionally include long_hosp_stay for hosp patients
		
		foreach c of global stratifiers {
		
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "$group: Calculate rate for variable `c' and level `l'" 
				qui  count if `c' ==`l'
				if `r(N)' > 0 {
				stptime if `c'==`l'
				* Save measures
				local events .
				if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
				post `measures' ("$group") ("`out'") ("Full period") ("`c'") (`l') (`r(ptime)')	///
								(`events') (`r(rate)') 							///
								(`r(lb)') (`r(ub)')
				}

				else {
				post `measures' ("$group") ("`out'") ("Full period") ("`c'") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
					
			}
		}
* Stsplit data into 30 day periods
	stsplit time, at(30(30)120)
		
		* Overall rate 
		forvalues t = 0(30)120 {
		qui  count if time ==`t'
		if `r(N)' > 0 {
		stptime if time ==`t'
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' ("$group") ("`out'") ("`t' days") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
		
	
		}
		else {
		post `measures' ("$group") ("`out'") ("`t' days") ("Overall") (0) (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
	}
  }
restore  
		
}

}

postclose `measures'

* Change postfiles to csv
use $tabfigdir/rates_summary_$group, replace

* Change from per person-day to per 100 person-months
gen rate_ppm = 100*(rate * 365.25 / 12)
gen lc_ppm = 100*(lc * 365.25 /12)
gen uc_ppm = 100*(uc * 365.25 /12)

export delimited using $tabfigdir/rates_summary_$group.csv, replace

