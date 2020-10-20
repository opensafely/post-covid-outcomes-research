
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
* Open a log file
capture log close
log using "output/103_cr_control_2019_matches", text replace

set seed 12938

foreach outcome in primary {

use  "data/cr_matched_cohort_`outcome'", replace 
keep if flag == "pneumonia_hosp"
keep patient_id indexdate indexMonth practice_id exposed age gender setid stp
replace exposed = 1
replace patient_id = setid
* Load control patients in 2019 
append using "data/cohort_`outcome'_control_2019", keep(patient_id practice_id exposed age gender ///
														stroke_hospital_date stroke_gp_date ///
														dvt_hospital_date dvt_gp_date /// 
														pe_hospital_date pe_gp_date /// 
														died_date_ons_date stp)
														
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

noi di ""
noi di "****************************************"
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
		frame tomatch: global TMstp = stp[`i']
		di $TMindexdate
		
		frame tomatch: scalar TMindexMonth = indexMonth[`i']


		cap frame drop eligiblematches
	
		* Matching criteria:
		* Gender, stp, age +/- 1 yr
		frame put if gender==TMgender & stp=="$TMstp" & abs(age-TMage)<=1, into(eligiblematches)

		frame eligiblematches: cou
		if r(N)>=1 {
			frame eligiblematches: gen u=uniform()
			frame eligiblematches: gen agediff=abs(age-TMage)
			frame eligiblematches: sort agediff u
			   
			frame eligiblematches: scalar selectedmatch = patient_id[1] 
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
		else scalar selectedmatch = -999

		frame tomatch: replace matchedto_`matchnum' = selectedmatch in `i'
		drop if patient_id==selectedmatch

	}
}
}

frame change tomatch
keep patient_id matchedto* 

 noi di ""
noi di "****************************************"
noi di "Matching Report:"
noi di "****************************************"


forvalues reportMatch = 1/`numMatch' {
   qui safecount if matchedto_`reportMatch' != -999
   if `r(N)'!=. {
	local perC = round(100*`r(N)'/ `totaltomatch', 0.1)
noi di "Out of `totaltomatch' patients, `r(N)' (`perC' %) received `reportMatch' match"

}
else  {
	local perC = round(100*5/ `totaltomatch', 0.1)
noi di "Out of `totaltomatch' patients, <5 (`perC' %) received `reportMatch' match"


}

}

save "data/cr_matches_control_2019_`outcome'", replace
frames reset
}

log close
