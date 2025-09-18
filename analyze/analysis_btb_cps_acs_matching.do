*** Rerun several of the CPS and ACS specifications restricting the samples to individuals in MSA-years that are in both the CPS and the ACS ***
set more off
capture log close

log using "$analyze_log/analysis_btb_cps_acs_matching.txt", text replace

********************************************************************************


*** Merge CPS data and ACS data ***

*** the following dataset is made in "$analyze/analysis_btb_cps_correctDH.do" ***
use "$analysis_data/dh_analysis_table_corrected.dta", clear

** ACS does not have substate geographies in 2004 **
drop if (year <= 2004)

drop px*
save "$analysis_data/dh_analysis_table_corrected_cps_acs_matching.dta", replace


*** Find the set of MSAs in both the ACS and CPS ***

* Start with CPS (already loaded) and collapse for frequencies
gen n = 1
collapse (sum) n, by(metroFIPS year group)

tempfile cps_freq
save "`cps_freq'", replace


use "$analysis_data/dh_acs_analysistable_cps_acs_matching.dta", clear
keep if (year >= 2005)

rename dh_group group 

merge m:1 metroFIPS year group using "`cps_freq'"
keep if (_merge == 3)

keep year metroFIPS
duplicates drop 

save "$analysis_data/msas_in_both.dta", replace 


*** CPS Estimate
use "$analysis_data/dh_analysis_table_corrected_cps_acs_matching.dta", clear

merge m:1 metroFIPS year using "$analysis_data/msas_in_both.dta", keep(match)
drop _merge


local demog_int = "age#group enrolledschool#group highestEdu#group"
local outcome "employed"

eststo clear

* table a.8, column 1: correction of Doleac and Hansen preferred CPS specification, sample restricted to individuals in MSA-years in both CPS and ACS
eststo m1: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table a.8, column 2: CPS, weighted, 2008 and later, sample restricted to MSA-years in both CPS and ACS
eststo m2: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp [aw = pwcmpwgt] if (year >= 2008), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' [aw = pwcmpwgt] if (black == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' [aw = pwcmpwgt] if (hispanic == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' [aw = pwcmpwgt] if (white == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


*** ACS Estimate
use "$analysis_data/dh_acs_analysistable_corrected.dta", clear

merge m:1 metroFIPS year using "$analysis_data/msas_in_both.dta", keep(match)
drop _merge

local demog_int = "age#dh_group in_school#dh_group educd#dh_group"
local outcome "employed"

* table a.8, column 3: correction of Doleac and Hansen (2020) preferred ACS specification, 2008 and later, sample restricted to MSA-years in both CPS and ACS
eststo m3: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if (year >= 2008), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* table a.8, column 4: ACS, excluding group quarters, 2008 and later, sample restricted to MSA-years in both CPS and ACS
eststo m4: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if ((year >= 2008) & (gq != 3 & gq != 4)), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* table a.8, column 5: ACS, weighted, excluding group quarters, 2008 and later, sample restricted to MSA-years in both CPS and ACS
eststo m5: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if ((year >= 2008) & (gq != 3 & gq != 4)) [aw = perwt], vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' [aw = perwt] if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' [aw = perwt] if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' [aw = perwt] if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008 & (gq != 3 & gq != 4))
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))


local include_models "m1 m2 m3 m4 m5"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/tableA8.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent \% Effect: Black" "hispanic_percent \% Effect: Hispanic" "white_percent \% Effect: White") sfmt(4 4 4 2 2 2) keep(*BTBx*) order(BTBxBlackNH BTBxHisp BTBxWhiteNH) coeflabels(BTBxWhiteNH "BTB x White" BTBxBlackNH "BTB x Black" BTBxHisp "BTB x Hispanic") mtitles("CPS: Full" "CPS: Weights, 2008+" "ACS:Full" "ACS: Weights, No GQ, 2008+" "ACS: No weights, No GQ, 2008+") star(* 0.10 ** 0.05 *** 0.01)


***** event studies for MSAs in both (ACS, drop group quarters) *****

* for years after the treatment date
forvalues i = 1(1)5 {
	local j = `i' - 1
	gen BTB_lag_`j'to`i' = (year == btb_eff_year + `j')
}

* for years before the treatment date
forvalues i = 1(1)4 {
	local j = `i' - 1
	gen BTB_lead_`j'to`i' = (year == btb_eff_year - `i')
}
	
gen BTB_neg1 = 0
replace BTB_lead_3to4 = 0


* drop group quarters
preserve

drop if gq == 3 | gq == 4


*** appendix figure A.6a: Black ***
eststo clear

reghdfe employed BTB_lead_3to4 BTB_lead_2to3 BTB_lead_1to2 BTB_neg1  BTB_lag_0to1 BTB_lag_1to2 BTB_lag_2to3 BTB_lag_3to4 BTB_lag_4to5 if dh_blackNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_black
coefplot (baseline_black, keep(BTB_lead_3to4 BTB_lead_2to3 BTB_lead_1to2) lcolor(black) mcolor(black)) ///
		(baseline_black, keep(BTB_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_black, keep(BTB_lag_0to1 BTB_lag_1to2 BTB_lag_2to3 BTB_lag_3to4 BTB_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTB_lead_3to4 = "t-4" BTB_lead_2to3 = "t-3" BTB_lead_1to2 = "t-2" BTB_neg1 = "t-1" BTB_lag_0to1 = "t" BTB_lag_1to2 = "t+1" BTB_lag_2to3 = "t+2" BTB_lag_3to4 = "t+3" BTB_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_black_nogq_MSAboth.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA6a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure A.6b: Hispanic ***
eststo clear

reghdfe employed BTB_lead_3to4 BTB_lead_2to3 BTB_lead_1to2 BTB_neg1  BTB_lag_0to1 BTB_lag_1to2 BTB_lag_2to3 BTB_lag_3to4 BTB_lag_4to5 if dh_hisp==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_hisp
coefplot (baseline_hisp, keep(BTB_lead_3to4 BTB_lead_2to3 BTB_lead_1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_hisp, keep(BTB_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_hisp, keep(BTB_lag_0to1 BTB_lag_1to2 BTB_lag_2to3 BTB_lag_3to4 BTB_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTB_lead_3to4 = "t-4" BTB_lead_2to3 = "t-3" BTB_lead_1to2 = "t-2" BTB_neg1 = "t-1" BTB_lag_0to1 = "t" BTB_lag_1to2 = "t+1" BTB_lag_2to3 = "t+2" BTB_lag_3to4 = "t+3" BTB_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_hispanic_nogq_MSAboth.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA6b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure A.6c: white ***
eststo clear
	
reghdfe employed BTB_lead_3to4 BTB_lead_2to3 BTB_lead_1to2 BTB_neg1  BTB_lag_0to1 BTB_lag_1to2 BTB_lag_2to3 BTB_lag_3to4 BTB_lag_4to5 if dh_whiteNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_white
coefplot (baseline_white, keep(BTB_lead_3to4 BTB_lead_2to3 BTB_lead_1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_white, keep(BTB_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_white, keep(BTB_lag_0to1 BTB_lag_1to2 BTB_lag_2to3 BTB_lag_3to4 BTB_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTB_lead_3to4 = "t-4" BTB_lead_2to3 = "t-3" BTB_lead_1to2 = "t-2" BTB_neg1 = "t-1" BTB_lag_0to1 = "t" BTB_lag_1to2 = "t+1" BTB_lag_2to3 = "t+2" BTB_lag_3to4 = "t+3" BTB_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_white_nogq_MSAboth.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA6c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

restore

log close