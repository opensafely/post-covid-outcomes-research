********************************************************************************
*
*	Do-file:		000_cr_matches.do
*
*	Programmed by:	John (based on Krishnan) 
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
foreach outcome in primary {
forvalues v = 1/3 {
use  "data/cohort_`outcome'_covid_hosp", replace 
keep patient_id indexdate indexMonth practice_id exposed age gender 

* Match pneumonia patients in 2019 
if `v' == 1 {
append using "data/cohort_`outcome'_pneumonia_hosp", keep(patient_id indexdate indexMonth practice_id exposed age gender )
}

* Match controls in 2019 
if `v' == 2 {
append using "data/cohort_`outcome'_control_2019", keep(patient_id practice_id exposed age gender dvt_gp_date pe_gp_date other_vte_gp_date dvt_hospital_date pe_hospital_date other_vte_hospital_date dvt_ons pe_ons other_vte_ons stroke_gp_date stroke_hospital_date stroke_ons died_date_ons_date)

}

* Match pneumonia in 2020
if `v' == 3 {
append using "data/cohort_`outcome'_control_2020", keep(patient_id practice_id exposed age gender dvt_gp_date pe_gp_date other_vte_gp_date dvt_hospital_date pe_hospital_date other_vte_hospital_date dvt_ons pe_ons other_vte_ons stroke_gp_date stroke_hospital_date stroke_ons died_date_ons_date)
}

*frames reset

**********************************
* Separate exposed and unexposed *
**********************************
frame put if exposed ==1, into(tomatch)
keep if exposed==0
frame rename default pool

* need to set number of possible matches
* one match for pneumonia and two for controls
if `v' == 1 {
for num 1 : frame tomatch: gen long matchedto_X=.
local numMatch = 1
}
else {
for num 1/2 : frame tomatch: gen long matchedto_X=.
local numMatch = 2
}

* sort exposed indexdate
frame tomatch: sort indexdate 

frame tomatch: qui cou
local totaltomatch = r(N)

noi di "Matching progress out of `totaltomatch':"
noi di "****************************************"
* match 2 unexposed patients 
qui {
	
	
forvalues matchnum = 1/`numMatch' {
noi di "Getting match number `matchnum's"

	forvalues i = 1/`totaltomatch' {

		if mod(`i',100)==0 noi di "." _cont
		if mod(`i',1000)==0 noi di "`i'" _cont

		frame tomatch: scalar idtomatch = patient_id[`i']
		frame tomatch: scalar TMgender = gender[`i']
		frame tomatch: scalar TMage = age[`i']
		frame tomatch: scalar TMpractice_id = practice_id[`i']
		frame tomatch: global TMindexdate = indexdate[`i']
		di $TMindexdate
		
		if `v' == 1 {
		frame tomatch: scalar TMindexMonth = indexMonth[`i']
		}

		cap frame drop eligiblematches
		* Age gap +/- 3 years
		if `v' == 1 {
		frame put if gender==TMgender & practice_id==TMpractice_id & abs(age-TMage)<=3 & indexMonth==TMindexMonth, into(eligiblematches)
		}
		else {
		frame put if gender==TMgender & practice_id==TMpractice_id & abs(age-TMage)<=3, into(eligiblematches)
		}
		
		
		frame eligiblematches: cou
		if r(N)>=1 {
			frame eligiblematches: gen u=uniform()
			frame eligiblematches: gen agediff=abs(age-TMage)
			frame eligiblematches: sort agediff u
			
		if `v'  == 3  {	
			* At the covid/pneumonia patients indexdate check matches against exclusion criteria 
			frame eligiblematches: replace indexdate = $TMindexdate if indexdate == .
			frame eligiblematches: format indexdate %td
		
				if "`outcome'" == "primary" {
			frame eligiblematches: gen exclude_primary = cond(stroke_gp_date <= indexdate | 		/// 
						   stroke_hospital_date <= indexdate | ///
						   dvt_gp_date <= indexdate | ///
						   dvt_hospital_date <= indexdate| ///
						   pe_gp_date <= indexdate | ///
						   pe_hospital_date <= indexdate | ///
						   died_date_ons_date <=  indexdate , 1, 0  )
						   
			frame eligiblematches: drop if exclude_primary == 1			   
												}
				if "`outcome'" == "secondary" {
			frame eligiblematches: gen exclude_secondary  = cond(stroke_hospital_date <= indexdate | ///
						   dvt_hospital_date <= indexdate | ///
						   pe_hospital_date <= indexdate | ///
						   died_date_ons_date <=  indexdate , 1, 0  )
						   
		     frame eligiblematches: drop if exclude_secondary == 1		
													}		
			}
						   
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


save "data/cr_matches_`v'_`outcome'.dta", replace

frames reset
}

}