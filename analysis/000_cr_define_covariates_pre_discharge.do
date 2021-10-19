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
*	Purpose:		In response to reviewer comments about pre-discharge characteristics
*
*	Note:			
********************************************************************************
clear
do `c(pwd)'/analysis/global.do
global group `1'

if "$group" == "pre_covid_discharged"   { 
local start_date  td(01/02/2020)
local last_year   td(01/02/2019)
local four_years_ago td(01/02/2015)	 
local fifteen_months_ago td(01/09/2019)
local end_date td(01/02/2021)

}
else {
local start_date  td(01/02/2019)
local last_year   td(01/02/2018)	
local four_years_ago td(01/02/2014)	 
local fifteen_months_ago td(01/09/2018)
local end_date td(01/02/2020)
}


di "STARTING COUNT FROM IMPORT:"
noi safecount

* Indexdate
gen indexdate = date(patient_index_date, "YMD")
format indexdate %td

drop if indexdate ==.
drop patient_index_date

* remove any patient discharged after end date
drop if indexdate > `end_date'

******************************
*  Convert strings to dates  *
******************************
* To be added: dates related to outcomes
foreach var of varlist deregistered			///
					   date_icu_admission   ///
					   dvt_gp				///
					   pe_gp				///
					   dvt_hospital		 	///
					   pe_hospital			///
					   stroke_gp			///
					   stroke_ons			///
					   pe_ons 				///
					   dvt_ons		 		///
					   aki_gp       ///
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
* drop if died_date_ons <= indexdate // KEEP ALL PATIENTS

* Note: There may be deaths recorded after end of our study 
* Set these to missing
replace died_date_ons_date = . if died_date_ons_date>`end_date'

* Process variables with nearest month dates only						
						
foreach var of varlist 	bmi_date_measured 				///
						bp_sys_date_measured			///
						hba1c_mmol_per_mol_date			///
						hba1c_percentage_date			///
						haem_cancer						///
						lung_cancer						///
						other_cancer					///
						temporary_immunodeficiency		///
						aplastic_anaemia				{
						    confirm string variable `var'
							replace `var' = `var' + "-15"
							rename `var' `var'_dstr
							replace `var'_dstr = " " if `var'_dstr == "-15"
							gen `var'_date = date(`var'_dstr, "YMD") 
							order `var'_date, after(`var'_dstr)
							drop `var'_dstr
							format `var'_date %td
						}

rename bmi_date_measured_date      	bmi_date_measured
rename bp_sys_date_measured_date   	bp_sys_date
rename hba1c_percentage_date_date  	hba1c_percentage_date
rename hba1c_mmol_per_mol_date_date hba1c_mmol_per_mol_date



*******************************
*  Recode implausible values  *
*******************************

* BMI 

* Only keep if within certain time period? using bmi_date_measured ?
* NB: Some BMI dates in future or after cohort entry

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
label define sexLab 1 "male" 0 "female"
label values male sexLab
label var male "sex = 0 F, 1 M"

/*  IMD  */
* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = . if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .=.

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" 
label values imd imd 

noi di "DROPPING IF NO IMD" 
drop if imd>=.

* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" 

gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = . if smoking_status=="M"
label values smoke smoke
drop smoking_status


* Ethnicity (5 category)
replace ethnicity = 6 if ethnicity==.
label define ethnicity_lab 	1 "White"  								///
						2 "Mixed" 								///
						3 "Asian or Asian British"				///
						4 "Black"  								///
						5 "Other"								///
						6 "Unknown"
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
* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old

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

/*  Body Mass Index  */

* BMI (NB: watch for missingness)
gen 	bmicat = .
recode  bmicat . = 1 if bmi<18.5
recode  bmicat . = 2 if bmi<25
recode  bmicat . = 3 if bmi<30
recode  bmicat . = 4 if bmi<35
recode  bmicat . = 5 if bmi<40
recode  bmicat . = 6 if bmi<.
replace bmicat = . if bmi>=.

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			
					
label values bmicat bmicat


* Create more granular categorisation
recode bmicat 1/3 . = 1 4=2 5=3 6=4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
label values obese4cat obese4cat
order obese4cat, after(bmicat)

gen obese4cat_withmiss = obese4cat
replace obese4cat_withmiss =. if bmicat ==.


/*  Smoking  */


* Create non-missing 3-category variable for current smoking
recode smoke .=1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke

* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3 .=1
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)



/*  Blood pressure   */

* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = . if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 1 "Normal" 2 "Elevated" 3 "High, stage I"	///
					4 "High, stage II" 
label values bpcat bpcat

recode bpcat .=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat

* Create non-missing indicator of known high blood pressure
gen bphigh = (bpcat==4)
order bpcat bphigh, after(bp_sys_date)



***************************
*  Grouped comorbidities  *
***************************


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen, after(sickle_cell)



/*  Cancer  */

label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

gen fiveybefore = indexdate-5*365.25
gen oneybefore = indexdate-365.25

* Haematological malignancies
gen     cancer_haem_cat = 4 if inrange(haem_cancer_date, d(1/1/1900), fiveybefore)
replace cancer_haem_cat = 3 if inrange(haem_cancer_date, fiveybefore, oneybefore)
replace cancer_haem_cat = 2 if inrange(haem_cancer_date, oneybefore, indexdate)
recode  cancer_haem_cat . = 1
label values cancer_haem_cat cancer


* All other cancers
gen     cancer_exhaem_cat = 4 if inrange(lung_cancer_date,  d(1/1/1900), fiveybefore) | ///
								 inrange(other_cancer_date, d(1/1/1900), fiveybefore) 
