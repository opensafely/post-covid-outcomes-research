********************************************************************************
*
*	Do-file:		model.do
*
*	Programmed by:	Alex & John
*
*	Data used:		output/input.csv

*	Data created:	a number of analysis datasets
*
*	Other output:	-
*
********************************************************************************
*
*	Purpose:		This do-file performs the data creation and preparation 
*					do-files. 
*  
********************************************************************************
import delimited "`c(pwd)'/output/input_covid.csv"

********** INSERT DATA END DATE ************
global dataEndDate td(01Sep2020)

set more off
cd  "`c(pwd)'"
adopath + "`c(pwd)'/analysis/ado"

/*  Pre-analysis data manipulation  */
global group "covid_hosp"
do "`c(pwd)'/analysis/000_cr_define_covariates.do"

clear 
import delimited "`c(pwd)'/output/input_pneumonia.csv"
global group "pneumonia_hosp"
do "`c(pwd)'/analysis/000_cr_define_covariates.do"

clear 
import delimited "`c(pwd)'/output/input_control_2019.csv"
global group "control_2019"
do "`c(pwd)'/analysis/000_cr_define_covariates.do"

clear 
import delimited "`c(pwd)'/output/input_control_2020.csv"
global group "control_2020"
do "`c(pwd)'/analysis/000_cr_define_covariates.do"


/* Matching */
do "`c(pwd)'/analysis/101_cr_pneumonia_matches.do" 
if $matchFlag == 0 {
noi di "Low percentage of pneumonia patients matched " 
}
else{
do "`c(pwd)'/analysis/102_cr_matched_cohort_pneumonia.do" 
do "`c(pwd)'/analysis/103_cr_control_2019_matches.do" 
}

if $matchFlag1 == 0 {
noi di "Low percentage of controls in 2019 matched" 
}
else {
do "`c(pwd)'/analysis/104_cr_matched_cohort_control_2019.do"
do "`c(pwd)'/analysis/105_cr_control_2020_matches.do" 
}

if $matchFlag2 == 0 {
noi di "Low percentage of controls in 2020 matched" 
}
else {
do "`c(pwd)'/analysis/106_cr_matched_cohort_control_2020.do" 
}
