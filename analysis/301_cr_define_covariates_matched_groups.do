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

local start_date_20  td(01/02/2020)
local last_year_20   td(01/02/2019)
local four_years_ago_20 td(01/02/2015)	 
local fifteen_months_ago_20 td(01/09/2019)
local end_date_20 td(01/10/2020)

local start_date_19 td(01/02/2019)
local last_year_19  td(01/02/2018)	
local four_years_ago_19 td(01/02/2014)	 
local fifteen_months_ago_19 td(01/09/2018)
local end_date_19 td(01/10/2019)


use $outdir/matched_combined_$group.dta, replace

di "STARTING COUNT FROM IMPORT:"
noi safecount

* Hospitalised with exposure (expo -> covid or pneumonia)
gen hospitalised_expo_date = date(exposure_hospitalisation, "YMD")
format hospitalised_expo_date %td

if "$group" == "pneumonia"{
	drop if hospitalised_expo_date ==.
}

gen discharged_expo_date = date(exposure_discharge, "YMD")
format discharged_expo_date %td

drop if discharged_expo_date ==.

drop if discharged_expo_date > `end_date_20' & year_20==1
drop if discharged_expo_date > `end_date_19' & year_20==0


if "$group" == "pneumonia"{
	drop if discharged_expo_date < hospitalised_expo_date
}

* Hospitalised covid/pneumonia is primary dx
gen hospitalised_expo_primary_dx = date(exposure_hosp_primary_dx, "YMD")
format hospitalised_expo_primary_dx %td 


gen indexdate= hospitalised_expo_date
format indexdate %td
gen indexMonth = month(hospitalised_expo_date)

******************************
*  Convert strings to dates  *
******************************
drop hiv
rename hiv_date hiv
* To be added: dates related to outcomes
foreach var of varlist af 					///	
					   date_icu_admission   ///
					   dvt_gp_* 			///
					   pe_gp_* 				///
					   dvt_hospital_*	 	///
					   pe_hospital_* 		///
					   other_vte_hospital 	///
					   stroke_gp_* 			///
					   stroke_hospital_*  	///
					   died_date_ons 		///
					   bmi_date_measured 	///
					   hypertension 		/// 
					   previous_stroke_gp   ///
					   previous_stroke_hospital /// 
					   previous_vte_gp   	///
					   previous_vte_hospital ///
					   previous_dvt_gp 		/// 
					   previous_dvt_hospital /// 
					   previous_pe_gp 		 /// 
					   previous_pe_hospital  ///
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

foreach var of varlist	diabetes                        ///
						chronic_respiratory_disease     ///
						chronic_cardiac_disease         ///
						chronic_liver_disease           ///
						stroke_for_dementia_defn        ///
						dementia                        ///
						other_neuro                     ///
						organ_transplant                ///
						aplastic_anaemia                ///
						dysplenia                       ///
						sickle_cell                     ///
						hiv                             ///
						permanent_immunodeficiency      ///
						temporary_immunodeficiency      ///
						ra_sle_psoriasis                ///
						lung_cancer                     ///
						other_cancer                    ///
						dialysis                        /// 
						haem_cancer                     ///
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

* Comorbidities ever before
foreach var of varlist	chronic_respiratory_disease_date 	///
						chronic_cardiac_disease_date 		///					///
						chronic_liver_disease_date 			///
						stroke_for_dementia_defn_date			///
						dementia_date						///
						other_neuro_date					///
						organ_transplant_date 				///
						aplastic_anaemia_date				///
						dysplenia_date 						///
						sickle_cell_date 					///
						hiv_date							///
						permanent_immunodeficiency_date		///
						temporary_immunodeficiency_date		///
						ra_sle_psoriasis_date ///
						dialysis_date ///
						lung_cancer_date ///
						other_cancer_date ///
						haem_cancer_date {
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'< `start_date_20') if year_20==1
	replace `newvar' = (`var'< `start_date_19') if year_20==0
	order `newvar', after(`var')
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
label define smoke 1 "Never" 2 "Former" 3 "Current" 

gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = . if smoking_status=="M"
label values smoke smoke
drop smoking_status

