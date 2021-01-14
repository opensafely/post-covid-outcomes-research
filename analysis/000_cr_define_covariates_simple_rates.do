********************************************************************************
*
*	Do-file:		000_cr_define_covariates.do
*
*	Programmed by:	Alex & John (Based on Fizz & Krishnan)
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
clear
do `c(pwd)'/analysis/global.do
global group `1'

if "$group" == "covid" | "$group" == "covid_community"  { 
local start_date  td(01/02/2020)
local last_year   td(01/02/2019)
local four_years_ago td(01/02/2015)	 
local fifteen_months_ago td(01/09/2019)
local end_date td(01/11/2020)

}
else {
local start_date  td(01/02/2019)
local last_year   td(01/02/2018)	
local four_years_ago td(01/02/2014)	 
local fifteen_months_ago td(01/09/2018)
local end_date td(01/11/2019)
}

import delimited $outdir/input_$group.csv

di "STARTING COUNT FROM IMPORT:"
noi safecount

* Indexdate
gen indexdate = date(patient_index_date, "YMD")
format indexdate %td

drop if indexdate ==.
drop patient_index_date

* remove any patient discharged after end date
drop if indexdate > `end_date'

if "$group" == "covid" | "$group" == "pneumonia"  { 
gen hosp_expo_date = date(exposure_hospitalisation, "YMD")
format hosp_expo_date %td
* Length of stay
gen length_of_stay = indexdate - hosp_expo_date + 1
label var length_of_stay "Length of stay in hospital (days)"
hist length , name(length_of_stay_$group, replace) graphregion(color(white)) col(navy%50) ylab(,angle(h)) lcol(navy%20)
graph export $tabfigdir/length_of_stay_$group.svg , as(svg) replace

* Create flag for patients staying in hospital longer than the median length
summ length, detail
gen long_hosp_stay = cond(length_of_stay >= `r(p50)' , 1, 0)
}

******************************
*  Convert strings to dates  *
******************************
* To be added: dates related to outcomes
foreach var of varlist date_icu_admission   ///
					   dvt_gp				///
					   pe_gp				///
					   dvt_hospital		 	///
					   pe_hospital			///
					   stroke_gp			///
					   stroke_ons			///
					   pe_ons 				///
					   dvt_ons		 		///
					   aki_hospital ///
					   aki_ons	///
					   heart_failure_gp		///
					   heart_failure_hospital ///
					   heart_failure_ons    ///
					   mi_gp				///
					   mi_hospital			///
					   mi_ons				///
					   stroke_hospital  	///
					   died_date_ons 		///
					   creatinine_date  	///
					   dialysis 			///
					   t1dm_gp				///
					   t1dm_hospital  		///
					   t1dm_ons 			///
					   t2dm_gp				///
					   t2dm_hospital  		///
					   t2dm_ons 			 {

capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		rename `var' `var'_dstr
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}

* Clean 
rename date_icu_admission_date icu_admission_date

* drop if died before discharge date
drop if died_date_ons < indexdate

