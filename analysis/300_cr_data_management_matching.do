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
ls $outdir/
foreach v in covid pneumonia  {
import delimited $outdir/input_`v'.csv, clear
save $outdir/patients_`v'.dta, replace
}

* Gen flag for covid patients  (case = 1)
use $outdir/patients_covid.dta, replace
gen case = 1 
append using $outdir/patients_pneumonia.dta, force
replace case = 0 if case ==.
* Remove patients from pneumonia group who are among Covid group
bysort patient_id: gen flag = _n
bysort patient_id: egen tot = max(flag)
drop if tot == 2 & case ==0 
drop flag tot
gen year_20 = 1 if case == 1
replace year_20 = 0 if case == 0
save $outdir/matched_combined_pneumonia.dta, replace


********************************************************************************
* Format controls_2019 matched sets 
********************************************************************************

import delimited $outdir/matched_combined_control_2019.csv, clear
gen year_20 = 1 if case == 1
replace year_20 = 0 if case == 0
save $outdir/matched_combined_control_2019.dta, replace

********************************************************************************
* Format controls_2020 matched sets 
********************************************************************************

import delimited $outdir/matched_combined_control_2020.csv, clear
gen year_20 = 1
save $outdir/matched_combined_control_2020.dta, replace
