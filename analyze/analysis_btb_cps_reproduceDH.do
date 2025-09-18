* BTB: Reproduce CPS results in Doleac and Hansen (2020)

clear all
set more off
capture log close

log using "$analyze_log/analysis_btb_cps_reproduceDH.txt", text replace

********************************************************************************
***** Read in data and set up sample

*** the following dataset is made in "$build/build_dh_cps_data.do": ***
use "$analysis_data/dh_analysis_table.dta", clear

fvset base 2 metroFIPS
fvset base 60 age

local in_sample = ("male == 1 & age >= 25 & age <= 34  & citizen == 1 & retired == 0 & noCollege == 1")
keep if (`in_sample')

keep if (hryear4 >= 2004 & hryear4 <= 2014)

rename hrmonth month
rename hryear4 year
rename t time
replace time = time - 12
gen time_moyr = time + 527
format time_moyr %tm

local demo_controls "age highestEdu enrolledschool"
local demo_controls_int "group#age group#highestEdu group#enrolledschool"

egen id = group(hrhhid hrhhid2 pulineno)
egen id2 = group(hrhhid hrsample hrsersuf huhhnum pulineno)
replace id = id2 + 2000000 if id == .
drop id2


***** Merge on BTB laws from Doleac and Hansen (2020) replication files
merge m:1 year month time metroFIPS stateFIPS using "$analysis_data/dh_btb_policy_assignment_cps_original.dta"
drop _merge


***** BTB X race dummies
* dhBTB corresponds to the exact coding of BTB policies in Doleac and Hansen (2020) replication materials
gen dhBTBxBlackNH = dhBTB*black 
gen dhBTBxWhiteNH = dhBTB*white 
gen dhBTBxHisp = dhBTB*hispanic 


save "$analysis_data/dh_analysis_table_reproduced.dta", replace

***** Get cell counts
* Per month
preserve

keep if (metroFIPS != stateFIPS)

gen n = 1
collapse (sum) n, by(year month metroFIPS group blackNH whiteNH hispanic)
bys group: summ n, detail

restore 

* Per year
preserve

keep if (metroFIPS != stateFIPS)

gen n = 1
collapse (sum) n, by(year metroFIPS group blackNH whiteNH hispanic)
bys group: summ n, detail

restore 


* Per month
preserve

keep if (metroFIPS != stateFIPS)

keep if (dhBTB == 1)
gen n = 1
collapse (sum) n, by(year month metroFIPS group blackNH whiteNH hispanic)
bys group: summ n, detail

restore 

* Per year
preserve

keep if (metroFIPS != stateFIPS)

keep if (dhBTB == 1)
gen n = 1
collapse (sum) n, by(year metroFIPS group blackNH whiteNH hispanic)
bys group: summ n, detail

restore 


***** Reproduction of Table 4 in Doleac and Hansen
local demog = "age enrolledschool highestEdu group"
local demog_int = "age#group enrolledschool#group highestEdu#group"
local outcome "employed"


* appendix table a.2, column 1 (Doleac and Hansen, 2020, table 4, column 5--DH preferred specification): full sample with linear time trends
eststo m1: reghdfe `outcome' dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS##c.time)

qui summ `outcome' if (black == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* appendix table a.2, column 2 (Doleac and Hansen, 2020, table 4, column 6): MSAs only
eststo m2: reghdfe `outcome' dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp if (metroFIPS != stateFIPS), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS##c.time)

qui summ `outcome' if (black == 1 & dhBTB == 0 & dhBTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & dhBTB == 0 & dhBTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & dhBTB == 0 & dhBTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* appendix table a.2, column 3 (Doleac and Hansen, 2020, table 4, column 7): BTB-adopting only
eststo m3: reghdfe `outcome' dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp if (dhBTBever == 1), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS##c.time)

qui summ `outcome' if (black == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


local include_models "m1 m2 m3"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/tableA2.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent % Effect: Black" "hispanic_percent % Effect: Hispanic" "white_percent % Effect: White") sfmt(4 4 4 2 2 2) nomtitles keep(dhBTBx*) order(dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH) coeflabels(dhBTBxWhiteNH "DH BTB x White" dhBTBxBlackNH "DH BTB x Black" dhBTBxHisp "DH BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


log close