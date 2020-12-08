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
do `c(pwd)'/analysis/global.do
global group `1'

import delimited $outdir/input_$group.csv

di "STARTING COUNT FROM IMPORT:"
noi safecount

* Hospitalised with exposure (expo -> covid or pneumonia)

gen hospitalised_expo_date = date(exposure_hospitalisation, "YMD")
format hospitalised_expo_date %td

drop if hospitalised_expo_date ==.

gen discharged_expo_date = date(exposure_discharge, "YMD")
format discharged_expo_date %td

drop if discharged_expo_date ==.

drop if discharged_expo_date > $dataEndDate

drop if discharged_expo_date < hospitalised_expo_date

* Hospitalised covid/pneumonia is primary dx
gen hospitalised_expo_primary_dx = date(exposure_hosp_primary_dx, "YMD")
format hospitalised_expo_primary_dx %td 

gen community_exp = cond(hospitalised_expo_primary_dx !=. , 1, 0)

* Length of stay
gen length_of_stay = discharged_expo_date - hospitalised_expo_date + 1
label var length_of_stay "Length of stay in hospital (days)"
hist length , name(length_of_stay_$group, replace) graphregion(color(white)) col(navy%50) ylab(,angle(h)) lcol(navy%20)
graph export $outdir/length_of_stay_$group.svg , as(svg) replace

* Create flag for patients staying in hospital longer than the median length
summ length, detail
gen long_hosp_stay = cond(length_of_stay >= `r(p50)' , 1, 0)

* for matching 
gen exposed = 1
gen indexdate= hospitalised_expo_date
format indexdate %td
gen indexMonth = month(hospitalised_expo_date)

gen flag = "$group"


******************************
*  Convert strings to dates  *
******************************

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
					   diabetes 			///
					   previous_stroke_gp   ///
					   previous_stroke_hospital /// 
					   previous_vte_gp   	///
					   previous_vte_hospital ///
					   previous_dvt_gp 		/// 
					   previous_dvt_hospital /// 
					   previous_pe_gp 		 /// 
					   previous_pe_hospital  {

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

rename date_icu_admission_date icu_admission_date
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
gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = .u if smoking_status=="M"
replace smoke = .u if smoking_status==""
label values smoke smoke
drop smoking_status


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

/*  Age variables  */ 
assert age >= 18 & age <=110

* Create categorised age
recode 	age 			18/49.9999=1 	///
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
	
	

******************************************
* Admitted to ICU during hospitalisation *	
******************************************

gen icu_admission = cond( icu_admission_date >= hospitalised_expo_date & icu_admission_date <= discharged_expo_date , 1, 0) 


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
	
	* For ONS they will be dropped below if they have died before hospitalisation 
	* This just picks up the min value as this doesn't represent an exact YYYY-MM-DD date
    gen `o'_ons = min(`o'_hospital_feb_date, ///
						`o'_hospital_mar_date, ///
						`o'_hospital_apr_date, ///
						`o'_hospital_may_date, ///
						`o'_hospital_jun_date, ///
						`o'_hospital_jul_date, ///
						`o'_hospital_aug_date, ///
						`o'_hospital_sep_date, ///
						`o'_hospital_oct_date)
	
	

}

* Note: There may be deaths recorded after end of our study (08 Oct)
* Set these to missing
replace died_date_ons_date = . if died_date_ons_date>td(01oct2020)


* Exclude those have died
drop if died_date_ons < hospitalised_expo_date 

* Define history of dvt/pe/stroke at admission
gen hist_stroke = cond(previous_stroke_gp < hospitalised_expo_date | ///
						   previous_stroke_hospital < hospitalised_expo_date , 1, 0   )

gen hist_dvt = cond(previous_dvt_gp < hospitalised_expo_date | ///
						   previous_dvt_hospital < hospitalised_expo_date , 1, 0  )
						   
gen hist_pe = cond(previous_pe_gp < hospitalised_expo_date | ///
						   previous_pe_hospital < hospitalised_expo_date , 1, 0  )
						   
