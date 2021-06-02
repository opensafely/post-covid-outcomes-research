do `c(pwd)'/analysis/000_cr_define_covariates_simple_rates.do "covid"
do `c(pwd)'/analysis/000_cr_define_covariates_simple_rates.do "pneumonia"
do `c(pwd)'/analysis/000_cr_define_covariates_simple_rates.do "matched_combined_general_population"


do `c(pwd)'/analysis/201_cr_simple_rates.do "covid"
do `c(pwd)'/analysis/201_cr_simple_rates.do "pneumonia"
do `c(pwd)'/analysis/201_cr_simple_rates.do "gen_population"

do `c(pwd)'/analysis/400_baseline_characteristics.do 

do `c(pwd)'/analysis/300_cr_data_management_matching.do 

do `c(pwd)'/analysis/302_cox_models.do


do `c(pwd)'/analysis/302_competing_events.do

