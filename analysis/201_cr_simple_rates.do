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
	postfile `measures' str13(group) str12(outcome) str12(analysis) str20(variable) category personTime numEvents rate lc uc using "data/rates_summary_$group", replace

foreach v in stroke dvt pe {

noi di "Starting analysis for $group: `v' Outcome ..." 
noi di "$group: stset in hospital" 
if "$group" == "covid_hosp" {
stset `v'_in_hosp_end_date , id(patient_id) failure(`v'_in_hosp) enter(hospitalised_covid_date)
}

if "$group" == "pneumonia_hosp" {
stset `v'_in_hosp_end_date , id(patient_id) failure(`v'_in_hosp) enter(hospitalised_pneumonia_date)
}



foreach c in hist_`v' {
qui levelsof `c' , local(cats) 
di `cats'
foreach l of local cats {
noi di "$group: Calculate rate for variable `c' and level `l'" 

stptime if `c'==`l' 


			* Save measures
			post `measures' ("$group") ("`v'") ("in_hosp") ("`c'") (`l') (`r(ptime)') ///
							(`r(failures)') (`r(rate)') 							///
							(`r(lb)') (`r(ub))') 	

}
}

foreach a in post_hosp post_hosp_gp {

noi di "$group: stset in `a'" 

if "$group" == "covid_hosp" {
stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(discharged_covid_date)
}

if "$group" == "pneumonia_hosp" {
stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(discharged_pneumonia_date)
}

foreach c in hist_`v' {
qui levelsof `c' , local(cats) 
di `cats'
foreach l of local cats {
noi di "$group: Calculate rate for variable `c' and level `l'" 

stptime if `c'==`l' 

			* Save measures
			post `measures' ("$group") ("`v'") ("`a'") ("`c'") (`l') (`r(ptime)') ///
							(`r(failures)') (`r(rate)') 							///
							(`r(lb)') (`r(ub))') 	

}
}


							
}
}

postclose `measures'

* Change postfiles to csv
use "data/rates_summary_$group", replace
export delimited using "data/rates_summary_$group.csv", replace
erase "data/rates_summary_$group.dta"