* Note: There may be deaths recorded after end of our study 
* Set these to missing
replace died_date_ons_date = . if died_date_ons_date>`end_date'

**********************
*  Recode variables  *
**********************

/*  Demographics  */

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex
label define sexLab 1 "male" 0 "female"
label values male sexLab
label var male "sex = 0 F, 1 M"

* Ethnicity (5 category)
replace ethnicity = .u if ethnicity==.
label define ethnicity_lab 	1 "White"  								///
						2 "Mixed" 								///
						3 "Asian or Asian British"				///
						4 "Black"  								///
						5 "Other"								///
						.u "Unknown"
label values ethnicity ethnicity_lab


/*  Geographical location  */

* Region
rename region region_string
assert inlist(region_string, 								///
					"East Midlands", 						///
					"East",  								///
					"London", 								///
					"North East", 							///
					"North West", 							///
					"South East", 							///
					"South West",							///
					"West Midlands", 						///
					"Yorkshire and The Humber") 
* Nine regions
gen     region_9 = 1 if region_string=="East Midlands"
replace region_9 = 2 if region_string=="East"
replace region_9 = 3 if region_string=="London"
replace region_9 = 4 if region_string=="North East"
replace region_9 = 5 if region_string=="North West"
replace region_9 = 6 if region_string=="South East"
replace region_9 = 7 if region_string=="South West"
replace region_9 = 8 if region_string=="West Midlands"
replace region_9 = 9 if region_string=="Yorkshire and The Humber"

label define region_9 	1 "East Midlands" 					///
						2 "East"   							///
						3 "London" 							///
						4 "North East" 						///
						5 "North West" 						///
						6 "South East" 						///
						7 "South West"						///
						8 "West Midlands" 					///
						9 "Yorkshire and The Humber"
label values region_9 region_9
label var region_9 "Region of England (9 regions)"

* Seven regions
recode region_9 2=1 3=2 1 8=3 4 9=4 5=5 6=6 7=7, gen(region_7)

label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"
drop region_string

	
**************************
*  Categorise variables  *
**************************

* Create categorised age
recode 	age 			min/49.9999=1 	///
						50/59.9999=2 	///
						60/69.9999=3 	///
						70/79.9999=4 	///
						80/max=5, 		///
						gen(agegroup) 

label define agegroup 	1 "18-<50" 		///
						2 "50-<60" 		///
						3 "60-<70" 		///
						4 "70-<80" 		///
						5 "80+"
label values agegroup agegroup


* Check there are no missing ages
assert age<.
assert agegroup<.

* Create restricted cubic splines fir age
mkspline age = age, cubic nknots(4)

***************************
*  Grouped comorbidities  *
***************************

************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 
	
* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min=.
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages

* dialysis
if "$group" == "covid" | "$group" == "pneumonia"  { 
gen dialysis_flag = 1 if dialysis_date < hosp_expo_date
replace dialysis_flag = 0 if dialysis_flag ==.
}
if "$group" == "covid_community" {
gen dialysis_flag = 1 if dialysis_date < indexdate
replace dialysis_flag = 0 if dialysis_flag ==.
}

gen aki_exclusion_flag = 1 if egfr < 15 | dialysis_flag==1
replace aki_exclusion_flag = 0 if aki_exclusion_flag ==.

**************
*  Outcomes  *
**************	

* Post outcome distribution 
tempname outcomeDist
																	 
	postfile `outcomeDist' str20(outcome) str12(type) numEvents percent using $tabfigdir/outcome_distribution_$group.dta, replace
	
foreach out in stroke dvt pe heart_failure mi aki t1dm t2dm {

if "`out'" == "aki" {
replace `out'_hospital = . if `out'_hospital > `end_date'
gen min_end_date = min(`out'_hospital, died_date_ons_date) // `out'_ons already captured in the study definition binary outcome
}
else {
replace `out'_hospital = . if `out'_hospital > `end_date'
replace `out'_gp = . if `out'_gp > `end_date'
gen min_end_date = min(`out'_hospital, `out'_gp, died_date_ons_date) // `out'_ons already captured in the study definition binary outcome
}

* 1) Define outcome using all data
replace `out' = 0 if min_end_date > `end_date'
gen 	`out'_end_date = `end_date' // relevant end date
replace `out'_end_date = min_end_date if  min_end_date!=.	 // not missing
replace `out'_end_date = `out'_end_date + 1 
format %td `out'_end_date 

drop min_end_date	

* 2) Define outcome using hospital data only
gen min_end_date = min(`out'_hospital, died_date_ons_date)
replace `out'_no_gp= 0 if min_end_date > `end_date'
gen 	`out'_no_gp_end_date = `end_date' // relevant end date
replace `out'_no_gp_end_date = min_end_date if  min_end_date!=.	 // not missing
replace `out'_no_gp_end_date = `out'_no_gp_end_date + 1 
format %td `out'_no_gp_end_date 

drop min_end_date	

* 3) Define outcome avoiding GP 'outcomes' if patient has a recent history
if "`out'"!="aki" & "`out'"!="t1dm" & "`out'"!="t2dm" {
gen min_end_date = min(`out'_hospital, `out'_gp, died_date_ons_date) if recent_`out' == 0
replace min_end_date = min(`out'_hospital, died_date_ons_date) if recent_`out' == 1
replace `out'_cens_gp= 0 if min_end_date > `end_date'
gen 	`out'_cens_gp_end_date = `end_date' // relevant end date
replace `out'_cens_gp_end_date = min_end_date if  min_end_date!=.	 // not missing
replace `out'_cens_gp_end_date = `out'_cens_gp_end_date + 1 
format %td `out'_cens_gp_end_date 

drop min_end_date	
}

* Count overall outcomes by type 

if "`out'" == "aki" {
replace `out'_hospital = `out'_hospital + 1 
replace died_date_ons_date = died_date_ons_date + 1 
}
else {
replace `out'_hospital = `out'_hospital + 1 
replace `out'_gp = `out'_gp + 1 
replace died_date_ons_date = died_date_ons_date + 1 
}

