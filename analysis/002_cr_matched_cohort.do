********************************************************************************
*
*	Do-file:		000_cr_matches.do
*
*	Programmed by:	Krishnan & John 
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
*run global

forvalues v = 1/3 {
use "data/cr_matches_`v'", clear
reshape long matchedto_, i(patient_id)

rename patient_id setid
rename matchedto patient_id

expand 2 if setid!=setid[_n-1], gen(expanded)
replace patient_id=setid if expanded==1
drop expanded

replace patient_id = -_n if patient_id==-999

sort setid patient_id
*safecount if setid!=setid[_n+1] & patient_id<0
count if setid!=setid[_n+1] & patient_id<0
noi di r(N) " patients could not be matched at all"

drop if patient_id<0 | patient_id==.
drop _j
* create flag for matched set

if `v' == 1 {
drop if patient_id == setid
gen flag = "pneumonia_hosp" if patient_id!=setid
 * merge on patient characteristics 
merge 1:1 patient_id flag using "data/cohort_pneumonia_hosp"
drop if _merge==2
drop _merge
 }
 
 if `v' == 2 {
 drop if patient_id == setid
 gen flag = "control_2019" if patient_id!=setid
 merge 1:1 patient_id flag using "data/cohort_control_2019"
drop if _merge==2
drop _merge
 }
 if `v' == 3 {
 drop if patient_id == setid
 gen flag = "control_2020" if patient_id!=setid
  merge 1:1 patient_id flag using "data/cohort_control_2020"
drop if _merge==2
drop _merge
 }
 
save "data/cr_matches_long_`v'.dta", replace
*erase "data/cr_matches_`v'.dta"
}

use "data/cohort_covid_hosp", replace

forvalues v = 1/3 {
    append using "data/cr_matches_long_`v'.dta"
	erase "data/cr_matches_long_`v'.dta"
}
replace setid = patient_id if setid ==. 
sort setid patient_id 

bysort setid patient: gen duplicatePatid = _n
count if duplicatePatid > 1
drop duplicatePatid

bysort setid: gen indexCovid = indexdate if flag == "covid_hosp"
egen index2020 = max(indexCovid), by(setid)
format index2020 %td 
bysort setid: gen indexPneumonia = indexdate if flag == "pneumonia_hosp"
egen index2019 = max(indexPneumonia), by(setid)
format index2019 %td

bysort setid: replace indexdate = index2020 if flag == "control_2020"
bysort setid: replace indexdate = index2019 if flag == "control_2019"

drop indexCovid indexPneumonia index2020 index2019

* remove setid if no pneumonia matched 
egen nbad = total(indexdate == .) , by(setid)
drop if nbad
drop nbad

save "data/cr_matched_cohort", replace 
