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
global stratifiers "previous_stroke previous_dvt previous_pe agegroup male ethnicity af anticoag_rx "
}
else {
global stratifiers "previous_stroke previous_dvt previous_pe agegroup male ethnicity af anticoag_rx"
}

tempname measures
																	 
	postfile `measures' str16(group) str20(outcome) str12(time) str20(variable) category personTime numEvents rate lc uc using $tabfigdir/rates_summary_$group, replace


foreach v in stroke dvt pe heart_failure mi renal_failure t1dm t2dm {
preserve	
if "`v'" == "renal_failure" {
drop if renal_exclusion_flag == 1
}
if "`v'" == "t1dm" | "`v'" == "t2dm" {
drop if previous_diabetes == 1
}
		noi di "$group: stset in post_hosp_gp" 
		
			stset `v'_end_date , id(patient_id) failure(`v') enter(indexdate)  origin(indexdate)
		
		* Overall rate 
		stptime  
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' ("$group") ("`v'") ("Full period") ("Overall") (0) (`r(ptime)') 	///
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
				post `measures' ("$group") ("`v'") ("Full period") ("`c'") (`l') (`r(ptime)')	///
								(`events') (`r(rate)') 							///
								(`r(lb)') (`r(ub)')
				}

				else {
				post `measures' ("$group") ("`v'") ("Full period") ("`c'") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
				}
					
			}
		}
* Stsplit data into 30 day periods
	stsplit time, at(30(30)120)
		
		* Overall rate 
		forvalues t = 0(30)120 {
		stptime if time ==`t'
		* Save measure
		local events .
		if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
		post `measures' ("$group") ("`v'") ("`t' days") ("Overall") (0) (`r(ptime)') 	///
							(`events') (`r(rate)') 								///
							(`r(lb)') (`r(ub)')
		
		* Stratified 
			qui levelsof agegroup , local(cats) 
			di `cats'
			foreach l of local cats {
				noi di "$group: Calculate rate for variable `c' and level `l' over time = `t'" 
				qui  count if time ==`t' & agegroup ==`l' 
				if `r(N)' > 0 {
				stptime if time ==`t' & agegroup ==`l'
				* Save measures
				local events .
				if `r(failures)' == 0 | `r(failures)' > 5 local events `r(failures)'
				post `measures' ("$group") ("`v'") ("`t' days")  ("agegroup") (`l') (`r(ptime)')	///
								(`events') (`r(rate)') 							///
								(`r(lb)') (`r(ub)')
				}

				else {
				post `measures' ("$group") ("`v'") ("`t' days") ("agegroup") (`l') (.) 	///
							(.) (.) 								///
							(.) (.) 
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

