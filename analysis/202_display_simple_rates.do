********************************************************************************
*
*	Do-file:		201_cr_simple_rates.do
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

* Change postfiles to csv

foreach v in covid_hosp pneumonia_hosp {
import delimited "released_output/rates_summary_`v'.csv", clear

save "released_output/rates_summary_`v'.dta", replace
}

use "released_output/rates_summary_covid_hosp.dta", clear
append using "released_output/rates_summary_pneumonia_hosp.dta"
* or 
foreach an in in_hosp post_hosp post_hosp_gp { 

if "`an'" == "in_hosp" {
local analysis = "In hospital" 
}

if "`an'" == "post_hosp" {
local analysis = "Post hospital (Hosp. only)"
}

if "`an'" == "post_hosp_gp" {
local analysis = "Post hospital (Hosp. & GP)"
}

foreach out in stroke pe dvt {
preserve
keep if outcome == "`out'" & analysis == "`an'"
* Change from per person-day to per 10000 person-months
drop rate_ppm lc_ppm uc_ppm
gen rate_ppm = 10000*(rate * 365.25 / 12)
gen lc_ppm = 10000*(lc * 365.25 /12)
gen uc_ppm = 10000*(uc * 365.25 /12)

replace persontime = (persontime / 365.25 *12 / 10000)
* sort
sort outcome analysis variable category

tostring category, gen(category2)

foreach i in community_exp hist_of_af hist_of_anticoag icu_admission long_hosp_stay {
replace category2 = "Yes" if variable == "`i'" & category==1
replace category2 = "No" if variable == "`i'" & category==0
}

replace category2 = "Yes" if variable == "hist_stroke" & category==1
replace category2 = "No" if variable == "hist_stroke" & category==0

replace category2 = "Yes" if variable == "hist_dvt" & category==1
replace category2 = "No" if variable == "hist_dvt" & category==0

replace category2 = "Yes" if variable == "hist_pe" & category==1
replace category2 = "No" if variable == "hist_pe" & category==0

replace variable = "History of Stroke" if variable == "hist_stroke"
replace	variable = "History of DVT" if variable == "hist_dvt"
replace variable = "History of PE" if variable == "hist_pe"

replace category2 = "Male" if variable == "gender" & category==1
replace category2 = "Female" if variable == "gender" & category==0

replace category2 = "White" if variable == "ethnicity" & category == 1
replace category2 = "Mixed" if variable == "ethnicity" & category == 2
replace category2 = "Asian or Asian British" if variable == "ethnicity" & category == 3
replace category2 = "Black" if variable == "ethnicity" & category == 4
replace category2 = "Other" if variable == "ethnicity" & category == 5
replace category2 = "Unknown" if variable == "ethnicity" & category == .u

replace category2 = "18-<50" if variable == "agegroup" & category==1
replace category2 = "50-<60" if variable == "agegroup" & category==2
replace category2 = "60-<70" if variable == "agegroup" & category==3
replace category2 = "70-<80" if variable == "agegroup" & category==4
replace category2 = "80+"	 if variable == "agegroup" & category==5

replace variable = "Age" if variable == "agegroup"
replace variable = "Gender" if variable == "gender"
replace variable = "Ethnicity" if variable == "ethnicity"
replace variable = "History of AF" if variable == "hist_of_af"
replace variable = "History of Anticoagulation" if variable == "hist_of_anticoag"
replace variable = "Length of Hosp. stay ({&ge} Median)" if variable == "long_hosp_stay"
replace variable = "Admitted to ICU" if variable == "icu_admission"

gen factor_order=1 if variable=="Overall"
replace factor_order=2 if variable=="History of Stroke" 
replace factor_order=2 if variable=="History of DVT" 
replace factor_order=2 if variable=="History of PE" 
replace factor_order=3 if variable=="Age" 
replace factor_order=4 if variable=="Gender"
replace factor_order=5 if variable=="Ethnicity"
replace factor_order=6 if variable=="History of AF"
replace factor_order=7 if variable=="History of Anticoagulation"
replace factor_order=8 if variable=="Length of Hosp. stay ({&ge} Median)"
replace factor_order=9 if variable=="Admitted to ICU"
replace factor_order=10 if variable=="Community Exposure"

replace outcome = "Stroke" if outcome == "stroke"
replace outcome = "DVT" if outcome == "dvt"
replace outcome = "PE" if outcome == "pe"

replace analysis = "In hospital" if analysis == "in_hosp"
replace analysis = "Post hospital (Hosp. only)" if analysis == "post_hosp"
replace analysis = "Post hospital (Hosp. & GP)" if analysis == "post_hosp_gp"

replace category2 = "" if variable == "Overall"

tostring persontime, gen(person_t_str) format (%3.1f) force

* Note: numevents already a string due to "REDACTED"
replace numevents  = "<5" if numevents =="REDACTED"

replace rate_ppm = 70 if rate == 0
replace lc_ppm = 70 if rate == 0
replace uc_ppm = 70 if rate == 0

tostring rate_ppm, gen(rate_ppm_str)   format(%3.1f)        force
tostring lc_ppm, gen(lc_ppm_str)   format(%3.1f)        force
tostring uc_ppm, gen(uc_ppm_str)   format(%3.1f)        force
gen result = rate_ppm_str + " " + "(" + lc_ppm_str + "-" + uc_ppm_str + ")"

* will loop over each outcome and analysis
*keep if outcome == "Stroke" & analysis == "In hospital"

* check these in actual results
*drop if rate_ppm ==. | rate_ppm ==0
sort analysis factor_order category group

* Graphing points
gen line2 = 100*_n
gen x0 = 0.00001
gen x1 = 0.007
gen x2 = 0.08
gen x3 = 250
gen x4 = 700
gen x7 = 2300
gen x5 = 0.007
gen x6 = 0.003

* 
replace variable = "" if _n!=1 & _n!=3 & _n!=7 & _n!=17 & _n!=21 & _n!=31 & _n!=35 & _n!=39 & _n!=43
replace variable = "Length of Hosp. stay" if _n==41
replace variable = "({&ge} Median)" if _n==43


forvalues i = 4(2)44 {
replace category2 = "" in `i'
}

if "`an'"!="post_hosp_gp" {
#delimit ; 
twoway (scatter line2 rate_ppm if group=="covid_hosp", ms(o) msize(*0.4) mcol(navy) ) // plot rate
	   (rspike lc_ppm uc_ppm line2 if group=="covid_hosp" , lcol(navy%60) horizontal) // plot CI rate
	   (scatter line2 rate_ppm if group=="pneumonia_hosp", ms(o) msize(*0.4) mcol(cranberry) ) // plot rate
	   (rspike lc_ppm uc_ppm line2 if group=="pneumonia_hosp" , lcol(cranberry%60) horizontal) // plot CI rate
	   (scatter line2 x3 , mlab(person_t_str) mlabsize(*0.5) ms(i) mlabpos(3) mlabcolor(black) ) // plot person time
	   (scatter line2 x4 , mlab(numevents) ms(i) mlabsize(*0.5)  mlabpos(0) mlabcolor(black)) // plot events
	   (scatter line2 x7 , mlab(result) ms(i) mlabsize(*0.5)  mlabpos(0) mlabcolor(black)) // plot  Estimates and CIs
	   (scatter line2 x1, mlab(variable) ms(i) mlabsize(*0.7) mlabpos(3) mlabcolor(black))  
	   (scatter line2 x2, mlab(category2) ms(i) mlabsize(*0.7) mlabpos(3) mlabcolor(black))  
	,
	title("`analysis'")
	xscale(log range(0.01 3000))
	xlab(5 10 20 40 80, format(%2.1f) labsize(small)) ylab( , nogrid )
	graphregion(style(none) color(white))
	yscale(reverse noextend) // plot 7 dashed line at 1.0
	yscale(off)
	legend(off)
	// Fixes titles	
	 text(-50.9 300 "{bf:Person-Time}" , size(*0.5) )
	 text(-170.9 750 "{bf:Num. of}" , size(*0.5) )
	text(-50.9 750 "{bf:Events}" , size(*0.5) )
	text(-50.9 2100 "{bf:Rate (95% CI)}" , size(*0.5) )
	name("`an'_`out'", replace)
	// text(-20.9 2100 "Rate per 100 person-months", size(vsmall)) // move by hand
	
;
#delimit cr
graph export "output/crude_rates_`an'_`out'.png", width(2000) replace
restore
}
else {

#delimit ; 
twoway (scatter line2 rate_ppm if group=="covid_hosp", ms(o) msize(*0.4) mcol(navy) ) // plot rate
	   (rspike lc_ppm uc_ppm line2 if group=="covid_hosp" , lcol(navy%60) horizontal) // plot CI rate
	   (scatter line2 rate_ppm if group=="pneumonia_hosp", ms(o) msize(*0.4) mcol(cranberry) ) // plot rate
	   (rspike lc_ppm uc_ppm line2 if group=="pneumonia_hosp" , lcol(cranberry%60) horizontal) // plot CI rate
	   (scatter line2 x3 , mlab(person_t_str) mlabsize(*0.5) ms(i) mlabpos(3) mlabcolor(black) ) // plot person time
	   (scatter line2 x4 , mlab(numevents) ms(i) mlabsize(*0.5)  mlabpos(0) mlabcolor(black)) // plot events
	   (scatter line2 x7 , mlab(result) ms(i) mlabsize(*0.5)  mlabpos(0) mlabcolor(black)) // plot  Estimates and CIs
	   (scatter line2 x1, mlab(variable) ms(i) mlabsize(*0.7) mlabpos(3) mlabcolor(black))  
	   (scatter line2 x2, mlab(category2) ms(i) mlabsize(*0.7) mlabpos(3) mlabcolor(black))  
	,
	title("`analysis'")	
	xscale(log range(0.01 3000))
	xlab(5 10 20 40 80, format(%2.1f) labsize(small)) ylab( , nogrid )
	legend(	order(1 "Covid-19"  3 "Pneumonia")
			cols(2)
			rows(1)
			symxsize(*0.4)
			size(small)
		  )
	graphregion(style(none) color(white))
	yscale(reverse noextend) // plot 7 dashed line at 1.0
	yscale(off)
	// Fixes titles	
	 text(-50.9 300 "{bf:Person-Time}" , size(*0.5) )
	 text(-170.9 750 "{bf:Num. of}" , size(*0.5) )
	text(-50.9 750 "{bf:Events}" , size(*0.5) )
	text(-50.9 2100 "{bf:Rate (95% CI)}" , size(*0.5) )
	name("`an'_`out'", replace)
	// text(-20.9 2100 "Rate per 100 person-months", size(vsmall)) // move by hand
	
;
#delimit cr
graph export "output/crude_rates_`an'_`out'.png", width(2000) replace
restore
}
}
}

foreach v in stroke pe dvt {
graph combine in_hosp_`v' post_hosp_`v' post_hosp_gp_`v', col(1)  ///  
																  ysize(10) ///
																  graphregion(style(none) color(white))
																  
graph export "output/combined_`v'.png", width(2000) replace		
}														  
