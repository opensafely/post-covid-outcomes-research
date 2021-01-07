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
local end_date td(01/10/2020)

}
else {
local start_date  td(01/02/2019)
local last_year   td(01/02/2018)	
local four_years_ago td(01/02/2014)	 
local fifteen_months_ago td(01/09/2018)
local end_date td(01/10/2019)
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
					   dvt_ons				///
					   stroke_hospital  	///
					   died_date_ons 		///
					   creatinine_date  	///
					   dialysis 			///
					   {

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

foreach v of varlist previous_pe   ///
					 previous_stroke ///
					 previous_dvt {
replace `v' = 0 if `v' ==. 
}
	
* drop if died before discharge date
drop if died_date_ons < indexdate

* Note: There may be deaths recorded after end of our study (08 Oct)
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


* Recode true/false variables
foreach v of varlist af 		///
					 dvt 		///
					 pe		    ///
					stroke 		///
					anticoag_rx { 
rename `v' `v'_2
gen `v' = (`v'_2=="True")
drop `v'_2
}		
	
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
egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
* 0 = "No CKD" 	2 "stage 3a" 3 "stage 3b" 4 "stage 4" 5 "stage 5"
label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
label var ckd "CKD stage calc without eth"

* Convert into CKD group
*recode ckd 2/5=1, gen(chronic_kidney_disease)
*replace chronic_kidney_disease = 0 if creatinine==. 

recode ckd 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
replace reduced_kidney_function_cat = 1 if creatinine==. 
label define reduced_kidney_function_catlab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4/5 egfr<30"
label values reduced_kidney_function_cat reduced_kidney_function_catlab 

*More detailed version incorporating stage 5 or dialysis as a separate category	
recode ckd 0=1 2/3=2 4=3 5=4, gen(reduced_kidney_function_cat2)
replace reduced_kidney_function_cat2 = 1 if creatinine==. 
replace reduced_kidney_function_cat2 = 5 if dialysis==1 

label define reduced_kidney_function_cat2lab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4 egfr 15-<30" 4 "Stage 4 egfr <15-<30" 5 "Stage 5 egfr <15 or dialysis"
label values reduced_kidney_function_cat2 reduced_kidney_function_cat2lab 
 
******************************************
* Admitted to ICU during hospitalisation *	
******************************************

gen icu_admission = cond(icu_admission_date <= indexdate , 1, 0) 


**************
*  Outcomes  *
**************	

foreach out in stroke dvt pe {

gen min_end_date = min(`out'_hospital, `out'_gp, died_date_ons_date)
* Define outcome 
	gen 	`out'_end_date = `end_date' // relevant end date
	replace `out'_end_date = min_end_date if min_end_date > indexdate & ///  // after indexdate
											 min_end_date!=. 				 // and not missing

	replace `out'_end_date = `out'_end_date + 1 
	format %td `out'_end_date 

drop min_end_date	
}
										
**** Tidy dataset

if "$group" == "covid" | "$group" == "pneumonia"  { 
keep  patient_id icu_admission previous_dvt previous_pe /// 
 previous_stroke agegroup ethnicity af /// 
 indexdate male region_7 dvt pe stroke anticoag_rx agegroup ///
 icu_admission stroke_end_date pe_end_date dvt_end_date long_hosp_stay
 }
else { 
keep  patient_id icu_admission previous_dvt previous_pe /// 
 previous_stroke agegroup ethnicity af /// 
 indexdate male region_7 dvt pe stroke anticoag_rx agegroup ///
 icu_admission stroke_end_date pe_end_date dvt_end_date
}
order patient_id indexdate

save $outdir/cohort_rates_$group, replace 
