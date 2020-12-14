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

clear
do `c(pwd)'/analysis/global.do
global group `1'

use $outdir/matched_cohort_$group.dta, replace
cap log close
log using $outdir/cox_model_$group, replace t
global crude i.case
global age_sex i.case i.gender age1 age2 age3
global full i.case i.gender age1 age2 age3 i.obese4cat i.smoke_nomiss i.ethnicity i.imd i.htdiag_or_highbp  /// 
				i.chronic_respiratory_disease i.asthmacat i.chronic_cardiac_disease ///		
				i.diabcat i.cancer_exhaem_cat i.cancer_haem_cat i.chronic_liver_disease /// 		
				i.stroke_dementia i.other_neuro i.reduced_kidney_function_cat2 i.organ_transplant ///				
				i.spleen i.ra_sle_psoriasis i.other_immunosuppression

tempname measures
	postfile `measures' str13(comparison) str12(outcome) str12(analysis) str10(adjustment) str20(variable) category hr lc uc using $tabfigdir/cox_model_summary_$group, replace

foreach v in stroke dvt pe  {
preserve
* In hosp
noi di "Starting analysis for $group: `v' Outcome ..." 
	noi di "$group: stset in hospital" 
local a = "in_hosp"	
																	 
		stset `v'_in_hosp_end_date , id(patient_id) failure(`v'_in_hosp) enter(hospitalised_expo_date) origin(hospitalised_expo_date)
        
		foreach adjust in crude age_sex full {
		stcox $`adjust'
	
		matrix b = r(table)
		local hr= b[1,2]
		local lc = b[5,2] 
		local uc = b[6,2]
		local c = "Overall"
		local s = 0

		
		post `measures' ("$group") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
			
	    
		forvalues s = 0/1 {
			stcox $`adjust' if hist_`v' == `s'

			matrix b = r(table)
			local hr= b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]
			local c = "History of `v'"
		
	
			post `measures' ("$group") ("`v'") ("`a'")  ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
			
		}
		}

    * DROP Patients who have the event in hospital
    drop if `v'_in_hosp == 1 
    * post-hosp
	foreach a in post_hosp post_hosp_gp  {
		noi di "$group: stset in `a'" 
		
		stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(discharged_expo_date) origin(discharged_expo_date)
		
		foreach adjust in crude age_sex full {
		stcox $`adjust'

		matrix b = r(table)
		local hr= b[1,2]
		local lc = b[5,2] 
		local uc = b[6,2]
		local c = "Overall"
		local s = 0

		post `measures' ("$group") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
		

		forvalues s = 0/1 {
		
			stcox $`adjust' if hist_`v' == `s'

			matrix b = r(table)
			local hr= b[1,2]
			local lc = b[5,2] 
			local uc = b[6,2]
			local c = "History of `v'"
		
			
			post `measures' ("$group") ("`v'") ("`a'") ("`adjust'") ("`c'") (`s') 	///
						(`hr') (`lc') (`uc')
			
		}
		}
	}

restore			
}


postclose `measures'

* Change postfiles to csv
use $tabfigdir/cox_model_summary_$group, replace

export delimited using $tabfigdir/cox_model_summary_$group.csv, replace

log close
