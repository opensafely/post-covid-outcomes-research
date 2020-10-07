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


di "STARTING COUNT FROM IMPORT:"
noi count

* Age: Exclude children and implausibly old people
qui summ age // Should be no missing ages
noi di "DROPPING AGE>105:" 
drop if age>105
noi di "DROPPING AGE<18:" 
drop if age<18
assert inrange(age, 18, 105)

* Age: Exclude those with implausible ages
assert age<.
noi di "DROPPING AGE<105:" 
drop if age>105

* Sex: Exclude categories other than M and F
assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")

* STP
noi di "DROPPING IF STP MISSING:"
drop if stp==""

* IMD 
noi di "DROPPING IF NO IMD" 
capture confirm string var imd 
if _rc==0 {
	drop if imd==""
}
else {
	drop if imd>=.
}

* Hospitalised with covid

if "$group" == "covid_hosp" {
gen hospitalised_covid_date = date(hospitalised_covid, "YMD")
format hospitalised_covid_date %td

drop if hospitalised_covid_date ==.
drop hospitalised_covid

* for matching 
gen exposed = 1
gen indexdate= hospitalised_covid_date
format indexdate %td
gen indexMonth = month(hospitalised_covid_date)

gen yob = 2020 - age
}

if "$group" == "pneumonia_hosp" {
gen hospitalised_pneumonia_date = date(hospitalised_covid, "YMD")
format hospitalised_pneumonia_date %td

drop if hospitalised_pneumonia_date ==.
drop hospitalised_covid

gen indexMonth = month(hospitalised_pneumonia_date)
gen exposed = 0 
gen yob = 2019 - age

}

if "$group" == "control_2019" {

* for matching (for 2019 comparison)
gen exposed = 0 
gen yob = 2019 - age
}

if "$group" == "control_2020" {

* for matching (for 2019 comparison)
gen exposed = 0 
gen yob = 2019 - age
}

******************************
*  Convert strings to dates  *
******************************

* To be added: dates related to outcomes
foreach var of varlist 	dvt 							///
						diabetes						///	
						pe  							///
						stroke 							///
						hypertension					///		
						bmi_date_measured				///
						{
	capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		replace `var' = `var' + "-15"
		rename `var' `var'_dstr
		replace `var'_dstr = " " if `var'_dstr == "-15"
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}


/* BMI */

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)

**********************
*  Recode variables  *
**********************


/*  Demographics  */

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex

gen gender = male 
drop male
label define genderLab 1 "male" 0 "female"
label values gender genderLab
label var gender "gender = 0 F, 1 M"


* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"
gen     smoke = 1  if smoking_status_1=="N"
replace smoke = 2  if smoking_status_1=="E"
replace smoke = 3  if smoking_status_1=="S"
replace smoke = .u if smoking_status_1=="M"
replace smoke = .u if smoking_status_1==""
label values smoke smoke
drop smoking_status_1


* Ethnicity (5 category)
rename ethnicity ethnicity_5
replace ethnicity_5 = .u if ethnicity_5==.
label define ethnicity 	1 "White"  								///
						2 "Mixed" 								///
						3 "Asian or Asian British"				///
						4 "Black"  								///
						5 "Other"								///
						.u "Unknown"
label values ethnicity_5 ethnicity


/*  Geographical location  */


* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old


/* Region
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
						2 "East"  							///
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
*/


**************************
*  Categorise variables  *
**************************

/*  Age variables  */ 

* Create categorised age
recode 	age 			18/39.9999=1 	///
						40/49.9999=2 	///
						50/59.9999=3 	///
						60/69.9999=4 	///
						70/79.9999=5 	///
						80/max=6, 		///
						gen(agegroup) 

label define agegroup 	1 "18-<40" 		///
						2 "40-<50" 		///
						3 "50-<60" 		///
						4 "60-<70" 		///
						5 "70-<80" 		///
						6 "80+"
label values agegroup agegroup


* Check there are no missing ages
assert age<.
assert agegroup<.

/*  Body Mass Index  */

