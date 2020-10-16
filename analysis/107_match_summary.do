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

* Open a log file
capture log close
log using "output/107_match_summary", text replace

use "data/cr_matched_cohort_primary", replace 

bysort setid: gen numSets = _n == 1
safecount if numSets
local setNum = `r(N)'
if `r(N)' != . {
noi di "Number of matched sets: `r(N)'"
}
else {
noi di "Number of matched sets: <5" 
}
 
safecount if flag == "covid_hosp"
if `r(N)' != . {
noi di "Number of covid patients in the matched cohort: `r(N)'"
}
else {
noi di "Number of covid patients in the matched cohort: <5 "
}

bysort setid flag: gen matches = _n 
bysort setid flag: egen totMatches = max(matches)
keep if matches == 1

safecount if totMatches >= 1 & flag == "pneumonia_hosp"
if `r(N)' != . {
noi di "Out of `setNum' matched sets: `r(N)' matched 1 pneuomnia patient" 
}
else {
noi di "Out of `setNum' matched sets: <=5 matched 1 pneuomnia patient" 
}

safecount if totMatches >= 1 & flag == "control_2019"
if `r(N)' != . {
noi di "Out of `setNum' matched sets: `r(N)' matched at least 1 2019 control patient" 
}
else {
noi di "Out of `setNum' matched sets: <=5 matched at least 1 2019 control patient" 
}

safecount if totMatches >= 1 & flag == "control_2020"
if `r(N)' != . {
noi di "Out of `setNum' matched sets: `r(N)' matched at least 1 2020 control patient" 
}
else {
noi di "Out of `setNum' matched sets: <=5 matched at least 1 2020 control patient" 
}

log close
