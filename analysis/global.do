*set filepaths
global projectdir `c(pwd)'
di "$projectdir"
global outdir $projectdir/output
di "$outdir"
global tabfigdir $projectdir/output/tabfig
di "$tabfigdir"

* Create directories required 
capture mkdir "$tabfigdir"

global dataEndDate td(01feb2021)

adopath + $projectdir/analysis/ado