label define bmicat 	1 "Underweight (<18.5)" 				///
						2 "Normal (18.5-24.9)"					///
						3 "Overweight (25-29.9)"				///
						4 "Obese I (30-34.9)"					///
						5 "Obese II (35-39.9)"					///
						6 "Obese III (40+)"						///
						.u "Unknown (.u)"


	* Categorised BMI (NB: watch for missingness)
    gen 	bmicat = .
	recode  bmicat . = 1 if bmi<18.5
	recode  bmicat . = 2 if bmi<25
	recode  bmicat . = 3 if bmi<30
	recode  bmicat . = 4 if bmi<35
	recode  bmicat . = 5 if bmi<40
	recode  bmicat . = 6 if bmi<.
	replace bmicat = .u  if bmi>=.
	label values bmicat bmicat

/*  IMD  */

* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = .u if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .u=.u

label define imd 	1 "1 least deprived"	///
					2 "2" 					///
					3 "3" 					///
					4 "4" 					///
					5 "5 most deprived" 	///
					.u "Unknown"
label values imd imd 






***************************
*  Grouped comorbidities  *
***************************


	
****************************************
*   Hba1c:  Level of diabetic control  *
****************************************

label define hba1ccat	0 "<6.5%"  		///
						1">=6.5-7.4"  	///
						2">=7.5-7.9" 	///
						3">=8-8.9" 		///
						4">=9"

* Set zero or negative to missing
	replace hba1c_percentage_1   = . if hba1c_percentage_1   <= 0
	replace hba1c_mmol_per_mol_1 = . if hba1c_mmol_per_mol_1 <= 0


	/* Express  HbA1c as percentage  */ 

	* Express all values as perecentage 
	noi summ hba1c_percentage_1 hba1c_mmol_per_mol_1
	gen 	hba1c_pct = hba1c_percentage_1 
	replace hba1c_pct = (hba1c_mmol_per_mol_1/10.929) + 2.15  ///
				if hba1c_mmol_per_mol_1<. 

	* Valid % range between 0-20  
	replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
	replace hba1c_pct = round(hba1c_pct, 0.1)


	/* Categorise hba1c and diabetes  */

	* Group hba1c
	gen 	hba1ccat_1 = 0 if hba1c_pct <  6.5
	replace hba1ccat_1 = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
	replace hba1ccat_1 = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
	replace hba1ccat_1 = 3 if hba1c_pct >= 8    & hba1c_pct < 9
	replace hba1ccat_1 = 4 if hba1c_pct >= 9    & hba1c_pct !=.
	label values hba1ccat_1 hba1ccat
	
	* Delete unneeded variables
	drop hba1c_pct hba1c_percentage_1 hba1c_mmol_per_mol_1 
	

********************************
*  Outcomes and survival time  *
********************************

/*
/*   Outcomes   */

* Format ONS death date
confirm string variable died_date_ons
rename died_date_ons died_date_ons_dstr
gen died_date_ons = date(died_date_ons_dstr, "YMD")
format died_date_ons %td
drop died_date_ons_dstr

* Note: There may be deaths recorded after end of our study (8 June)
* Set these to missing
replace died_date_ons = . if died_date_ons>d(8jun2020)

* Date of Covid death in ONS
gen died_date_onscovid = died_date_ons if died_ons_covid_flag_any==1
gen died_date_onsother = died_date_ons if died_ons_covid_flag_any!=1
drop died_date_ons

* Delete unneeded variables
drop died_ons_covid_flag_any 



/*  Binary outcome and survival time  */


* For training and internal evaluation: 
*   Outcome = COVID-19 death between cohort first and last date
gen onscoviddeath = died_date_onscovid <= d(8/06/2020)

* Survival time
gen 	stime = (died_date_onscovid - d(1/03/2020) + 1) if onscoviddeath==1
replace stime = (d(8/06/2020)       - d(1/03/2020) + 1)	if onscoviddeath==0


*/
* dummy pracid variable
generate pracid = floor((51)*runiform() + 1)

save "data/cohort_$group", replace 



