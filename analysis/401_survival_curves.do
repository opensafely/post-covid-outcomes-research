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
log using $outdir/survcurves_$group, replace t


foreach v in stroke dvt pe  {
preserve
* In hosp
noi di "Starting analysis for $group: `v' Outcome ..." 
	noi di "$group: stset in hospital" 
local a = "in_hosp"	
		
		stset `v'_in_hosp_end_date , id(patient_id) failure(`v'_in_hosp) enter(hospitalised_expo_date) origin(hospitalised_expo_date)
		* Label setting
		cap drop flag
		gen flag = "$group"
		replace flag = proper(flag)
		local graphLab = flag[1]
		* Crude cox
		stcox i.case 
		* Survival curve
		#delimit ; 
		stcurv, surv at1(case=0) at2(case=1)
		title("")
		legend(
			order(1 "`graphLab'" 2 "Covid-19")
			rows(1)
			symxsize(*0.4)
			size(small)
		  ) 
		  ylabel(,angle(horizontal))
		  plotregion(color(white))
		  graphregion(color(white))
		ytitle("Survival Probability" )  
		xtitle("Time (Days)" ) 
		  ;
		 #delimit cr
		
		graph export $tabfigdir/survcurv_`a'_`v'_$group.svg , as(svg) replace
		
		forvalues s = 0/1 {
				* Survival curve
		stcox i.case hist_`v'

		#delimit ; 
		stcurv, surv at1(case=0 hist_`v'=`s') at2(case=1 hist_`v'=`s')
	    title("")
		legend(
			order(1 "`graphLab'" 2 "Covid-19")
			rows(1)
			symxsize(*0.4)
			size(small)
		  ) 
		  ylabel(,angle(horizontal))
		  plotregion(color(white))
		  graphregion(color(white))
		ytitle("Survival Probability" )  
		xtitle("Time (Days)" ) 
		  ;
		 #delimit cr
		
		graph export $tabfigdir/survcurv_`a'_`v'_history_`s'_$group.svg , as(svg) replace
			
	}
	

	* DROP Patients who have the event in hospital
	drop if `v'_in_hosp == 1
	drop if died_date_ons_date <= discharged_expo_date

	* post-hosp
	foreach a in post_hosp post_hosp_gp  {
		noi di "$group: stset in `a'" 
		
		stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a') enter(discharged_expo_date) origin(discharged_expo_date)
		
		* Label setting
		cap drop flag
		gen flag = "$group"
		replace flag = proper(flag)
		local graphLab = flag[1]
		* Crude cox
		stcox i.case 
		* Survival curve
		#delimit ; 
		stcurv, surv at1(case=0) at2(case=1)
	    title("")
		legend(
			order(1 "`graphLab'" 2 "Covid-19")
			rows(1)
			symxsize(*0.4)
			size(small)
		  ) 
		  ylabel(,angle(horizontal))
		  plotregion(color(white))
		  graphregion(color(white))
		ytitle("Survival Probability" )  
		xtitle("Time (Days)" ) 
		  ;
		 #delimit cr
		 
		 graph export $tabfigdir/survcurv_`a'_`v'_$group.svg , as(svg) replace
		
		

			forvalues s = 0/1 {
			
		* Survival curve
		stcox i.case hist_`v'

		#delimit ; 
		stcurv, surv at1(case=0 hist_`v'=`s') at2(case=1 hist_`v'=`s')
	    title("")
		legend(
			order(1 "`graphLab'" 2 "Covid-19")
			rows(1)
			symxsize(*0.4)
			size(small)
		  ) 
		  ylabel(,angle(horizontal))
		  plotregion(color(white))
		  graphregion(color(white))
		ytitle("Survival Probability" )  
		xtitle("Time (Days)" ) 
		  ;
		 #delimit cr
		
		graph export $tabfigdir/survcurv_`a'_`v'_history_`s'_$group.svg , as(svg) replace
		}
	}
restore			
}


log close
