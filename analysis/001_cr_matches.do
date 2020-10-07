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
set seed 1293098 

foreach v in 1/3 {

use  "data/cohort_covid_hosp", replace 
keep patient_id indexdate indexMonth pracid exposed age gender 

* Match controls in 2020
if `v' == 1 {
append using "data/cohort_control_2020", keep(patient_id pracid exposed age gender)
* To prevent duplicate ids in the dummy data
replace patient_id = _n
save "data/match_covid_ctrl20", replace
}

* Match controls in 2019 
if `v' == 1 {
append using "data/cohort_control_2020", keep(patient_id pracid exposed age gender)
* To prevent duplicate ids in the dummy data
replace patient_id = _n
save "data/match_covid_ctrl19", replace
}

* Match pneumonia in 2019
if `v' == 1 {
append using "data/cohort_control_2020", keep(patient_id pracid indexMonth exposed age gender)
* To prevent duplicate ids in the dummy data
replace patient_id = _n
save "data/match_covid_ctrl19", replace
}



*frames reset

**********************************
* Separate exposed and unexposed *
**********************************
frame put if exposed ==1, into(tomatch)
keep if exposed==0
frame rename default pool

* need to set number of possible matches
for num 1/3 : frame tomatch: gen long matchedto_X=.

* sort exposed indexdate
frame tomatch: sort indexdate 

frame tomatch: qui cou
local totaltomatch = r(N)

noi di "Matching progress out of `totaltomatch':"
noi di "****************************************"
* match 2 unexposed patients 
qui {
forvalues matchnum = 1/2{
noi di "Getting match number `matchnum's"

	forvalues i = 1/`totaltomatch' {

		if mod(`i',100)==0 noi di "." _cont
		if mod(`i',1000)==0 noi di "`i'" _cont

		frame tomatch: scalar idtomatch = patient_id[`i']
		frame tomatch: scalar TMgender = gender[`i']
		frame tomatch: scalar TMage = age[`i']
		frame tomatch: scalar TMpracid = pracid[`i']

		cap frame drop eligiblematches
		* Age gap +/- 3 years
		frame put if gender==TMgender & pracid==TMpracid & abs(age-TMage)<=3, into(eligiblematches)
		frame eligiblematches: cou
		if r(N)>=1{
			frame eligiblematches: gen u=uniform()
			frame eligiblematches: gen agediff=abs(age-TMage)
			frame eligiblematches: sort agediff u
			frame eligiblematches: scalar selectedmatch = patient_id[1]
		}
		else scalar selectedmatch = -999

		frame tomatch: replace matchedto_`matchnum' = selectedmatch in `i'
		drop if patient_id==selectedmatch

	}
}
}


frame change tomatch
keep patient_id matchedto*

save "data/cr_matches", replace
}
