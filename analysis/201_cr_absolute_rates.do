********************************************************************************
*
*	Do-file:		000_cr_matches.do
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
*	Purpose:		T
*
*	Note:			
********************************************************************************

use "data/cr_matched_cohort_primary", replace 

*foreach v in stroke dvt pe  {
foreach v in stroke   {
gen `v'_primary_outcome = cond( (`v'_gp_date > indexdate  & `v'_gp_date !=.) | 		/// 
								  (`v'_hospital_date > indexdate & `v'_gp_date !=. ) | ///
								  (`v'_ons == 2020 & died_date_ons_date > indexdate & died_date_ons_date!=. ) & ///
								  died_date_ons_date!= indexdate, 1, 0)
								  
* Update to other end of follow up dates								  
gen `v'_primary_end_date = min(`v'_gp_date, `v'_hospital_date, died_date_ons_date, td(01oct2020))
format %td `v'_primary_end_date
								 								   
gen `v'_secondary_outcome = cond( (`v'_hospital_date > indexdate & `v'_gp_date !=. ) |  ///
								  (`v'_ons == 2020 & died_date_ons_date > indexdate & died_date_ons_date!=. ) & ///
								  died_date_ons_date!= indexdate, 1, 0)

gen `v'_secondary_end_date = min(`v'_gp_date, `v'_hospital_date, died_date_ons_date, td(01oct2020))								  
format %td `v'_secondary_end_date
								 


stset `v'_primary_end_date , id(patient_id) failure(`v'_primary_outcome) enter(indexdate)
 
stptime
noi di "Person Time"  
 di `r(ptime)'
noi di "No. Events"   
di `r(failures)'
noi di "Rate (95% CI)" 
di `r(rate)' 
di `r(lb)' 
di `r(ub)'

*test strat
 gen agecat = 1 if age<50
 replace agecat = 0 if agecat==.
stptime , by(agecat) // no return list
stptime if agecat==1 // gives same
 
 
}