* Define outcome 
foreach out in stroke dvt pe {

	* in-hosital
	gen `out'_in_hosp = cond( (`out'_hospital >= hospitalised_expo_date & `out'_hospital <= discharged_expo_date & `out'_hospital != .) | ///
							(`out'_ons == 2020 & hospitalised_expo_date >= died_date_ons &  died_date_ons <= discharged_expo_date & died_date_ons_date!=. ) , 1, 0  )

	gen `out'_in_hosp_end_date =  td(01oct2020)
	replace `out'_in_hosp_end_date = `out'_hospital if `out'_hospital >= hospitalised_expo_date & `out'_hospital <= discharged_expo_date & `out'_hospital != .
	replace `out'_in_hosp_end_date = died_date_ons if `out'_ons == 2020 & hospitalised_expo_date >= died_date_ons &  died_date_ons <= discharged_expo_date & died_date_ons_date!=. 
	format %td `out'_in_hosp_end_date 

	replace `out'_in_hosp_end_date = `out'_in_hosp_end_date + 1 

	* post-hospital (hosp + ons)
	gen `out'_post_hosp = cond( `out'_hospital >= discharged_expo_date & `out'_hospital != . | ///
							(`out'_ons == 2020 &  died_date_ons >= discharged_expo_date & died_date_ons_date!=. ) , 1, 0  )

	gen `out'_post_hosp_end_date = td(01oct2020) 
	replace  `out'_post_hosp_end_date = `out'_hospital if `out'_hospital >= discharged_expo_date & `out'_hospital != .
	replace `out'_post_hosp_end_date = died_date_ons_date if `out'_ons == 2020 &  died_date_ons >= discharged_expo_date & died_date_ons_date!=. 
	format %td `out'_post_hosp_end_date 

	replace `out'_post_hosp_end_date = `out'_post_hosp_end_date + 1 

	* post-hospital (+ primary care)
							
	gen `out'_post_hosp_gp = cond( `out'_hospital >= discharged_expo_date  & `out'_hospital != .& `out'_in_hosp!=1 | ///
							`out'_gp >= discharged_expo_date & `out'_gp != . & `out'_in_hosp!=1 | ///
							(`out'_ons == 2020 &  died_date_ons >= discharged_expo_date & died_date_ons_date!=. )  , 1, 0  )

	gen `out'_post_hosp_gp_end_date = td(01oct2020) 
	replace  `out'_post_hosp_gp_end_date = `out'_hospital if `out'_hospital >= discharged_expo_date & `out'_hospital != .
	replace  `out'_post_hosp_gp_end_date = `out'_gp if `out'_gp >= discharged_expo_date & `out'_gp != .
	replace `out'_post_hosp_gp_end_date = died_date_ons_date if `out'_ons == 2020 &  died_date_ons >= discharged_expo_date & died_date_ons_date!=. 
	format %td `out'_post_hosp_gp_end_date 

	format %td `out'_post_hosp_gp_end_date 

	replace `out'_post_hosp_gp_end_date = `out'_post_hosp_gp_end_date + 1 

}
										
**** Tidy dataset
keep patient_id died_date_ons_date age ethnicity hospitalised_expo_date ///
 discharged_expo_date community_exp long_hosp_stay gender agegroup hist_of_af ///
 hist_of_anticoag icu_admission stroke_gp stroke_hospital stroke_ons dvt_gp  /// 
 dvt_hospital dvt_ons pe_gp pe_hospital pe_ons hist_stroke hist_dvt hist_pe /// 
 stroke_in_hosp stroke_in_hosp_end_date stroke_post_hosp stroke_post_hosp_end_date /// 
 stroke_post_hosp_gp stroke_post_hosp_gp_end_date dvt_in_hosp dvt_in_hosp_end_date ///
 dvt_post_hosp dvt_post_hosp_end_date dvt_post_hosp_gp dvt_post_hosp_gp_end_date ///
 pe_in_hosp pe_in_hosp_end_date pe_post_hosp pe_post_hosp_end_date pe_post_hosp_gp /// 
 pe_post_hosp_gp_end_date
 
save $outdir/cohort_rates_$group, replace 







