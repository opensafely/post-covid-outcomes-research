
/****************************************************/
/***
Start with all exposed patients and pool of possible controls to be matched
Variables needed in the dataset at the outset
patid gender startdate enddate yob indexdate (for exposed patients)
***/
/****************************************************/
/*
syntax, cprddb(string) [practice gender yob yobwindow(real 1) followup dayspriorreg(real 0) ///
ctrlsperexp(real 4) updates(real 1000) getallpossible savedir(string) ///
filesuffix(string) dontcheck]
*/

* until pracid id known use following syntax

program define matchCohort
syntax,  [practice gender yob yobwindow(real 1) followup dayspriorreg(real 0) ///
ctrlsperexp(real 4) updates(real 1000) getallpossible savedir(string) ///
filesuffix(string) dontcheck]

if "`practice'"=="practice" local practice = 1
else local practice = 0
if "`gender'"=="gender" local gender = 1
else local gender = 0
if "`yob'"=="yob" local yob = 1
else local yob = 0
if "`followup'"=="followup" local followup = 1
else local followup = 0
if "`getallpossible'"=="getallpossible" local getallpossible = 1
else local getallpossible = 0

*CHECK ALL OPTIONS CORRECTLY SPECIFIED 
cap assert (`dayspriorreg'>=0) ///
& (`yobwindow'>=0 & `yobwindow'<=25) ///
& (`ctrlsperexp'>=1) ///
& (`getallpossible'==0|`getallpossible'==1) 
* /// & ("`cprddb'"=="gold"|"`cprddb'"=="aurum")
if _rc!=0 {
noi di as error "Error in options, please review: "
*noi di as error "cprddb must be specified and should be gold or aurum"
noi di as error "dayspriorreg should be >=0;" 
noi di as error "yobwindow should be >=0 and specified in years (values>25 not accepted)"
noi di as error "ctrlsperexp should be >=1"
error 198
}
cap assert (`practice'+`gender'+`yob'+`followup')>0
if _rc!=0 {
noi di as error "Error: no matching factors specified!"
error 198
}
if "`savedir'"=="" local savedir = "."
m: st_numscalar("de", direxists("`savedir'"))
if de==0 {
noi di as error "Error: specified save directory not found"
error 198
}

**
*CHECK ALL VARIABLES ARE PRESENT IN DATASET (if not, confirm will cause exit with error
confirm var patid 
if "`cprddb'"=="aurum" {
	cap confirm double var patid
	if _rc==7 { 
		noi di in red "Aurum patids should be stored as double to avoid rounding errors"
		error 7	
		}
	}
confirm var gender
confirm var startdate
confirm var enddate
confirm var yob
confirm var indexdate
**

*Display options to user and request confirmationh
noi di ""
noi di "About to match by: " 
if `practice'==1 noi di "practice... " 
if `gender'==1 noi di "gender..." 
if `yob'==1 noi di "year of birth (window `yobwindow' yrs)..." 
if `followup'==1 noi di "follow-up (requiring `dayspriorreg' days prior registration)..." 
if `practice'==0 noi di _n "Caution, matching without practice as a factor may take a while if overall pool is large"  _n
if `getallpossible'==0 noi di "Controls per exposed to be selected = `ctrlsperexp'"
if `getallpossible'==1 noi di "ALL POSSIBLE MATCHES PER EXPOSED TO BE RETRIEVED" _n "(no selection - just returns 'pool' of possible matches!)"
noi di ""
if "`savedir'"!="." noi di "Saving file 'getmatches' in `savedir'"
else noi di "Saving file 'getmatches`filesuffix'' in current working directory"
noi di ""
if "`dontcheck'"=="" {
noi di "CONTINUE? (y then enter to continue, anything else then enter to quit" _request(keyentry)
if "$keyentry"!="y" error 1
noi di "" 
}

tempfile dataaspresented
save `dataaspresented', replace

*pracid may be included in the dataset or not - if not it is generated here from patid
cap confirm var pracid
if _rc!=0 {
if "`cprddb'"=="gold" gen pracid=mod(patid,1000)
if "`cprddb'"=="aurum" gen pracid=mod(patid,100000)
}

tempvar sortunique
gen `sortunique'=runiform()
sort exposed indexdate `sortunique'


cou if exposed==1
local tomatch = r(N)

cap drop unexposed
cap drop taken 
cap drop rowno

gen byte unexposed = 1-exposed
gen byte taken = 0
gen rowno = _n

/*initial setup in mata*/
/*create views of exposed patients, and unexposed pool*/
mata {
EXPOSED=.
UNEXPOSED=.
st_view(EXPOSED, ., "patid pracid gender startdate enddate yob indexdate", "exposed")
st_view(UNEXPOSED, ., "patid pracid gender startdate enddate yob taken rowno", "unexposed")
}
if `practice'==1 splitpractices
else m: POINTRS=.

/*select matches according to specified criteria and return selections to mata matrix "MATCHES"*/
mata: MATCHES=selectmatches(EXPOSED, UNEXPOSED, POINTRS, ALLPRACIDS, `practice', `gender', `followup', `dayspriorreg', `yob', `yobwindow', `ctrlsperexp', `updates', `getallpossible')

clear
getmata (exposedid controlid) = MATCHES, double
sort exposedid controlid
expand 2 if exposedid!=exposedid[_n-1]
sort exposedid controlid
by exposedid controlid: gen byte exposed = (_n==1 & _N==2)
by exposedid controlid: replace controlid = exposedid if _n==1 & _N==2
rename controlid patid
rename exposedid setid

cou if exposed==1
local totalfoundmatch = r(N)

noi di
if (`tomatch'-`totalfoundmatch')>0 noi di "Warning: no matches at all found for " (`tomatch'-`totalfoundmatch') " exposed patients"
else noi di "At least 1 match found for all exposed patients"

/*Bring indexdate and enddate back in*/ 
if `getallpossible'==0 merge 1:1 patid exposed using `dataaspresented', keep(match) assert(match using) nogen keepusing(indexdate enddate)
if `getallpossible'==1 merge m:1 patid exposed using `dataaspresented', keep(match) assert(match using) nogen keepusing(indexdate enddate)

gsort setid -exposed
by setid: replace indexdate = indexdate[1]

save "`savedir'\getmatchedcohort`filesuffix'", replace

*Restore original data
use `dataaspresented', clear

end


/*SPLIT UNEXPOSED BY PRAC IF MATCHING BY PRACTICE (speeds up later matching process massively*/
cap prog drop splitpractices
program define splitpractices 
preserve
bysort pracid: keep if _n==1
m: ALLPRACIDS = st_data(., "pracid")
m: ALLPRACIDS = ((1..rows(ALLPRACIDS))', ALLPRACIDS)
restore

m: st_matrix("allpracids", ALLPRACIDS)
local npractices = rowsof(allpracids)
noi di ""
noi di "Pre-processing practice level data for `npractices' practices " _n "(to speed up later matching process)"
noi di ""
noi di "Progress (/`npractices'):"
forvalues i=1/`npractices' {
local j = el(allpracids,`i',2)
noi di _cont "."
if mod(`i', 10)==0 noi di _cont "`i'"
gen byte prac`j'=(pracid==`j')
mata {
P`j'=.
st_select(P`j', UNEXPOSED, UNEXPOSED[.,2]:==`j')
if (rows(P`j')>0) {
P`j'[.,8]=(1..rows(P`j'))' 
} ;
if (`i'==1) POINTRS = (&P`j')
else POINTRS = (POINTRS, &P`j')
}
drop prac`j'
}
noi di ""
noi di ""
end


/*MAIN FUNCTION TO APPLY MATCHING CRITERIA AND SELECT MATCHES*/
mata
matrix function selectmatches(EXPOSED, UNEXPOSED, POINTRS, ALLPRACIDS, real scalar matchbyprac, real scalar matchbygender, real scalar matchbyfup, real scalar dayspriorreg, real scalar matchbyyob, real scalar yobwindow, real scalar ctrlsperexp, real scalar updates, real scalar getallpossible) 
{

/*Set up dummy matrices for later use*/
SELECTprac=.
SELECTpracgender=.
SELECTpracgenderfup1=.
SELECTpracgenderfup2=.
SELECTpracgenderfup2yob=.
SELECTpracgenderfup2yobNYS=.
MATCHES=(0,0)

/*get number of cases*/
nEXPOSED=rows(EXPOSED)

"********************"
printf("Cases to match = %9.0g\n", nEXPOSED)
"********************"

"PROGRESS:"
timer_clear(2)
timer_on(2)
printf("done <%-9.0g\n", updates)
for (i=1; i<=nEXPOSED; i++){
if (mod(i,updates)==0) {
timer_off(2)
printf("done %-9.0g (last %-6.0g took %-6.0g secs)\n", i, updates, timer_value(2)[1,1])
timer_clear(2)
timer_on(2)
}
;

/*get case to match*/
PATTOMATCH=EXPOSED[i,.]


/*if matching by practice make a copy of the practice-level view (*POINTRS... below)*/
if (matchbyprac==1) SELECTprac = (*POINTRS[1,(select(ALLPRACIDS, ALLPRACIDS[.,2]:==PATTOMATCH[1,2])[1,1])]) 
else st_select(SELECTprac, UNEXPOSED, UNEXPOSED[.,1]:<.)

/*gender*/
if (matchbygender==1) st_select(SELECTpracgender, SELECTprac, (SELECTprac[.,3]:==PATTOMATCH[1,3]))
else st_select(SELECTpracgender, SELECTprac, (SELECTprac[.,1]:<.))

/*..fup (startfup must be <= indexdate; end must be >indexdate)*/
if (matchbyfup==1) {
st_select(SELECTpracgenderfup1, SELECTpracgender, (SELECTpracgender[.,4]:<=(PATTOMATCH[1,7]-dayspriorreg))) 
st_select(SELECTpracgenderfup2, SELECTpracgenderfup1, (SELECTpracgenderfup1[.,5]:>(PATTOMATCH[1,7]))) 
}
else st_select(SELECTpracgenderfup2, SELECTpracgender, (SELECTpracgender[.,1]:<.)) 

/*..year of birth*/
if (matchbyyob==1) st_select(SELECTpracgenderfup2yob, SELECTpracgenderfup2, (abs(SELECTpracgenderfup2[.,6]:-PATTOMATCH[1,6]):<=yobwindow)) 
else st_select(SELECTpracgenderfup2yob, SELECTpracgenderfup2, (SELECTpracgenderfup2[.,1]:<.)) 

if (getallpossible==0){

/*..not yet selected*/
st_select(SELECTpracgenderfup2yobNYS, SELECTpracgenderfup2yob, (SELECTpracgenderfup2yob[.,7]:==0)) 

/* randomly select required number of ctrls - prioritise by yob difference, then a random number, then pick top 4*/
nrowsinselection = rows(SELECTpracgenderfup2yobNYS)
if (nrowsinselection>0) SELECTION = (SELECTpracgenderfup2yobNYS,  (abs(SELECTpracgenderfup2yobNYS[.,6]:-PATTOMATCH[1,6])), runiform(nrowsinselection, 1))
else SELECTION = (SELECTpracgenderfup2yobNYS, SELECTpracgenderfup2yobNYS[.,6]:-PATTOMATCH[1,6], runiform(nrowsinselection, 1))
if (matchbyyob==1) SELECTION = sort(SELECTION, (9,10))
else SELECTION = sort(SELECTION, (10))
if (rows(SELECTION)>=ctrlsperexp) ntoselect=ctrlsperexp
else ntoselect = rows(SELECTION)
if (rows(SELECTION)>0) SELECTION = (SELECTION[1..ntoselect, 1], SELECTION[1..ntoselect, 8])
; 
/*Mark selected as "taken" in the pool*/
if (matchbyprac==1) {
for (p=1; p<=rows(SELECTION); p++){
(*POINTRS[1,(select(ALLPRACIDS, ALLPRACIDS[.,2]:==PATTOMATCH[1,2])[1,1])])[SELECTION[p,2],7]=1
}
}
else {
for (p=1; p<=rows(SELECTION); p++){
UNEXPOSED[SELECTION[p,2],7]=1
}
}

}
else {
SELECTION = SELECTpracgenderfup2yob[.,1]
}

/*record match*/
MATCHES = MATCHES \ J(rows(SELECTION),1,PATTOMATCH[1,1]), SELECTION[.,1]

}
MATCHES = MATCHES[2..rows(MATCHES),.]
return(MATCHES)
}
end






