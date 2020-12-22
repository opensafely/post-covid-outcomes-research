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

foreach v in covid pneumonia control_2019 control_2020 {
*Set up output file
cap file close tablecontent
file open tablecontent using $tabfigdir/an_descriptiveTable_`v'.txt, write text replace

if "`v'" == "covid" {
use $outdir/matched_cohort_pneumonia.dta, clear 
keep if case == 1
}
else {
use $outdir/matched_cohort_`v'.dta, clear 
keep if case == 0
}

gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) 
file write tablecontent _n 

tabulatevariable, variable(agegroup) start(1) end(5)  
file write tablecontent _n 

tabulatevariable, variable(gender) start(0) end(1) 
file write tablecontent _n 

tabulatevariable, variable(obese4cat) start(1) end(4) 
file write tablecontent _n 

tabulatevariable, variable(smoke_nomiss) start(1) end(3) 
file write tablecontent _n 

tabulatevariable, variable(ethnicity) start(1) end(5) missing 
file write tablecontent _n 

tabulatevariable, variable(imd) start(1) end(5) 
file write tablecontent _n _n

*tabulatevariable, variable(bpcat) start(1) end(4) missing 
tabulatevariable, variable(htdiag_or_highbp) start(1) end(1) 			

**COMORBIDITIES
*RESPIRATORY
tabulatevariable, variable(chronic_respiratory_disease) start(1) end(1) 
*ASTHMA
tabulatevariable, variable(asthmacat) start(2) end(3)  /*no ocs, then with ocs*/
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
tabulatevariable, variable(reduced_kidney_function_cat2) start(2) end(5) 
/*DIALYSIS
tabulatevariable, variable(dialysis) start(1) end(1) */
*LIVER
tabulatevariable, variable(chronic_liver_disease) start(1) end(1) 
*DEMENTIA
tabulatevariable, variable(stroke_dementia) start(1) end(1) 
*OTHER NEURO
tabulatevariable, variable(other_neuro) start(1) end(1) 
*ORGAN TRANSPLANT
tabulatevariable, variable(organ_transplant) start(1) end(1) 
*SPLEEN
tabulatevariable, variable(spleen) start(1) end(1) 
*RA_SLE_PSORIASIS
tabulatevariable, variable(ra_sle_psoriasis) start(1) end(1) 
*OTHER IMMUNOSUPPRESSION
tabulatevariable, variable(other_immunosuppression) start(1) end(1) 

cou
local denom = r(N)
cou if obese==1
local bmimissing=r(N)
cou if smoke==.
local smokmissing=r(N)
file write tablecontent _n ("*missing BMI included in 'not obese' (n = ") (`bmimissing') (" (") %3.1f (100*`bmimissing'/`denom') ("%); missing smoking included in 'never smoker' (n = ") (`smokmissing') (" (") %3.1f (100*`smokmissing'/`denom') ("%))") 


file close tablecontent
}
