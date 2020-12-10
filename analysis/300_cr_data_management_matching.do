********************************************************************************
*
*	Do-file:		300_cr_data_management.do
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

use "/Users/lsh1401926/Desktop/post-covid-thrombosis-research/output/cohort_rates_pneumonia.dta", replace
replace patient_id = patient_id + 1000000 // for dummy data
append using "/Users/lsh1401926/Desktop/post-covid-thrombosis-research/output/cohort_rates_covid.dta"
gen exposed = 1 if flag == "covid"
replace exposed =0 if exposed ==.
save "data/cr_matched_cohort", replace 
