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
noi safecount

* Hospitalised with exposure (expo -> covid or pneumonia)

gen hospitalised_expo_date = date(exposure_hospitalisation, "YMD")
format hospitalised_ex_date %td

drop if hospitalised_ex_date ==.

gen discharged_expo_date = date(exposure_discharge, "YMD")
format discharged_expo_date %td

drop if discharged_expo_date ==.

drop if discharged_expo_date > $dataEndDate

drop if discharged_expo_date < hospitalised_expo_date
* for matching 
gen exposed = 1
gen indexdate= discharged_expo_date
format indexdate %td
gen indexMonth = month(discharged_expo_date)

gen flag = "covid_hosp"


******************************
*  Convert strings to dates  *
******************************

* To be added: dates related to outcomes
foreach var of varlist dvt_gp 				///
					   pe_gp 				///
					   other_vte_gp 		///
					   dvt_hospital			///
					   pe_hospital 			///
					   other_vte_hospital 	///
					   stroke_gp 			///
					   stroke_hospital  	///
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

**************
*  Outcomes  *
**************
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
							
	gen `out'_post_hosp_gp = cond( `out'_hospital >= discharged_expo_date  & `out'_hospital != . | ///
							`out'_gp >= discharged_expo_date & `out'_gp != . | ///
							(`out'_ons == 2020 &  died_date_ons >= discharged_expo_date & died_date_ons_date!=. )  , 1, 0  )

	gen `out'_post_hosp_gp_end_date = td(01oct2020) 
	replace  `out'_post_hosp_gp_end_date = `out'_hospital if `out'_hospital >= discharged_expo_date & `out'_hospital != .
	replace  `out'_post_hosp_gp_end_date = `out'_gp if `out'_gp >= discharged_expo_date & `out'_gp != .
	replace `out'_post_hosp_gp_end_date = died_date_ons_date if `out'_ons == 2020 &  died_date_ons >= discharged_expo_date & died_date_ons_date!=. 
	format %td `out'_post_hosp_gp_end_date 

	format %td `out'_post_hosp_gp_end_date 

	replace `out'_post_hosp_gp_end_date = `out'_post_hosp_gp_end_date + 1 

}
										

save "data/cohort_rates_$group", replace 







