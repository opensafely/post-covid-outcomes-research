*an_tablecontent_PublicationDescriptivesTable
*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell "Table 1" (main cohort descriptives) for the Risk Factors paper
*
*Requires: final analysis dataset (cr_analysis_dataset.dta)
*
*Coding: Krishnan Bhaskaran
*
*Date drafted: 17/4/2020
*************************************************************************

clear
do `c(pwd)'/analysis/global.do
*******************************************************************************
*Generic code to output one row of table
cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string)
	
	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontent ("`variable'") _tab ("`condition'") _tab
	
	cou
	local overalldenom=r(N)
	
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent (`rowdenom')  (" (") %3.1f (`colpct') (")") _n

	/*cou if `outcome'==1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent (r(N)) (" (") %4.2f  (`pct') (")") _n*/

	
end

*******************************************************************************
*Generic code to output one section (varible) within table (calls above)
cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) start(real) end(real) [missing] 

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') condition("==`varlevel'") 
	}
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.") 

end

*******************************************************************************

foreach v in covid covid_community pneumonia gen_population  {
*Set up output file
cap file close tablecontent
file open tablecontent using $tabfigdir/an_descriptiveTable_`v'.txt, write text replace

use "$outdir/cohort_rates_`v'", clear

gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) 
file write tablecontent _n 

tabulatevariable, variable(agegroup) start(1) end(5)  
file write tablecontent _n 

tabulatevariable, variable(male) start(0) end(1) 
file write tablecontent _n 

tabulatevariable, variable(ethnicity) start(1) end(6)
file write tablecontent _n 

tabulatevariable, variable(ethnicity) start(1) end(7) 
file write tablecontent _n 

tabulatevariable, variable(obese4cat) start(1) end(4) 
file write tablecontent _n 

tabulatevariable, variable(smoke_nomiss) start(1) end(3) 
file write tablecontent _n 

tabulatevariable, variable(imd) start(1) end(5) 
file write tablecontent _n _n

tabulatevariable, variable(htdiag_or_highbp) start(1) end(1) 			

**COMORBIDITIES
*HYPERTENSION
tabulatevariable, variable(hypertension) start(1) end(1) 		
*RESPIRATORY
tabulatevariable, variable(chronic_respiratory_disease) start(1) end(1) 
*ASTHMA
tabulatevariable, variable(asthmacat) start(0) end(2)  /*no ocs, then with ocs*/
*CARDIAC
tabulatevariable, variable(chronic_cardiac_disease) start(1) end(1) 
*DIABETES
tabulatevariable, variable(diabcat) start(2) end(4)  /*controlled, then uncontrolled, then missing a1c*/
file write tablecontent _n
*CANCER EX HAEM
tabulatevariable, variable(cancer_exhaem_cat) start(2) end(4)  /*<1, 1-4.9, 5+ years ago*/
file write tablecontent _n
*CANCER HAEM
tabulatevariable, variable(cancer_haem_cat) start(2) end(4)  /*<1, 1-4.9, 5+ years ago*/
file write tablecontent _n
*REDUCED KIDNEY FUNCTION
tabulatevariable, variable(reduced_kidney_function_cat2) start(2) end(4) 
file write tablecontent _n
*LIVER
tabulatevariable, variable(chronic_liver_disease) start(1) end(1) 
file write tablecontent _n
*DEMENTIA
tabulatevariable, variable(dementia) start(1) end(1) 
file write tablecontent _n
*OTHER NEURO
tabulatevariable, variable(other_neuro) start(1) end(1) 
file write tablecontent _n
*SPLEEN
tabulatevariable, variable(spleen) start(1) end(1) 
file write tablecontent _n
*RA_SLE_PSORIASIS
tabulatevariable, variable(ra_sle_psoriasis) start(1) end(1) 
file write tablecontent _n
*OTHER IMMUNOSUPPRESSION
tabulatevariable, variable(other_immunosuppression) start(1) end(1) 
file write tablecontent _n

**History
tabulatevariable, variable(hist_dvt) start(1) end(1) 
file write tablecontent _n
tabulatevariable, variable(hist_stroke) start(1) end(1) 
file write tablecontent _n
tabulatevariable, variable(hist_pe) start(1) end(1) 
file write tablecontent _n
tabulatevariable, variable(hist_mi) start(1) end(1) 
file write tablecontent _n
tabulatevariable, variable(hist_aki) start(1) end(1) 
file write tablecontent _n
tabulatevariable, variable(hist_heart_failure) start(1) end(1) 
file write tablecontent _n
tabulatevariable, variable(previous_diabetes) start(1) end(1)


cou if bmicat==.
file write tablecontent _n _n ("*missing BMI included in 'not obese' ") (r(N)) 
cou if smoke==. 
file write tablecontent ("missing smoking in never: ") (r(N)) 


file close tablecontent
}
