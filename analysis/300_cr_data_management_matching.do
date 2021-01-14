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
* Append covid/pneumonia cohorts 
********************************************************************************
ls $outdir/

cap log close
log using $outdir/append_cohorts.txt, replace t

* Gen flag for covid patients  (case = 1)
use $outdir/cohort_rates_covid, replace
gen case = 1 
append using $outdir/cohort_rates_pneumonia, force
replace case = 0 if case ==.

* count patients from pneumonia group who are among Covid group
bysort patient_id: gen flag = _n
safecount if flag == 2

noi di "number of patients in both cohorts is `r(N)'"

drop flag 
save $outdir/combined_covid_pneumonia.dta, replace

log close
