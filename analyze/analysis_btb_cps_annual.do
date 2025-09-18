* Estimates from different ways to "annualize" treatment in the CPS

capture log close

log using "$analyze_log/analysis_btb_annualCPS.txt", text replace

*** the following dataset is made in "$analyze/analysis_btb_cps_correctDH.do" ***
use "$analysis_data/dh_analysis_table_corrected.dta", clear

***** Baseline estimates after changing treatment definition to match that of ACS *****
local demog = "age enrolledschool highestEdu group"
local demog_int = "age#group enrolledschool#group highestEdu#group"
local outcome "employed"

eststo clear

* table 3, column 1: donut BTB (drop year of implementation)
eststo mdonut_t: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp if (firstBTByr == 0), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#blackNH##c.time metroFIPS#hispanic##c.time metroFIPS#whiteNH##c.time)

qui summ `outcome' if (blackNH == 1 & BTB == 0 & BTBever == 1 & firstBTByr == 0)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1 & firstBTByr == 0)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (whiteNH == 1 & BTB == 0 & BTBever == 1 & firstBTByr == 0)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table 3, column 2: full-year BTB
eststo mfullyear_tt: reghdfe `outcome' fullyearBTBxWhiteNH fullyearBTBxBlackNH fullyearBTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#blackNH##c.time metroFIPS#hispanic##c.time metroFIPS#whiteNH##c.time)

qui summ `outcome' if (blackNH == 1 & fullyearBTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & fullyearBTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (whiteNH == 1 & fullyearBTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table 3, column 4: donut BTB (drop year of implementation) restricted to 2008 and later to match acs years
eststo mdonut_t2008: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp if (firstBTByr == 0 & year >= 2008), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#blackNH##c.time metroFIPS#hispanic##c.time metroFIPS#whiteNH##c.time)

qui summ `outcome' if (blackNH == 1 & BTB == 0 & BTBever == 1 & firstBTByr == 0 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1 & firstBTByr == 0 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (whiteNH == 1 & BTB == 0 & BTBever == 1 & firstBTByr == 0 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table 3, column 5: full-year BTB restricted to 2008 and later to match acs years
eststo mfullyear_tt2008: reghdfe `outcome' fullyearBTBxWhiteNH fullyearBTBxBlackNH fullyearBTBxHisp if (year >= 2008), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#blackNH##c.time metroFIPS#hispanic##c.time metroFIPS#whiteNH##c.time)

qui summ `outcome' if (blackNH == 1 & fullyearBTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & fullyearBTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (whiteNH == 1 & fullyearBTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


local include_models "mdonut_t mfullyear_tt mdonut_t2008 mfullyear_tt2008"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/table3columns1245.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent % Effect: Black" "hispanic_percent % Effect: Hispanic" "white_percent % Effect: White") sfmt(4 4 4 2 2 2) mtitles("Drop Year Implemented: With Trends" "Full Year Treatment: With Trends") keep(fullyearBTBx*  BTBxBlackNH BTBxHisp BTBxWhiteNH) order(fullyearBTBxBlackNH fullyearBTBxHisp fullyearBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH) coeflabels(fullyearBTBxWhiteNH "Full Year BTB x White" fullyearBTBxBlackNH "Full Year BTB x Black" fullyearBTBxHisp "Full Year BTB x Hispanic" BTBxWhiteNH "BTB x White" BTBxBlackNH "BTB x Black" BTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


