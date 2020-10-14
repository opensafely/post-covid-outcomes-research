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
set seed 12938

foreach outcome in primary {

use  "data/cohort_`outcome'_covid_hosp", replace 
keep patient_id indexdate indexMonth practice_id exposed age gender 

* Load pneumonia patients in 2019 
append using "data/cohort_`outcome'_pneumonia_hosp" , keep(patient_id indexdate indexMonth practice_id exposed age gender ///
														stroke_hospital_date stroke_gp_date ///
														dvt_hospital_date dvt_gp_date /// 
														pe_hospital_date pe_gp_date /// 
														died_date_ons_date)
														

**********************************
* Separate exposed and unexposed *
**********************************
frame put if exposed ==1, into(tomatch)
keep if exposed==0
frame rename default pool

***********************************************************
* Set number of possible matches - Two pneumonia patients *
***********************************************************

for num 1/2 : frame tomatch: gen long matchedto_X=.
local numMatch = 2

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

		* Matching variables
		frame tomatch: scalar idtomatch = patient_id[`i']
		frame tomatch: scalar TMgender = gender[`i']
		frame tomatch: scalar TMage = age[`i']
		frame tomatch: scalar TMpractice_id = practice_id[`i']
		frame tomatch: global TMindexdate = indexdate[`i']
		di $TMindexdate
		
		frame tomatch: scalar TMindexMonth = indexMonth[`i']


		cap frame drop eligiblematches
	
		* Matching criteria:
		* Gender, practice, age within 3 yrs, index month 
		frame put if gender==TMgender & practice_id==TMpractice_id & abs(age-TMage)<=5 & indexMonth==TMindexMonth, into(eligiblematches)

		frame eligiblematches: cou
		if r(N)>=1 {
			frame eligiblematches: gen u=uniform()
			frame eligiblematches: gen agediff=abs(age-TMage)
			frame eligiblematches: sort agediff u
			   
			frame eligiblematches: scalar selectedmatch = patient_id[1] 
			
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
		else scalar selectedmatch = -999

		frame tomatch: replace matchedto_`matchnum' = selectedmatch in `i'
		drop if patient_id==selectedmatch

	}
}
}

frame change tomatch
keep patient_id matchedto* 

save "data/cr_matches_pneumonia_`outcome'", replace
frames reset
}