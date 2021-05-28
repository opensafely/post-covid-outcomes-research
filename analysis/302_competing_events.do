********************************************************************************
*
*	Do-file:		302_competing_events.do
*
*	Programmed by:	John 
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

cap log close
log using $outdir/competing_events.txt, replace t

tempname measures
	postfile `measures' ///
		str20(comparator) str20(outcome) str25(analysis) str10(adjustment) hr lc uc ///
		using $tabfigdir/fine_gray_summary, replace
		
		
		
foreach an in pneumonia gen_population {
use $outdir/combined_covid_`an'.dta, replace
drop patient_id
gen new_patient_id = _n

global crude i.case
global age_sex i.case i.male age1 age2 age3

global full i.case i.male age1 age2 age3 i.stp i.ethnicity i.imd i.obese4cat /// 
	i.smoke htdiag chronic_respiratory_disease i.asthmacat chronic_cardiac_disease ///
	i.diabcat i.cancer_exhaem_cat i.cancer_haem_cat i.reduced_kidney_function_cat2  ///
	chronic_liver_disease stroke dementia other_neuro organ_transplant spleen ///
	ra_sle_psoriasis other_immunosuppression hist_dvt hist_pe hist_stroke hist_mi hist_aki hist_heart_failure	///
	


foreach v in stroke dvt pe heart_failure mi aki t2dm {

	if "`v'" == "stroke" {
	local lab = "Stroke"
	}
	if "`v'" == "dvt" {
	local lab = "DVT"
	}
	if "`v'" == "pe" {
	local lab = "PE"
	}
	if "`v'" == "heart_failure" {
	local lab = "Heart Failure"
	}
	if "`v'" == "mi" {
	local lab = "MI"
	}
	if "`v'" == "aki" {
	local lab = "AKI"
	}
	if "`v'" == "t2dm" {
	local lab = "T2DM"
	}
	

	
	noi di "Starting analysis for `v' Outcome ..." 

	
	forvalues i = 1/3 {
	
	preserve
	
	local skip_1 = 0
	local skip_2 = 0
	local skip_3 = 0
	
	* Apply exclusion for AKI and diabetes outcomes 
	if "`v'" == "t1dm" | "`v'" == "t2dm" {
	drop if previous_diabetes == 1
	local skip_2 = 1 
	local skip_3 = 1 
	}	
	
	if "`v'" == "aki" {
	drop if aki_exclusion_flag == 1
	}
	
	if `i' == 1 {
	local out `v'
	local end_date `v'_end_date
	}
	
	if `i' == 2 {
	local out `v'_no_gp
	local end_date `v'_no_gp_end_date
	}
	
	if `i' == 3 {
	local out `v'_cens_gp
	local end_date `v'_cens_gp_end_date
	}
	
		if `skip_`i'' == 0 {
		
		noi di "$group: stset in `a'" 
		
		* Set up variables
	    gen act_end_date = `end_date' - 1
		replace `out' = 2 if (died_date_ons_date == act_end_date) & ///
							 (died_date_ons_date != `v'_ons)
		
		stset `end_date', id(new_patient_id) enter(indexdate)  origin(indexdate) failure(`out'==1)
		
foreach adjust in crude age_sex full {
		    
			if "`adjust'" == "full" & "`v'" == "t2dm" {
			* remove diabetes
		global full i.case i.male age1 age2 age3 i.stp i.ethnicity i.imd i.obese4cat /// 
			i.smoke htdiag chronic_respiratory_disease i.asthmacat chronic_cardiac_disease ///
			i.cancer_exhaem_cat i.cancer_haem_cat i.reduced_kidney_function_cat2  ///
			chronic_liver_disease stroke dementia other_neuro organ_transplant spleen ///
			ra_sle_psoriasis other_immunosuppression hist_dvt hist_pe hist_stroke hist_mi hist_aki hist_heart_failure	///
			}
			
			
			stcrreg $`adjust', compete(`out'==2)  vce(robust)
			
			
			matrix b = r(table)
			local hr= b[1,1]
			local lc = b[5,1] 
			local uc = b[6,1]


			post `measures'  ("`an'") ("`v'") ("`out'") ("`adjust'")  ///
			
							(`hr') (`lc') (`uc')	
			
			}
		}
	
	if `i' == 3 {
	
		* Adjusted cuminc 
		stcompet cuminc = ci, by(case) compet1(2)
		gen cumInc = cuminc if `out'==1 // cumaltive inc of outcome accounting death as competing risk
		separate cumInc, by(case) veryshortlabel
		drop cuminc
		
		* max for time & cumulatives
		forvalues i = 0/1{
			sum `end_date' if case ==`i', meanonly
			local tmax`i' = r(max)
			sum cumInc`i', meanonly
			local cmax`i' = r(max)
		}

		* add extra points for plot 
		qui safecount 
		local obsSet1 = `r(N)' + 1
		local obsSet2 = `r(N)' + 2
		local obsSet3 = `r(N)' + 3
		set obs `obsSet3'
		replace cumInc0 = 0 in `obsSet1'
		replace cumInc1 = 0 in `obsSet1'
		replace _t = 0 in   `obsSet1'
		replace cumInc0 = `cmax0'   in `obsSet2'
		replace  _t = `tmax0'    in `obsSet2'
		replace cumInc1 = `cmax1'   in `obsSet3'
		replace  _t = `tmax1'    in `obsSet3'


		* Plot cumulative incidence functions for exp groups (accounting for death as a competing risk)
		#delimit ;
		twoway 	(line cumInc0 _t, sort c(J)) 
				(line cumInc1 _t, sort c(J)) ,
		
			ylabel(,angle(horizontal))
			plotregion(color(white))
			graphregion(color(white))
			ytitle("Cumulative Incidence")  
			xtitle("Time (Days)") 
		 ;
		#delimit cr	
			
		graph export "$tabfigdir/cumInc_`out'.png", width(2000)
		
	


	}
		
		
restore			
}
	
}


}
postclose `measures'

* Change postfiles to csv
use $tabfigdir/fine_gray_summary, replace

export delimited using $tabfigdir/fine_gray_summary.csv, replace

log close





	




