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


use "data/cohort_rates_$group", replace 

tempname measures
	postfile `measures' str12(outcome) str12(analysis) str20(variable) category personTime numEvents rate lc uc using "data/rates_summary_$group", replace

foreach v in  stroke dvt pe {

stset `v'_in_hosp_end_date , id(patient_id) failure(`v'_in_hosp) enter(hospitalised_covid_date)

foreach c in hist_`v' {
qui levelsof `c' , local(cats) 
di `cats'
foreach l of local cats {
stptime if `c'==`l' 

			* Save measures
			post `measures' ("`v'") ("in_hosp") ("`c'") (`l') (`r(ptime)') ///
							(`r(failures)') (`r(rate)') 							///
							(`r(lb)') (`r(ub))') 	

}
}

foreach a in post_hosp post_hosp_gp {

stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(discharged_covid_date)


foreach c in hist_`v' {
qui levelsof `c' , local(cats) 
di `cats'
foreach l of local cats {
stptime if `c'==`l' 

			* Save measures
			post `measures' ("`v'") ("`a'") ("`c'") (`l') (`r(ptime)') ///
							(`r(failures)') (`r(rate)') 							///
							(`r(lb)') (`r(ub))') 	

}
}


							
}
}

postclose `measures'

