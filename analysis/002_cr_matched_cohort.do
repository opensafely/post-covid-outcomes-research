********************************************************************************
*
*	Do-file:		000_cr_matches.do
*
*	Programmed by:	Khrisnan & John 
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

use "data/cr_matches", clear

reshape long matchedto_, i(patient_id)

rename patient_id setid
rename matchedto patient_id

expand 2 if setid!=setid[_n-1], gen(expanded)
replace patient_id=setid if expanded==1
drop expanded

replace patient_id = -_n if patient_id==-999

sort setid patient_id
safecount if setid!=setid[_n+1] & patient_id<0
noi di r(N) " patients could not be matched at all"

drop if patient_id<0 | patient_id==.
drop _j

* merge on patient characteristics 
merge 1:1 patient_id using "data/matchgroup1", keep(match master)

gsort setid patient_id

save "data/cr_matched_cohort", replace 