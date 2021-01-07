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

tempname measures
																	 
	postfile `measures' str16(group) str20(outcome) str12(analysis) str20(variable) category personTime numEvents rate lc uc using $tabfigdir/rates_summary_$group, replace


foreach v in stroke dvt pe {
preserve	
	foreach a in post_hosp post_hosp_gp {
		noi di "$group: stset in `a'" 
		
			stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(indexdate)  origin(indexdate)
		
		* Overall rate 
		stptime  
		* Save measure
		post `measures' ("$group") ("`v'") ("`a'") ("Overall") (0) (`r(ptime)') 	///
							(`r(failures)') (`r(rate)') 								///
							(`r(lb)') (`r(ub))')
		
		* Stratified
		foreach c in previous_`v' agegroup male ethnicity af anticoag_rx icu_admission  {
			qui levelsof `c' , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "$group: Calculate rate for variable `c' and level `l'" 
				qui  count if `c' ==`l'
				if `r(N)' > 0 {
				stptime if `c'==`l' 

				* Save measures
				post `measures' ("$group") ("`v'") ("`a'") ("`c'") (`l') (`r(ptime)')	///
								(`r(failures)') (`r(rate)') 							///
								(`r(lb)') (`r(ub))')
				}

				else {
				post `measures' ("$group") ("`v'") ("`a'") ("`c'") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
					
			}
		}
	}
restore
}

postclose `measures'

* Change postfiles to csv
use $tabfigdir/rates_summary_$group, replace

* Change from per person-day to per 100 person-months
gen rate_ppm = 100*(rate * 365.25 / 12)
gen lc_ppm = 100*(lc * 365.25 /12)
gen uc_ppm = 100*(uc * 365.25 /12)

export delimited using $tabfigdir/rates_summary_$group.csv, replace

