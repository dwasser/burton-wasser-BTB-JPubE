* BTB: Additional corrected CPS results

capture log close

log using "$analyze_log/analysis_btb_cps_additional.txt", text replace

********************************************************************************
local demog = "age enrolledschool highestEdu group"
local demog_int = "age#group enrolledschool#group highestEdu#group"
local outcome "employed"
********************************************************************************

*** the following dataset is made in "$analyze/analysis_btb_cps_correctDH.do": ***
use "$analysis_data/dh_analysis_table_corrected.dta", clear


***********************************************************************************************
*** Crosswalk from Published Doleac and Hansen Estimate to Corrected Doleac and Hansen Estimate
***********************************************************************************************
eststo clear

* table a.5, column 1: published Doleac and Hansen (2020) estimate--preferred CPS specification
eststo m1: reghdfe `outcome' dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' raw_metroFIPS#black##c.time raw_metroFIPS#hispanic##c.time raw_metroFIPS##c.time)

qui summ `outcome' if (black == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table a.5, column 2: correct trend controls and harmonize MSAs
eststo m2: reghdfe `outcome' dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & dhBTB == 0 & dhBTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table a.5, column 3: correct trend controls, harmonize MSAs, and correct coding of laws--corrected Doleac and Hansen (2020) preferred CPS specification shown in our table 1, column 3
eststo m3: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


local include_models "m*"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/tableA5.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("white_mean Pre-BTB Mean: White" "black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_percent % Effect: White" "black_percent % Effect: Black" "hispanic_percent % Effect: Hispanic") sfmt(4 4 4 2 2 2) mtitles("DH Published" "Harmonize MSAs" "Corrected") keep(*BTBx*) order(dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH) coeflabels(BTBxWhiteNH "Corrected BTB x White" BTBxBlackNH "Corrected BTB x Black" BTBxHisp "Corrected BTB x Hispanic" dhBTBxWhiteNH "DH BTB x White" dhBTBxBlackNH "DH BTB x Black" dhBTBxHisp "DH BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


********************************************************************************
*** CPS Estimates with Survey Weights
********************************************************************************
eststo clear 

* table a.7, column 1: weighted regression, all years
eststo m1: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp [aw = pwcmpwgt], vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1) [aw = pwcmpwgt]
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1) [aw = pwcmpwgt]
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1) [aw = pwcmpwgt]
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table a.7, column 2: weighted regression, 2008 and later to match acs years
eststo m2: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp [aw = pwcmpwgt] if year >= 2008, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1 & year >= 2008) [aw = pwcmpwgt]
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1 & year >= 2008) [aw = pwcmpwgt]
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1 & year >= 2008) [aw = pwcmpwgt]
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


local include_models "m1 m2"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/tableA7columns12.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent % Effect: Black" "hispanic_percent % Effect: Hispanic" "white_percent % Effect: White") sfmt(4 4 4 2 2 2) nomtitles keep(*BTBx*) order(BTBxBlackNH BTBxHisp BTBxWhiteNH) coeflabels(BTBxWhiteNH "Corrected BTB x White" BTBxBlackNH "Corrected BTB x Black" BTBxHisp "Corrected BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


log close