* BTB: Additional ACS results using corrected treatment variable

set more off
capture log close

log using "$analyze_log/analysis_btb_acs_additional.txt", text replace

*** the following dataset is made in "$analyze/analysis_btb_acs_correctDH.do": ***
use "$analysis_data/dh_acs_analysistable_corrected.dta", clear

********************************************************************************
local sample "sex == 1 & age >= 25 & age <= 34 & us_citizen == 1"
local demog = "age in_school educd"
local demog_int = "age#dh_group in_school#dh_group educd#dh_group"
********************************************************************************


********************************************************************************
***** Public-sector employment 
********************************************************************************
eststo clear

local outcome "employed_public"

* appendix table a.6, column 1: all sample years, no time trends
eststo m1: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH, vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH metroFIPS#dh_hisp metroFIPS#dh_whiteNH)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.6, column 2: full sample with linear time trends
eststo m2: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH, vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.6 column 3: MSAs only 
eststo m3: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH  if (metroFIPS != stateFIPS), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.6, column 4: BTB adopting-only 
eststo m4: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if (BTBever == 1), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.6, column 5: full sample, 2008 and later 
eststo m5: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if (year >= 2008), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))


local include_models "m1 m2 m3 m4 m5"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" dh_time#gereg "Year-Region FE" age#dh_group "Demographics" metroFIPS#c.dh_time "MSA-Specific Trends")

esttab `include_models' using "$out/tableA6.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent \% Effect: Black" "hispanic_percent \% Effect: Hispanic" "white_percent \% Effect: White") sfmt(4 4 4 2 2 2) nomtitles keep(BTBx*) coeflabels(BTBxWhiteNH "BTB x White" BTBxBlackNH "BTB x Black" BTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


********************************************************************************
***** Account for differences with CPS (GQs and survey weights)
********************************************************************************
eststo clear

local outcome "employed"

* appendix table a.7, column 3: estimate ACS treatment effects with provided sample weights
eststo m1: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH  if (year >= 2008) [aw = perwt], vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008) [aw = perwt]
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008) [aw = perwt]
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008) [aw = perwt]
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.7, column 4: drop individuals living in group quarters (unweighted)
eststo m2: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH  if ((year >= 2008) & (gq != 3 & gq != 4)), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* appendix table a.7, column 5: drop individuals living in group quarters (weighted)
eststo m3: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH  if ((year >= 2008) & (gq != 3 & gq != 4)) [aw = perwt], vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008 & (gq != 3 & gq != 4)) [aw = perwt]
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008 & (gq != 3 & gq != 4)) [aw = perwt]
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS & year >= 2008 & (gq != 3 & gq != 4)) [aw = perwt]
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))


local include_models "m*"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" metroFIPS#group "MSA FE" year#division "Year-Region FE" year#division#group "Year-Region FE" year#division "Year-Division FE" age#group "Demographics" metroFIPS#c.year "MSA-Specific Trends")

esttab `include_models' using "$out/tableA7columns345.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent \% Effect: Black" "hispanic_percent \% Effect: Hispanic" "white_percent \% Effect: White") sfmt(4 4 4 2 2 2) keep(BTBx*) coeflabels(BTBxWhiteNH "BTB x White" BTBxBlackNH "BTB x Black" BTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01) mtitles("Drop Obs in Group Quarters" "With Sample Weights")


log close