* Create non-missing 3-category variable for current smoking
recode smoke .=1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke

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
order bpcat bphigh, after(bp_dias_date)

/*  Asthma  */


* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3 .=1
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)




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

	* Create more granular categorisation
	recode bmicat 1/3 .u = 1 4=2 5=3 6=4, gen(obese4cat)

	label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
	label values obese4cat obese4cat
	order obese4cat, after(bmicat)

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


/*  Neurological  */

* Stroke and dementia
egen stroke_dementia = rowmax(stroke_for_dementia_defn dementia)
order stroke_dementia, after(dementia_date)


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen, after(sickle_cell)



/*  Cancer  */

label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

* Haematological malignancies
gen     cancer_haem_cat = 4 if inrange(haem_cancer_date, td(1/1/1900), `four_years_ago_20') & year_20 ==1 
replace cancer_haem_cat = 4 if inrange(haem_cancer_date, td(1/1/1900), `four_years_ago_19') & year_20 ==0 
replace cancer_haem_cat = 3 if inrange(haem_cancer_date, `four_years_ago_20', `last_year_20') & year_20 ==1 
replace cancer_haem_cat = 3 if inrange(haem_cancer_date, `four_years_ago_19', `last_year_19') & year_20 ==0
replace cancer_haem_cat = 2 if inrange(haem_cancer_date, `last_year_20', `start_date_20') & year_20 == 1
replace cancer_haem_cat = 2 if inrange(haem_cancer_date, `last_year_19', `start_date_19') & year_20 ==0
recode  cancer_haem_cat . = 1
label values cancer_haem_cat cancer


* All other cancers
gen     cancer_exhaem_cat = 4 if inrange(lung_cancer_date,  td(01/01/1900), `four_years_ago_20') | ///
								 inrange(other_cancer_date, td(01/01/1900), `four_years_ago_20')  & year_20 ==1
								 
replace     cancer_exhaem_cat = 4 if inrange(lung_cancer_date,  td(01/01/1900), `four_years_ago_19') | ///
								 inrange(other_cancer_date, td(01/01/1900), `four_years_ago_19')  & year_20 ==0
								 
replace cancer_exhaem_cat = 3 if inrange(lung_cancer_date, `four_years_ago_20', `last_year_20') | ///
								 inrange(other_cancer_date, `four_years_ago_20', `last_year_20') & year_20==1
								 
replace cancer_exhaem_cat = 3 if inrange(lung_cancer_date, `four_years_ago_19', `last_year_19') | ///
								 inrange(other_cancer_date, `four_years_ago_19', `last_year_19') & year_20==0
								 
replace cancer_exhaem_cat = 2 if inrange(lung_cancer_date,  `last_year_20', `start_date_20') | ///
								 inrange(other_cancer_date, `last_year_20', `start_date_20') & year_20==1
								 
replace cancer_exhaem_cat = 2 if inrange(lung_cancer_date,  `last_year_19', `start_date_19') | ///
								 inrange(other_cancer_date, `last_year_19', `start_date_19')	& year_20==0							 
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


* Put variables together
order cancer_exhaem_cat cancer_haem_cat, after(other_cancer_date)



/*  Immunosuppression  */

* Immunosuppressed:
* HIV, permanent immunodeficiency ever, OR 
* temporary immunodeficiency or aplastic anaemia last year
gen temp1  = max(hiv, permanent_immunodeficiency)
gen temp2  = inrange(temporary_immunodeficiency_date, `last_year_20', `start_date_20') & year_20 ==1 
replace temp2  = inrange(temporary_immunodeficiency_date, `last_year_19', `start_date_19') & year_20 ==0
gen temp3  = inrange(aplastic_anaemia_date, `last_year_20', `start_date_20') & year_20 ==1 
replace temp3  = inrange(aplastic_anaemia_date, `last_year_19', `start_date_19') & year_20 ==0

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
replace min = SCr_adj/0.7 if gender==0
replace min = SCr_adj/0.9 if gender==1
replace min = min^-0.329  if gender==0
replace min = min^-0.411  if gender==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if gender==0
replace max=SCr_adj/0.9 if gender==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if gender==0
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

	* Only consider measurements in last 15 months (this is done in the study definition/common variables)

	/* Express  HbA1c as percentage  */ 

	* Express all values as percentage 
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
	
	* Create diabetes, split by control/not
gen     diabcat = 1 if diabetes==.
replace diabcat = 2 if diabetes!=. & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if diabetes!=. & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if diabetes!=. & !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diabcat 	1 "No diabetes" 			///
						2 "Controlled diabetes"		///
						3 "Uncontrolled diabetes" 	///
						4 "Diabetes, no hba1c measure"
label values diabcat diabcat
	
	* Delete unneeded variables
	drop hba1c_pct hba1c_percentage_1 hba1c_mmol_per_mol_1 

*****************
* History of AF *
*****************

gen hist_of_af = cond(af < hospitalised_expo_date, 1, 0) 

***************************
* Hist of anticoagulation *
***************************	

gen hist_of_anticoag = .

levelsof indexMonth, local(months) 
foreach m of local months {

* Feb
if `m' == 2 {
replace hist_of_anticoag = 1 if (anticoag_rx_jan !=. | 	   ///
								anticoag_rx_prev_nov !=. | ///
								anticoag_rx_prev_dec !=.) & ///
								indexMonth == 2
}
* Mar
if `m' == 3 {
replace hist_of_anticoag = 1 if (anticoag_rx_jan !=. | 	   ///
								anticoag_rx_feb !=. | 	   ///
								anticoag_rx_prev_dec !=.) & ///
								indexMonth == 3
}
* Apr
if `m' == 4 {
replace hist_of_anticoag = 1 if (anticoag_rx_jan !=. | 	   ///
								anticoag_rx_feb !=. | 	   ///
								anticoag_rx_mar !=.) & 	   ///
								indexMonth == 4
}

* May
if `m' == 5 {
replace hist_of_anticoag = 1 if (anticoag_rx_feb !=. | 	   ///
								anticoag_rx_mar !=. | 	   ///
								anticoag_rx_apr !=.) & 	   ///
								indexMonth == 5
}

* Jun
if `m' == 6 {
replace hist_of_anticoag = 1 if (anticoag_rx_mar !=. | 	   ///
								anticoag_rx_apr !=. | 	   ///
								anticoag_rx_may !=.) & 	   ///
								indexMonth == 6
}

* Jul
if `m' == 7 {
replace hist_of_anticoag = 1 if (anticoag_rx_apr !=. | 	   ///
								anticoag_rx_may !=. | 	   ///
								anticoag_rx_jun !=.) & 	   ///
								indexMonth == 7
}

* Aug
if `m' == 8 {
replace hist_of_anticoag = 1 if (anticoag_rx_may !=. | 	   ///
								anticoag_rx_jun !=. | 	   ///
								anticoag_rx_jul !=.) & 	   ///
								indexMonth == 8
}

* Sep
if `m' == 9 {
replace hist_of_anticoag = 1 if (anticoag_rx_jun !=. | 	   ///
								anticoag_rx_jul !=. | 	   ///
								anticoag_rx_aug !=.) & 	   ///
								indexMonth == 9
}

* Oct
if `m' == 10 {
replace hist_of_anticoag = 1 if (anticoag_rx_jul !=. | 	   ///
								anticoag_rx_aug !=. | 	   ///
								anticoag_rx_sep !=.) & 	   ///
								indexMonth == 10
}

}

replace hist_of_anticoag = 0 if hist_of_anticoag == .	
	
	


**************
*  Outcomes  *
**************	
foreach o in stroke dvt pe {

	* Set all dates which are less than the hospitalised date to missing
	foreach v in feb mar apr may jun jul aug sep oct {
		replace `o'_gp_`v'_date =. if `o'_gp_`v'_date < hospitalised_expo_date 
		replace `o'_hospital_`v'_date =. if `o'_gp_`v'_date < hospitalised_expo_date 
	}
	* Select the minimum date of the dates as the outcome 
	gen `o'_gp = min(`o'_gp_feb_date, ///
						`o'_gp_mar_date, ///
						`o'_gp_apr_date, ///
						`o'_gp_may_date, ///
						`o'_gp_jun_date, ///
						`o'_gp_jul_date, ///
						`o'_gp_aug_date, ///
						`o'_gp_sep_date, ///
						`o'_gp_oct_date)
	format `o'_gp %td
	* remove outcomes after study end
	replace `o'_gp = . if `o'_gp > `end_date_20' & year_20==1
	replace `o'_gp = . if `o'_gp > `end_date_19' & year_20==0
	
	gen `o'_hospital = min(`o'_hospital_feb_date, ///
						`o'_hospital_mar_date, ///
						`o'_hospital_apr_date, ///
						`o'_hospital_may_date, ///
						`o'_hospital_jun_date, ///
						`o'_hospital_jul_date, ///
						`o'_hospital_aug_date, ///
						`o'_hospital_sep_date, ///
						`o'_hospital_oct_date)	
	format `o'_hospital %td
	* remove outcomes after study end
	replace `o'_hospital = . if `o'_hospital > `end_date_20' & year_20==1
	replace `o'_hospital = . if `o'_hospital > `end_date_19' & year_20==0
	
	* For ONS they will be dropped below if they have died before hospitalisation 
	* This just picks up the min value as this doesn't represent an exact YYYY-MM-DD date
	gen `o'_ons = min(`o'_ons_feb, ///
						`o'_ons_mar, ///
						`o'_ons_apr, ///
						`o'_ons_may, ///
						`o'_ons_jun, ///
						`o'_ons_jul, ///
						`o'_ons_aug, ///
						`o'_ons_sep, ///
						`o'_ons_oct)
}

* Note: There may be deaths recorded after end of our study
* Set these to missing
replace died_date_ons_date = . if died_date_ons_date > `end_date_20' & year_20==1
replace died_date_ons_date = . if died_date_ons_date > `end_date_19' & year_20==0


* Exclude those have died
drop if died_date_ons_date < hospitalised_expo_date 


foreach out in stroke dvt pe {

* Define history of dvt/pe/stroke at admission
gen hist_`out' = cond( ///
	( ///
		  previous_`out'_gp < discharged_expo_date ///
		| previous_`out'_hospital < discharged_expo_date ///
	) ///
	& previous_`out'_hospital != hospitalised_expo_date, ///
	1, 0 ///
)
						   
* Define outcome 

	di "in-hospital"
	gen `out'_in_hosp = cond( ///
		( ///
			  `out'_hospital >= hospitalised_expo_date /// after hosp admission
			& `out'_hospital <= discharged_expo_date /// before discharge
			& `out'_hospital != . /// and not missing
		) | ( ///
			  `out'_ons != . /// not missing means this COD is on death cert
			& died_date_ons_date >= hospitalised_expo_date /// after hosp admission
			& died_date_ons_date <= discharged_expo_date /// before discharge
			& died_date_ons_date != . /// this may be redundant
		), ///
		1, 0 ///
	)

	gen     `out'_in_hosp_end_date = discharged_expo_date
	replace `out'_in_hosp_end_date = died_date_ons if /// replace with death date
			  died_date_ons_date >= hospitalised_expo_date /// after hosp admission
			& died_date_ons_date <= discharged_expo_date /// before discharge
			& died_date_ons_date != . /// and not missing - this may be redundant
			& died_date_ons_date < `out'_in_hosp_end_date // otherwise it would overwrite earlier hosp dates
	replace `out'_in_hosp_end_date = `out'_in_hosp_end_date + 1 
	format %td `out'_in_hosp_end_date


	di "post-hospital (hosp + ons)"
	gen `out'_post_hosp = cond( ///
		( ///
			  `out'_hospital > discharged_expo_date /// after hosp discharge
			& `out'_hospital != . /// and not missing
			& `out'_in_hosp != 1 /// and no events in hospital
		) | ( ///
			  `out'_ons != . /// not missing means this COD is on death cert
			& died_date_ons_date > discharged_expo_date /// after hosp discharge
			& died_date_ons_date != . /// and not missing - this may be redundant
			& `out'_in_hosp != 1 /// and no events in hospital
		), ///
		1, 0 ///
	)

	gen 	`out'_post_hosp_end_date = `end_date_20' if year_20==1 // relevant end date
	replace `out'_post_hosp_end_date = `end_date_19' if year_20==0 // relevant end date
	replace  `out'_post_hosp_end_date = `out'_hospital if /// replace with hosp
		  `out'_hospital > discharged_expo_date /// after hosp discharge
		& `out'_hospital != . // and not missing
	replace `out'_post_hosp_end_date = died_date_ons_date if /// replace with death date
		  died_date_ons > discharged_expo_date /// after hosp discharge
		& died_date_ons_date != . /// and not missing
		& died_date_ons_date < `out'_post_hosp_end_date // otherwise it would overwrite earlier hosp dates
	replace `out'_post_hosp_end_date = `out'_post_hosp_end_date + 1 
	format %td `out'_post_hosp_end_date 



	di "post-hospital (+ primary care)"
	gen `out'_post_hosp_gp = cond( ///
		( ///
			  `out'_hospital > discharged_expo_date /// after hosp discharge
			& `out'_hospital != . /// and not missing
			& `out'_in_hosp != 1 /// and no events in hospital
		) | ( ///
			  `out'_gp > discharged_expo_date /// after hosp discharge
			& `out'_gp != . /// and not missing
			& `out'_in_hosp != 1 /// and no events in hospital
		) | ( ///
			  `out'_ons != . /// not missing means this COD is on death cert
			& died_date_ons_date > discharged_expo_date /// after hosp discharge
			& died_date_ons_date != . /// and not missing - this may be redundant
			& `out'_in_hosp != 1 /// and no events in hospital
		), ///
		1, 0 ///
	)

	gen 	`out'_post_hosp_gp_end_date = `end_date_20' if year_20==1
	replace `out'_post_hosp_gp_end_date = `end_date_19' if year_20==0
	replace  `out'_post_hosp_gp_end_date = `out'_hospital if ///
		  `out'_hospital > discharged_expo_date /// after hosp discharge
		& `out'_hospital != . // and not missing
	replace  `out'_post_hosp_gp_end_date = `out'_gp if ///
		  `out'_gp > discharged_expo_date /// after hosp discharge
		& `out'_gp != . /// and not missing
		& `out'_gp < `out'_post_hosp_gp_end_date // otherwise it would overwrite earlier gp dates
	replace `out'_post_hosp_gp_end_date = died_date_ons_date if ///
		  died_date_ons > discharged_expo_date ///
		& died_date_ons_date != . ///
		& died_date_ons_date < `out'_post_hosp_gp_end_date // otherwise it would overwrite earlier gp & hosp dates
	replace `out'_post_hosp_gp_end_date = `out'_post_hosp_gp_end_date + 1 
	format %td `out'_post_hosp_gp_end_date 
}
		
										
**** Tidy dataset
keep patient_id died_date_ons_date age ethnicity hospitalised_expo_date ///
 discharged_expo_date  gender agegroup hist_of_af ///
 hist_of_anticoag stroke_gp stroke_hospital stroke_ons dvt_gp  /// 
 dvt_hospital dvt_ons pe_gp pe_hospital pe_ons hist_stroke hist_dvt hist_pe /// 
 stroke_in_hosp stroke_in_hosp_end_date stroke_post_hosp stroke_post_hosp_end_date /// 
 stroke_post_hosp_gp stroke_post_hosp_gp_end_date dvt_in_hosp dvt_in_hosp_end_date ///
 dvt_post_hosp dvt_post_hosp_end_date dvt_post_hosp_gp dvt_post_hosp_gp_end_date ///
 pe_in_hosp pe_in_hosp_end_date pe_post_hosp pe_post_hosp_end_date pe_post_hosp_gp /// 
 pe_post_hosp_gp_end_date chronic_respiratory_disease chronic_cardiac_disease /// 
 cancer_exhaem_cat cancer_haem_cat chronic_liver_disease other_neuro /// 
 stroke_dementia organ_transplant spleen other_immunosuppression bpcat bphigh ///
 ra_sle_psoriasis asthmacat gender smoke bpcat_nomiss obese4cat imd htdiag_or_highbp smoke_nomiss ///
 reduced_kidney_function_cat2 diabcat case age*
 
save $outdir/matched_cohort_$group, replace 







