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

use "data/cr_matched_cohort_primary", replace 

encode flag, gen(exposure)
/* 
  control_2019 1
  control_2020 2
    covid_hosp 3
pneumonia_hosp 4

*/


tempname measures
	postfile `measures' str13(comparison) str12(outcome) str12(analysis) str20(variable) category hr lc uc using "data/cox_model_summary", replace

forvalues t = 1/3  {
preserve

if `t' == 1 {
noi di "Covid vs 2020 control analysis"
keep if flag == "covid_hosp" | flag == "control_2020"
}

if `t' == 2 {
noi di "Pneumonia vs 2019 control analysis"
keep if flag == "pneumonia_hosp" | flag == "control_2019"
}

if `t' == 3 {
noi di "Covid vs pneumonia analysis"
keep if flag == "covid_hosp" | flag == "pneumonia_hosp"
}

*foreach v in stroke dvt pe  {
foreach v in stroke   {

* Clean outcomes / dates

*******************
* Primary Outcome *
*******************

gen `v'_primary_outcome = cond( (`v'_gp_date > indexdate  & `v'_gp_date !=.) | 		/// 
								  (`v'_hospital_date > indexdate & `v'_hospital_date !=. ) | ///
								  (`v'_ons == 2020 & died_date_ons_date > indexdate & died_date_ons_date!=. ) & ///
								  died_date_ons_date!= indexdate, 1, 0)
								  
* Update to other end of follow up dates								  
gen `v'_primary_end_date = min(`v'_gp_date, `v'_hospital_date, died_date_ons_date, td(01oct2020))
format %td `v'_primary_end_date

*********************
* Secondary Outcome *
*********************
								 								   
gen `v'_secondary_outcome = cond( (`v'_hospital_date > indexdate & `v'_hospital_date !=. ) |  ///
								  (`v'_ons == 2020 & died_date_ons_date > indexdate & died_date_ons_date!=. ) & ///
								  died_date_ons_date!= indexdate, 1, 0)

gen `v'_secondary_end_date = min(`v'_gp_date, `v'_hospital_date, died_date_ons_date, td(01oct2020))								  
format %td `v'_secondary_end_date
								 

foreach a in primary secondary {

stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a'_outcome) enter(indexdate)
 
foreach c in imd ethnicity smoke {
qui levelsof `c' , local(cats) 
di `cats'
foreach l of local cats {

/*
stptime
noi di "Person Time: `r(ptime)'"
noi di "No. Events : `r(failures)'"
noi di "Rate (95% CI): `r(rate)' (95%CI: `r(lb)' to `r(ub)')" 
*/

stcox i.exposed if `c'==`l'
matrix b = r(table)
local hr= b[1,2]
local lc = b[5,2] 
local uc = b[6,2]


if `t' == 1 {
	post `measures' ("covid_2020") ("`v'") ("`a'") ("`c'") (`l') 	///
						(`hr') (`lc') (`uc')
}
if `t' == 2 {
	post `measures' ("pneu_2019") ("`v'") ("`a'") ("`c'") (`l') 				///
						(`hr') (`lc') (`uc')
}
if `t' == 3 {
	post `measures' ("covid_pneu") ("`v'") ("`a'") ("`c'") (`l') ///
						(`hr') (`lc') (`uc')
}

							
}




}
}

}

restore

}

postclose `measures'

use "data/cox_model_summary", replace
