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
*	Other $outdir:	None
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			
********************************************************************************
clear
do `c(pwd)'/analysis/global.do
********************************************************************************
* Append covid/pneumonia groups matched datasets
********************************************************************************
foreach v in covid pneumonia  {
import delimited "$outdir/input_`v'.csv", clear
save "$outdir/patients_`v'.dta", replace
}

* Gen flag for covid patients  (case = 1)
use "$outdir/patients_covid.dta", replace
gen case = 1 
append using "$outdir/patients_pneumonia.dta"
replace case = 0 if case ==.
gen year_20 = 1 if case == 1
replace year_20 = 0 if case == 0
save "$outdir/matched_combined_pneumonia.dta", replace


********************************************************************************
* Format controls_2019 matched sets 
********************************************************************************

import delimited "$outdir/matched_combined_control_2019.csv", clear
gen year_20 = 1 if case == 1
replace year_20 = 0 if case == 0
save "$outdir/matched_combined_control_2019.dta", replace

********************************************************************************
* Format controls_2020 matched sets 
********************************************************************************

import delimited "$outdir/matched_combined_control_2020.csv", clear
gen compflag = "control_20"
gen year_20 = 1
save "$outdir/matched_combined_control_2020.dta", replace