***** Annualize the CPS *****
* Use methodology in Rivera Drew et al., (2014): Journal of Economic and Social Measurement (DOI: https://doi.org/10.3233%2FJEM-140388)
* In theory, HRHHID and HRHHID2 can be used to link households across samples. In practice, need a couple other variables.

sort hrhhid year month
drop if (hrhhid == "")

order hrhhid hrhhid2 hrsample hrsersuf huhhnum year month stateFIPS

* HRHHID2 first becomes available starting in May 2004, but it can be reconstructed
gen _part1 = substr(hrsample, 2, 2)

gen _part2 = ""
replace _part2 = "00" if (hrsersuf == "-1" & year == 2004 & month < 5)
replace _part2 = "01" if (hrsersuf == "A" & year == 2004 & month < 5)
replace _part2 = "02" if (hrsersuf == "B" & year == 2004 & month < 5)
replace _part2 = "03" if (hrsersuf == "C" & year == 2004 & month < 5)
replace _part2 = "04" if (hrsersuf == "D" & year == 2004 & month < 5)
replace _part2 = "25" if (hrsersuf == "Y" & year == 2004 & month < 5)
replace _part2 = "26" if (hrsersuf == "Z" & year == 2004 & month < 5)

tostring huhhnum, gen(_part3)
replace _part3 = "" if (hrhhid2 != "")

replace hrhhid2 = _part1 + _part2 + _part3 if (hrhhid2 == "" & year == 2004 & month < 5)

drop _part1 _part2 _part3


** Create unique person-level identifier **
sort hrhhid hrhhid2 hrmis year month gestcen pulineno 
order hrhhid hrhhid2 hrmis year month gestcen pulineno 

tostring pulineno, gen(str_pulineno)
replace str_pulineno = "0" + str_pulineno if (pulineno < 10)
drop pulineno
rename str_pulineno pulineno


* 1. Create new value of CPSIDP in MIS1
tostring month, gen(str_month)
replace str_month = "0" + str_month if (month < 10)

gen mis1month = month if (hrmis == 1)
gen mis1year = year if (hrmis == 1)

tostring mis1month, gen(str_mis1month)
replace str_mis1month = "0" + str_mis1month if (mis1month < 10)

egen cpsidp = concat(mis1year str_mis1month hrhhid hrhhid2 pulineno) if (hrmis == 1)

drop str_month str_mis1month


* 2. For MIS2-MIS8, identify which month was their first month in sample (hrmis == 1)
* First, do this with MIS <= 4
replace mis1month = month - (hrmis - 1) if (hrmis >= 2 & hrmis <= 4 & (month >= hrmis))
replace mis1year = year if (hrmis >= 2 & hrmis <= 4 & (month >= hrmis))

tostring mis1month, gen(str_mis1month)
replace str_mis1month = "0" + str_mis1month if (mis1month < 10)
replace str_mis1month = "" if (mis1month <= 0)

ereplace cpsidp = concat(mis1year str_mis1month hrhhid hrhhid2 pulineno) if (hrmis >= 2 & hrmis <= 4 & cpsidp == "" & mis1month != . & str_mis1month != "")

drop str_mis1month


* Now do it with MIS >= 5
replace mis1month = month - (hrmis - 5) if (hrmis >= 5 & mis1month == .)
replace mis1year = year - 1 if (hrmis >= 5 & mis1year == .)

tostring mis1month, gen(str_mis1month)
replace str_mis1month = "0" + str_mis1month if (mis1month < 10)
replace str_mis1month = "" if (mis1month <= 0)

ereplace cpsidp = concat(mis1year str_mis1month hrhhid hrhhid2 pulineno) if (hrmis >= 5 & cpsidp == "" & mis1month != .  & str_mis1month != "")

drop str_mis1month

* Manually handle cases when month == 1 and hrmis > 1
replace mis1month = 12 if (month == 1 & hrmis == 2 & (mis1month <= 0 | mis1month == .))
replace mis1month = 11 if (month == 1 & hrmis == 3 & (mis1month <= 0 | mis1month == .))
replace mis1month = 10 if (month == 1 & hrmis == 4 & (mis1month <= 0 | mis1month == .))

replace mis1month = 12 if (month == 1 & hrmis == 6 & (mis1month <= 0 | mis1month == .))
replace mis1month = 11 if (month == 1 & hrmis == 7 & (mis1month <= 0 | mis1month == .))
replace mis1month = 10 if (month == 1 & hrmis == 8 & (mis1month <= 0 | mis1month == .))

replace mis1year = year - 1 if (month == 1 & hrmis == 2)
replace mis1year = year - 1 if (month == 1 & hrmis == 3)
replace mis1year = year - 1 if (month == 1 & hrmis == 4)

replace mis1year = year - 2 if (month == 1 & hrmis == 6)
replace mis1year = year - 2 if (month == 1 & hrmis == 7)
replace mis1year = year - 2 if (month == 1 & hrmis == 8)

* Manually handle cases when month == 2 and hrmis > 2
replace mis1month = 12 if (month == 2 & hrmis == 3 & (mis1month <= 0 | mis1month == .))
replace mis1month = 11 if (month == 2 & hrmis == 4 & (mis1month <= 0 | mis1month == .))

replace mis1month = 12 if (month == 2 & hrmis == 7 & (mis1month <= 0 | mis1month == .))
replace mis1month = 11 if (month == 2 & hrmis == 8 & (mis1month <= 0 | mis1month == .))

replace mis1year = year - 1 if (month == 2 & hrmis == 3)
replace mis1year = year - 1 if (month == 2 & hrmis == 4)

replace mis1year = year - 2 if (month == 2 & hrmis == 7)
replace mis1year = year - 2 if (month == 2 & hrmis == 8)

* Manually handle cases when month == 3 and hrmis > 4
replace mis1month = 12 if (month == 3 & hrmis == 4 & (mis1month <= 0 | mis1month == .))
replace mis1month = 12 if (month == 3 & hrmis == 8 & (mis1month <= 0 | mis1month == .))

replace mis1year = year - 1 if (month == 3 & hrmis == 4)
replace mis1year = year - 2 if (month == 3 & hrmis == 8)


tostring mis1month, gen(str_mis1month)
replace str_mis1month = "0" + str_mis1month if (mis1month < 10)
replace str_mis1month = "" if (mis1month <= 0)

ereplace cpsidp = concat(mis1year str_mis1month hrhhid hrhhid2 pulineno) if (cpsidp == "" & mis1month != . & mis1month > 0 & mis1year != . & str_mis1month != "")

drop str_mis1month


replace cpsidp = "" if (mis1month <= 0)


order cpsidp hrhhid hrhhid2 pulineno year month hrmis mis1month mis1year stateFIPS


***** Get cell counts *****
* Only MSAs: include duplicates persons
preserve

keep if (metroFIPS != stateFIPS)

gen n = 1
collapse (sum) n, by(year metroFIPS group blackNH whiteNH hispanic)
bys group: summ n, detail

restore 

* Only MSAs: unique persons
preserve

duplicates drop cpsidp, force

keep if (metroFIPS != stateFIPS)

gen n = 1
collapse (sum) n, by(year metroFIPS group blackNH whiteNH hispanic)
bys group: summ n, detail

restore 

***** Only keep each respondent's first month in sample in order to create a person-year level dataset (like ACS) *****
capture drop time 
gen time = year - 2003

save "$analysis_data/cps_annualized.dta", replace

*** regressions ***
eststo clear

* table 3, column 3: annualized CPS (full-year BTB definition, only keep respondent's first month-in-sample)
eststo m1: reghdfe `outcome' fullyearBTBxWhiteNH fullyearBTBxBlackNH fullyearBTBxHisp if (hrmis == 1), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#blackNH##c.time metroFIPS#hispanic##c.time metroFIPS#whiteNH##c.time)

qui summ `outcome' if (blackNH == 1 & fullyearBTB == 0 & e(sample) == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & fullyearBTB == 0 & e(sample) == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (whiteNH == 1 & fullyearBTB == 0 & e(sample) == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


* table 3, column 3: annualized CPS (full-year BTB definition, only keep respondent's first month-in-sample) restricted to 2008 and later to match acs years
eststo m2: reghdfe `outcome' fullyearBTBxWhiteNH fullyearBTBxBlackNH fullyearBTBxHisp if (year >= 2008 & hrmis == 1), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#blackNH##c.time metroFIPS#hispanic##c.time metroFIPS#whiteNH##c.time)

qui summ `outcome' if (blackNH == 1 & fullyearBTB == 0 & e(sample) == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & fullyearBTB == 0 & e(sample) == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (whiteNH == 1 & fullyearBTB == 0 & e(sample) == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))


local include_models "m1 m2"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/table3columns36.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("white_mean Pre-BTB Mean: White" "black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_percent % Effect: White" "black_percent % Effect: Black" "hispanic_percent % Effect: Hispanic") sfmt(4 4 4 2 2 2) mtitles("With Trends") keep(fullyearBTBx*) order(fullyearBTBxBlackNH fullyearBTBxHisp fullyearBTBxWhiteNH) coeflabels(fullyearBTBxWhiteNH "BTB x White" fullyearBTBxBlackNH "BTB x Black" fullyearBTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


log close