replace cancer_exhaem_cat = 3 if inrange(lung_cancer_date,  fiveybefore, oneybefore) | ///
								 inrange(other_cancer_date, fiveybefore, oneybefore) 
replace cancer_exhaem_cat = 2 if inrange(lung_cancer_date,  oneybefore, indexdate) | ///
								 inrange(other_cancer_date, oneybefore, indexdate)
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


* Put variables together
order cancer_exhaem_cat cancer_haem_cat, after(other_cancer_date)



/*  Immunosuppression  */

* Immunosuppressed:
* HIV, permanent immunodeficiency ever, OR 
* temporary immunodeficiency or aplastic anaemia last year
gen temp1  = max(hiv, permanent_immunodeficiency)
gen temp2  = inrange(temporary_immunodeficiency_date, oneybefore, indexdate)
gen temp3  = inrange(aplastic_anaemia_date, oneybefore, indexdate)

egen other_immunosuppression = rowmax(temp1 temp2 temp3)
drop temp1 temp2 temp3
order other_immunosuppression, after(temporary_immunodeficiency)




/*  Hypertension  */

gen htdiag_or_highbp = bphigh
recode htdiag_or_highbp 0 = 1 if hypertension==1 


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
replace reduced_kidney_function_cat2 = 4 if dialysis==1 

label define reduced_kidney_function_cat2lab ///
	1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4 egfr 15-<30" 4 "Stage 5 egfr <15 or dialysis"
label values reduced_kidney_function_cat2 reduced_kidney_function_cat2lab 


* dialysis
if "$group" == "covid" | "$group" == "pneumonia"  { 
gen dialysis_flag = 1 if dialysis_date < hosp_expo_date
replace dialysis_flag = 0 if dialysis_flag ==.
}
if "$group" == "gen_population" | "$group" == "covid_community"{
gen dialysis_flag = 1 if dialysis_date < indexdate
replace dialysis_flag = 0 if dialysis_flag ==.
}

gen aki_exclusion_flag = 1 if egfr < 15 | dialysis_flag==1
replace aki_exclusion_flag = 0 if aki_exclusion_flag ==.

 
	
************
*   Hba1c  *
************
	

/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage<=0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol<=0


local fifteenmbefore = `studystart'-15*(365.25/12)

* Only consider measurements in last 15 months
replace hba1c_percentage   = . if hba1c_percentage_date   < `fifteenmbefore'
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol_date < `fifteenmbefore'



/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
tab hba1ccat

* Create diabetes, split by control/not
gen     diabcat = 1 if diabetes==0
replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diabcat 	1 "No diabetes" 			///
						2 "Controlled diabetes"		///
						3 "Uncontrolled diabetes" 	///
						4 "Diabetes, no hba1c measure"
label values diabcat diabcat

* Delete unneeded variables
drop hba1c_percentage* hba1c_mmol_per_mol* bmi_date_measured creatinine_date bp_sys_date *cancer_date aplastic_anaemia_date temporary_immunodeficiency_date SCr_adj min max egfr egfr_cat ckd hba1c_pct hba1ccat asthma diabetes reduced_kidney_function_cat bphigh dysplenia sickle_cell permanent_immunodeficiency hiv creatinine


**************
*  Outcomes  *
**************	

* The default deregistration date is 9999-12-31, so:
replace deregistered_date = . if deregistered_date > `end_date'

foreach out in stroke dvt pe heart_failure mi aki t1dm t2dm {

replace `out'_hospital = . if `out'_hospital > `end_date'
replace `out'_gp = . if `out'_gp > `end_date'
gen min_end_date = min(`out'_hospital, `out'_gp, died_date_ons_date, deregistered_date) // `out'_ons already captured in the study definition binary outcome


* 1) Define outcome using all data
replace `out' = 0 if min_end_date > `end_date'
gen 	`out'_end_date = `end_date' // relevant end date
replace `out'_end_date = min_end_date if  min_end_date!=.	 // not missing
replace `out'_end_date = `out'_end_date + 1 
format %td `out'_end_date 

drop min_end_date	

* 2) Define outcome using hospital data only
if  "`out'"!="t1dm" & "`out'"!="t2dm" {
gen min_end_date = min(`out'_hospital, died_date_ons_date, deregistered_date)
replace `out'_no_gp= 0 if min_end_date > `end_date'
gen 	`out'_no_gp_end_date = `end_date' // relevant end date
replace `out'_no_gp_end_date = min_end_date if  min_end_date!=.	 // not missing
replace `out'_no_gp_end_date = `out'_no_gp_end_date + 1 
format %td `out'_no_gp_end_date 

drop min_end_date	
}

* 3) Define outcome avoiding GP 'outcomes' if patient has a recent history
if "`out'"!="t1dm" & "`out'"!="t2dm" {
gen min_end_date = min(`out'_hospital, `out'_gp, died_date_ons_date, deregistered_date) if recent_`out' == 0
replace min_end_date = min(`out'_hospital, died_date_ons_date, deregistered_date) if recent_`out' == 1
replace `out'_cens_gp= 0 if min_end_date > `end_date'
gen 	`out'_cens_gp_end_date = `end_date' // relevant end date
replace `out'_cens_gp_end_date = min_end_date if  min_end_date!=.	 // not missing
replace `out'_cens_gp_end_date = `out'_cens_gp_end_date + 1 
format %td `out'_cens_gp_end_date 

drop min_end_date	
}

}



**** Tidy dataset


save $outdir/cohort_rates_$group, replace 


/*use $tabfigdir/recent_events_$group.dta, replace
export delimited using $tabfigdir/recent_events_$group.csv, replace*/