if "`out'" == "aki" {
* Overall
safecount if `out' == 1 & aki_exclusion_flag == 0
local tot_events = `r(N)'
post `outcomeDist' ("`out'") ("Overall") (`tot_events') (100)

* Hospital
safecount if `out' == 1 & `out'_end_date == `out'_hospital & aki_exclusion_flag == 0
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("HOSP") (`events') (`percent') 

* ONS
safecount if `out' == 1 & `out'_end_date == died_date_ons_date & aki_exclusion_flag == 0
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("ONS") (`events') (`percent') 


}

if "`out'" == "t2dm" | "`out'" == "t1dm" {
* Overall
safecount if `out' == 1 & previous_diabetes == 0
local tot_events = `r(N)'
post `outcomeDist' ("`out'") ("Overall") (`tot_events') (100)

* GP
safecount if `out' == 1 & `out'_end_date == `out'_gp & previous_diabetes == 0
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("GP") (`events') (`percent') 

* Hospital
safecount if `out' == 1 & `out'_end_date == `out'_hospital & previous_diabetes == 0
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("HOSP") (`events') (`percent') 

* ONS
safecount if `out' == 1 & `out'_end_date == died_date_ons_date & previous_diabetes == 0
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("ONS") (`events') (`percent') 


}

if "`out'" != "aki" & "`out'" != "t2dm" & "`out'" != "t1dm" {
* Overall
safecount if `out' == 1 
local tot_events = `r(N)'
post `outcomeDist' ("`out'") ("Overall") (`tot_events') (100)

* GP
safecount if `out' == 1 & `out'_end_date == `out'_gp
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("GP") (`events') (`percent') 

* Hospital
safecount if `out' == 1 & `out'_end_date == `out'_hospital
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("HOSP") (`events') (`percent') 

* ONS
safecount if `out' == 1 & `out'_end_date == died_date_ons_date
local events = `r(N)' 
local percent= `r(N)' /`tot_events' *100
post `outcomeDist' ("`out'") ("ONS") (`events') (`percent') 
}

}

postclose `outcomeDist'


										
**** Tidy dataset

if "$group" == "covid" | "$group" == "pneumonia"  { 
keep  patient_id hosp_expo_date previous_* agegroup ethnicity af aki_exclusion_flag /// 
 indexdate male region_7 dvt* pe* stroke* anticoag_rx agegroup ///
 af *_end_date long_hosp_stay mi* heart_failure* aki* mi* t1dm* t2dm* age*
 }
else { 
keep patient_id previous_* agegroup ethnicity af aki_exclusion_flag /// 
 indexdate male region_7 dvt* pe* stroke* anticoag_rx agegroup ///
 af *_end_date long_hosp_stay mi* heart_failure* aki* mi* t1dm* t2dm* age*
 
}
order patient_id indexdate

save $outdir/cohort_rates_$group, replace 



* Tidy outcome dist data 
use $tabfigdir/outcome_distribution_$group.dta, replace
export delimited using $tabfigdir/outcome_distribution_$group.csv, replace
