********************************************************************************
*
*	Do-file:		202_cox_models.do
*
*	Programmed by:	John & Alex
*
*	Data used:		None
*
*	Data created:   None
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			
********************************************************************************
global crude i.exposed 
global age_sex i.exposed i.gender i.agegroup
global full i.exposed i.gender i.agegroup i.obese4cat i.smoke i.ethnicity i.imd i.htdiag_or_highbp  /// 
				i.chronic_respiratory_disease i.asthmacat i.chronic_cardiac_disease ///		
				i.diabcat i.cancer_exhaem_cat i.cancer_haem_cat i.chronic_liver_disease /// 		
				i.stroke_dementia i.other_neuro i.reduced_kidney_function_cat2 i.organ_transplant ///				
				i.spleen i.ra_sle_psoriasis i.other_immunosuppression

tempname measures
	postfile `measures' str13(comparison) str12(outcome) str12(analysis) str10(adjustment) str20(variable) category hr lc uc using "data/cox_model_summary", replace

forvalues t = 1/3 {

use "data/cr_matched_cohort", replace 

if `t' == 1 {
noi di "Covid vs pneumonia analysis"
keep if flag == "covid" | flag == "pneumonia"
}

if `t' == 2 {
noi di "Covid vs 2020 control analysis"
keep if flag == "covid" | flag == "control_2020"
}

if `t' == 3 {
noi di "Covid vs 2019 control analysis"
keep if flag == "covid" | flag == "control_2019"
}

foreach v in stroke dvt pe  {
preserve
* In hosp
noi di "Starting analysis for $group: `v' Outcome ..." 
	noi di "$group: stset in hospital" 
local a = "in_hosp"	
																	 
		stset `v'_in_hosp_end_date , id(patient_id) failure(`v'_in_hosp) enter(hospitalised_expo_date)
        
		foreach adjust in crude age_sex {
		stcox $`adjust'
	
		matrix b = r(table)
		local hr= b[1,2]
		local lc = b[5,2] 
		local uc = b[6,2]
		local c = "Overall"
		local s = 0

		if `t' == 1 {
		post `measures' ("covid_vs_pneu") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
		}
		if `t' == 2 {
		post `measures' ("covid_vs_ctl20") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 				///
						(`hr') (`lc') (`uc')
		}
		if `t' == 3 {
		post `measures' ("covid_vs_ctl19") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') ///
						(`hr') (`lc') (`uc')
		}			
	    
		forvalues s = 0/1 {
			stcox i.exposed $adjust if hist_`v' == `s'

			matrix b = r(table)
			local hr= b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]
			local c = "History of `v'"
		
			if `t' == 1 {
			post `measures' ("covid_vs_pneu") ("`v'") ("`a'")  ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
			}
			if `t' == 2 {
			post `measures' ("covid_vs_ctl20") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 				///
						(`hr') (`lc') (`uc')
			}
			if `t' == 3 {
			post `measures' ("covid_vs_ctl19") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') ///
						(`hr') (`lc') (`uc')
			}			
					
		}
		}

* DROP Patients who have the event in hospital
drop if `v'_in_hosp == 1 
* post-hosp
	foreach a in post_hosp post_hosp_gp {
		noi di "$group: stset in `a'" 
		
		stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(discharged_expo_date)
		
		foreach adjust in crude age_sex {
		stcox $`adjust'

		matrix b = r(table)
		local hr= b[1,2]
		local lc = b[5,2] 
		local uc = b[6,2]
		local c = "Overall"
		local s = 0

		if `t' == 1 {
		post `measures' ("covid_vs_pneu") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
		}
		if `t' == 2 {
		post `measures' ("covid_vs_ctl20") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 				///
						(`hr') (`lc') (`uc')
		}
		if `t' == 3 {
		post `measures' ("covid_vs_ctl19") ("`v'") ("`a'")  ("`adjust'") ("`c'") (`s') ///
						(`hr') (`lc') (`uc')
		}			
	    
		forvalues s = 0/1 {
		
			stcox $`adjust' if hist_`v' == `s'

			matrix b = r(table)
			local hr= b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]
			local c = "History of `v'"
		
			if `t' == 1 {
			post `measures' ("covid_vs_pneu") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
			}
			if `t' == 2 {
			post `measures' ("covid_vs_ctl20") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 				///
						(`hr') (`lc') (`uc')
			}
			if `t' == 3 {
			post `measures' ("covid_vs_ctl19") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') ///
						(`hr') (`lc') (`uc')
			}			
					
		}
		}
	}

restore			
}


} 

postclose `measures'

use "data/cox_model_summary", replace
