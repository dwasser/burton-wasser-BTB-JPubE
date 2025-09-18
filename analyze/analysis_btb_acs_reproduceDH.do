* BTB: Reproduce ACS results in Table A-13 from Doleac and Hansen (2020)

set more off
capture log close

log using "$analyze_log/analysis_btb_acs_reproduceDH.txt", text replace

********************************************************************************
local sample "sex == 1 & age >= 25 & age <= 34 & us_citizen == 1"
local demog = "age in_school educd"
local demog_int = "age#dh_group in_school#dh_group educd#dh_group"

********************************************************************************

*** the following dataset is made in "$build/build_acs_data.do": ***
use "$analysis_data/btb_acs_analysis_table.dta", clear


fvset base 2 metroFIPS
fvset base 60 age
fvset base 2004 year

***** Get cell counts
* Per year
preserve
keep if `sample'
keep if (no_coll_deg == 1)

keep if (metroFIPS != stateFIPS)

gen n = 1
collapse (sum) n, by(year metroFIPS dh_group dh_blackNH dh_whiteNH dh_hisp)
bys dh_group: summ n, detail

restore


preserve
keep if `sample'
keep if (no_coll_deg == 1)

keep if (metroFIPS != stateFIPS)

keep if (dhBTB == 1)
gen n = 1
collapse (sum) n, by(year metroFIPS dh_group dh_blackNH dh_whiteNH dh_hisp)
bys dh_group: summ n, detail

restore


***** Save table for use in CPS-ACS matching MSA-years specifications (Table A.8)
preserve
keep if `sample'
keep if (no_coll_deg == 1)

save "$analysis_data/dh_acs_analysistable_cps_acs_matching.dta", replace 

restore

*** analysis dataset ***
keep if `sample'
keep if (dh_noCollege == 1)


***** Regressions **************************************************************
eststo clear

local outcome "employed"

* appendix table a.3, column 1: full sample with linear time trends
eststo m1: reghdfe `outcome' dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH, vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.3, column 2 (Doleac and Hansen, 2020, table a.13, column 2): MSAs only 
eststo m2: reghdfe `outcome' dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH  if (metroFIPS != stateFIPS), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & dhBTB == 0 & dhBTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & dhBTB == 0 & dhBTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & dhBTB == 0 & dhBTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.3, column 3 (Doleac and Hansen, 2020, table a.13, column 3): BTB-adopting only 
eststo m3: reghdfe `outcome' dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH if (dhBTBever == 1), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.3, column 4 (Doleac and Hansen, 2020, table a.13, column 4--DH preferred specification): full sample, 2008 and later 
eststo m4: reghdfe `outcome' dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH if (year >= 2008), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS##c.dh_time)

test dhBTBxBlackNH = 0
test dhBTBxHisp = 0
test dhBTBxWhiteNH = 0

qui summ `outcome' if (dh_blackNH == 1 & dhBTB == 0 & dhBTBever == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & dhBTB == 0 & dhBTBever == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & dhBTB == 0 & dhBTBever == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))


** Only output regressions included in the table
local include_models "m1 m2 m3 m4"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" dh_time#gereg "Year-Region FE" age#dh_group "Demographics" metroFIPS#c.dh_time "MSA-Specific Trends")

esttab `include_models' using "$out/tableA3.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent \% Effect: Black" "hispanic_percent \% Effect: Hispanic" "white_percent \% Effect: White") sfmt(4 4 4 2 2 2) nomtitles keep(dhBTBx*) coeflabels(dhBTBxWhiteNH "BTB x White" dhBTBxBlackNH "BTB x Black" dhBTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


log close