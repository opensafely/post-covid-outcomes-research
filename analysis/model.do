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

