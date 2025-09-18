***** Test if BW results are statistically significantly different from DH results *****

clear all
capture log close
log using "$analyze_log/stat_difference.txt", text replace


***** ACS *****

*** the following dataset is made in "$build/build_acs_data.do": ***
use "$analysis_data/btb_acs_analysis_table.dta", clear

fvset base 2 metroFIPS
fvset base 60 age
fvset base 2004 year

local sample "sex == 1 & age >= 25 & age <= 34 & us_citizen == 1"

keep if `sample'

keep employed *BTB* dh_time gereg dh_group age in_school educd metroFIPS us_citizen no_coll_deg dh_blackNH dh_hisp dh_whiteNH stateFIPS year dh_noCollege perwt gq

save "$analysis_data/minimal_acs_data.dta", replace 


***** CPS *****

*** the following dataset is made in "$analyze/analysis_btb_cps_correctDH.do" ***
use "$analysis_data/dh_analysis_table_corrected.dta", clear

keep employed BTBxWhiteNH BTBxBlackNH BTBxHisp dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp year time gereg group age enrolledschool highestEdu metroFIPS raw_metroFIPS black hispanic white stateFIPS  *BTB* pwcmpwgt

save "$analysis_data/minimal_cps_data.dta", replace


***************** regressions ***********************

*** stacking: uncorrected CPS vs. uncorrected ACS ***
use "$analysis_data/minimal_acs_data.dta", clear
keep if dh_noCollege == 1
keep if (year >= 2008)

gen source = "acs"

append using "$analysis_data/minimal_cps_data.dta"
replace source = "cps" if (source == "")

rename black black_cps
rename white white_cps

gen metroFIPS_both = .
replace metroFIPS_both = metroFIPS if (source == "acs")
replace metroFIPS_both = raw_metroFIPS if (source == "cps")

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

*uncorrected BTB laws
gen ACSdhBTBxBlack = 0
replace ACSdhBTBxBlack = dhBTBxBlackNH if (source == "acs")

gen CPSdhBTBxBlack = 0
replace CPSdhBTBxBlack = dhBTBxBlackNH if (source == "cps")

gen ACSdhBTBxHisp = 0
replace ACSdhBTBxHisp = dhBTBxHisp if (source == "acs")

gen CPSdhBTBxHisp = 0
replace CPSdhBTBxHisp = dhBTBxHisp if (source == "cps")

gen ACSdhBTBxWhite = 0
replace ACSdhBTBxWhite = dhBTBxWhite if (source == "acs")

gen CPSdhBTBxWhite = 0
replace CPSdhBTBxWhite = dhBTBxWhite if (source == "cps")

gen acs_data = (source == "acs")

replace dh_time =  0 if (dh_time == .)

gen test_time = 0
replace test_time = time if (source == "cps")

replace white_cps = 0 if (source == "acs")

*** stacking: uncorrected ACS vs. uncorrected CPS ***
reghdfe employed ACSdhBTBxBlack CPSdhBTBxBlack ACSdhBTBxHisp CPSdhBTBxHisp ACSdhBTBxWhite CPSdhBTBxWhite, absorb(acs_data#group_both time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data metroFIPS_both#black_both#acs_data metroFIPS_both#hisp_both#acs_data metroFIPS_both#white_cps metroFIPS_both#black_both##c.test_time metroFIPS_both#hisp_both##c.test_time metroFIPS_both#white_cps##c.test_time metroFIPS_both#black_both##c.dh_time metroFIPS_both#hisp_both##c.dh_time metroFIPS_both##c.dh_time, savefe) vce(cluster stateFIPS)

test ACSdhBTBxBlack = CPSdhBTBxBlack

test ACSdhBTBxHisp = CPSdhBTBxHisp

test ACSdhBTBxWhite = CPSdhBTBxWhite

********************************************************************************
*** stacking: uncorrected CPS vs. corrected ACS ***

use "$analysis_data/minimal_acs_data.dta", clear
keep if no_coll_deg == 1
keep if (year >= 2008)

gen source = "acs"

append using "$analysis_data/minimal_cps_data.dta"
replace source = "cps" if (source == "")

rename black black_cps
rename white white_cps

gen metroFIPS_both = .
replace metroFIPS_both = metroFIPS if (source == "acs")
replace metroFIPS_both = raw_metroFIPS if (source == "cps")

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

*BTB laws
gen acsBTBxBlack = 0
replace acsBTBxBlack = BTBxBlackNH if (source == "acs")

gen CPSdhBTBxBlack = 0
replace CPSdhBTBxBlack = dhBTBxBlackNH if (source == "cps")

gen acsBTBxHisp = 0
replace acsBTBxHisp = BTBxHisp if (source == "acs")

gen CPSdhBTBxHisp = 0
replace CPSdhBTBxHisp = dhBTBxHisp if (source == "cps")

gen acsBTBxWhite = 0
replace acsBTBxWhite = BTBxWhite if (source == "acs")

gen CPSdhBTBxWhite = 0
replace CPSdhBTBxWhite = dhBTBxWhite if (source == "cps")

gen acs_data = (source == "acs")

replace dh_time =  0 if (dh_time == .)

gen test_time = 0
replace test_time = time if (source == "cps")

replace white_cps = 0 if (source == "acs")


*** stacking: corrected ACS vs. uncorrected CPS ***

reghdfe employed acsBTBxBlack CPSdhBTBxBlack acsBTBxHisp CPSdhBTBxHisp acsBTBxWhite CPSdhBTBxWhite, absorb(acs_data#group_both time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data metroFIPS_both#black_both#acs_data metroFIPS_both#hisp_both#acs_data metroFIPS_both#white_both#acs_data metroFIPS_both#black_both##c.test_time metroFIPS_both#hisp_both##c.test_time metroFIPS_both#white_both##c.test_time metroFIPS_both#black_both##c.dh_time metroFIPS_both#hisp_both##c.dh_time metroFIPS_both#white_both##c.dh_time, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = CPSdhBTBxBlack

test acsBTBxHisp = CPSdhBTBxHisp

test acsBTBxWhite = CPSdhBTBxWhite

********************************************************************************
*** stacking: corrected ACS vs. corrected CPS ***

use "$analysis_data/minimal_acs_data.dta", clear
keep if (no_coll_deg == 1)
keep if (year >= 2008)

gen source = "acs"

append using "$analysis_data/minimal_cps_data.dta"
replace source = "cps" if (source == "")

rename black black_cps
rename white white_cps

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

*corrected BTB laws
gen acsBTBxBlack = 0
replace acsBTBxBlack = BTBxBlackNH if (source == "acs")

gen cpsBTBxBlack = 0
replace cpsBTBxBlack = BTBxBlackNH if (source == "cps")

gen acsBTBxHisp = 0
replace acsBTBxHisp = BTBxHisp if (source == "acs")

gen cpsBTBxHisp = 0
replace cpsBTBxHisp = BTBxHisp if (source == "cps")

gen acsBTBxWhite = 0
replace acsBTBxWhite = BTBxWhite if (source == "acs")

gen cpsBTBxWhite = 0
replace cpsBTBxWhite = BTBxWhite if (source == "cps")

gen acs_data = (source == "acs")


reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

********************************************************************************
*** stacking: uncorrected vs. corrected CPS ***
use "$analysis_data/minimal_cps_data.dta", clear
gen source = 0

append using "$analysis_data/minimal_cps_data.dta"
replace source = 1 if source == .

replace dhBTBxBlackNH = 0 if source == 1
replace dhBTBxHisp = 0 if source == 1
replace dhBTBxWhiteNH = 0 if source == 1
replace BTBxBlackNH = 0 if source == 0
replace BTBxHisp = 0 if source == 0
replace BTBxWhiteNH = 0 if source == 0

replace raw_metroFIPS = 0 if source == 1
replace metroFIPS = 0 if source == 0

gen metroFIPS_both = raw_metroFIPS if source == 0
replace metroFIPS_both = metroFIPS if source == 1

reghdfe employed dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH, absorb(source#group source#time#gereg#group source#age#group source#enrolledschool#group source#highestEdu#group metroFIPS_both#black#source metroFIPS_both#hispanic#source metroFIPS_both#white#source metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time raw_metroFIPS#black##c.time raw_metroFIPS#hispanic##c.time raw_metroFIPS##c.time, savefe) vce(cluster stateFIPS)

test dhBTBxBlackNH = BTBxBlackNH

test dhBTBxHisp = BTBxHisp

test dhBTBxWhiteNH = BTBxWhiteNH

********************************************************************************
*** stacking: uncorrected vs. corrected ACS ***
use "$analysis_data/minimal_acs_data.dta", clear
keep if dh_noCollege == 1
gen source = 0

append using "$analysis_data/minimal_acs_data.dta"
replace source = 1 if source == .

drop if (source == 1 & no_coll_deg != 1)
keep if (year >= 2008)

replace dhBTBxBlackNH = 0 if source == 1
replace dhBTBxHisp = 0 if source == 1
replace dhBTBxWhiteNH = 0 if source == 1
replace BTBxBlackNH = 0 if source == 0
replace BTBxHisp = 0 if source == 0
replace BTBxWhiteNH = 0 if source == 0

gen metroFIPS0 = metroFIPS if source == 0
replace metroFIPS0 = 0 if source == 1

gen metroFIPS1 = metroFIPS if source == 1
replace metroFIPS1 = 0 if source == 0

gen white_corrected = dh_whiteNH*source

reghdfe employed dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH, absorb(source#dh_group source#dh_time#gereg#dh_group source#age#dh_group source#in_school#dh_group source#educd#dh_group metroFIPS#dh_blackNH#source metroFIPS#dh_hisp#source metroFIPS#white_corrected metroFIPS1#dh_blackNH##c.dh_time metroFIPS1#dh_hisp##c.dh_time metroFIPS1#white_corrected##c.dh_time metroFIPS0#dh_blackNH##c.dh_time metroFIPS0#dh_hisp##c.dh_time metroFIPS0##c.dh_time, savefe) vce(cluster stateFIPS)


test dhBTBxBlackNH = BTBxBlackNH

test dhBTBxHisp = BTBxHisp

test dhBTBxWhiteNH = BTBxWhiteNH

********************************************************************************
*** stacking: table 3 col 2 and 5 vs. corrected ACS ***
use "$analysis_data/minimal_cps_data.dta", clear

gen source = "cps"

append using "$analysis_data/minimal_acs_data.dta"
replace source = "acs" if source == ""
drop if (no_coll_deg != 1 & source == "acs")
drop if (year < 2008 & source == "acs")

rename black black_cps
rename white white_cps

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

gen acs_data = (source == "acs")

* rename BTB laws
gen acsBTBxBlack = 0
replace acsBTBxBlack = BTBxBlackNH if (source == "acs")

gen cpsBTBxBlack = 0
replace cpsBTBxBlack = BTBxBlackNH if (source == "cps")

gen acsBTBxHisp = 0
replace acsBTBxHisp = BTBxHisp if (source == "acs")

gen cpsBTBxHisp = 0
replace cpsBTBxHisp = BTBxHisp if (source == "cps")

gen acsBTBxWhite = 0
replace acsBTBxWhite = BTBxWhiteNH if (source == "acs")

gen cpsBTBxWhite = 0
replace cpsBTBxWhite = BTBxWhiteNH if (source == "cps")

replace fullyearBTBxBlackNH = 0 if source == "acs"
replace fullyearBTBxHisp = 0 if source == "acs"
replace fullyearBTBxWhiteNH = 0 if source == "acs"

* full year, all years cps
reghdfe employed fullyearBTBxBlackNH fullyearBTBxHisp fullyearBTBxWhiteNH acsBTBxBlack acsBTBxHisp acsBTBxWhite, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = fullyearBTBxBlackNH

test acsBTBxHisp = fullyearBTBxHisp

test acsBTBxWhite = fullyearBTBxWhiteNH

* full year, 2008 and later for both
reghdfe employed fullyearBTBxBlackNH fullyearBTBxHisp fullyearBTBxWhiteNH acsBTBxBlack acsBTBxHisp acsBTBxWhite if year >= 2008, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = fullyearBTBxBlackNH

test acsBTBxHisp = fullyearBTBxHisp

test acsBTBxWhite = fullyearBTBxWhiteNH

********************************************************************************
*** stacking: table 3 col 1 and 4 vs corrected ACS ***
drop if source == "cps" & firstBTByr != 0

* donut year, all years cps
reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

* donut year, 2008 and later for both
reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite if year >= 2008, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

********************************************************************************
*** stacking: table 3 col 3 and 6 vs. corrected acs ***

*** the following dataset is made in "$analyze/analysis_btb_cps_annual.do": ***
use "$analysis_data/cps_annualized.dta", clear
gen source = "cps"
keep if hrmis == 1


append using "$analysis_data/minimal_acs_data.dta"
replace source = "acs" if source == ""
drop if (no_coll_deg != 1 & source == "acs")
drop if (year < 2008 & source == "acs")

rename black black_cps
rename white white_cps

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

gen acs_data = (source == "acs")

replace fullyearBTBxBlackNH = 0 if source == "acs"
replace fullyearBTBxHisp = 0 if source == "acs"
replace fullyearBTBxWhiteNH = 0 if source == "acs"
replace BTBxBlackNH = 0 if source == "cps"
replace BTBxHisp = 0 if source == "cps"
replace BTBxWhiteNH = 0 if source == "cps"

* table 3 column 3 (annualized cps) vs. table 2 column 6 (corrected acs)
reghdfe employed BTBxBlackNH fullyearBTBxBlackNH BTBxHisp fullyearBTBxHisp BTBxWhiteNH fullyearBTBxWhiteNH, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = fullyearBTBxBlackNH

test BTBxHisp = fullyearBTBxHisp

test BTBxWhiteNH = fullyearBTBxWhiteNH

* table 3 column 6 (annualized cps 2008+) vs. table 2 column 6 (corrected acs)
reghdfe employed BTBxBlackNH fullyearBTBxBlackNH BTBxHisp fullyearBTBxHisp BTBxWhiteNH fullyearBTBxWhiteNH if year >= 2008, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = fullyearBTBxBlackNH

test BTBxHisp = fullyearBTBxHisp

test BTBxWhiteNH = fullyearBTBxWhiteNH


********************************************************************************
*** stacking: table 3 col 2 and 5 vs. corrected CPS ***
use "$analysis_data/minimal_cps_data.dta", clear

gen source = 1

append using "$analysis_data/minimal_cps_data.dta"
replace source = 0 if source == .

* make donut BTB law
gen donutBTBxBlack = 0
replace donutBTBxBlack = BTBxBlackNH if (source == 1)

gen donutBTBxHisp = 0
replace donutBTBxHisp = BTBxHisp if (source == 1)

gen donutBTBxWhite = 0
replace donutBTBxWhite = BTBxWhiteNH if (source == 1)

replace fullyearBTBxBlackNH = 0 if source == 0
replace fullyearBTBxHisp = 0 if source == 0
replace fullyearBTBxWhiteNH = 0 if source == 0
replace BTBxBlackNH = 0 if source == 1
replace BTBxHisp = 0 if source == 1
replace BTBxWhiteNH = 0 if source == 1

* full year, all years cps
reghdfe employed fullyearBTBxBlackNH fullyearBTBxHisp fullyearBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH, absorb(time#gereg#group#source age#group#source enrolledschool#group#source highestEdu#group#source source#metroFIPS#black##c.time source#metroFIPS#hispanic##c.time source#metroFIPS#white##c.time, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = fullyearBTBxBlackNH

test BTBxHisp = fullyearBTBxHisp

test BTBxWhiteNH = fullyearBTBxWhiteNH



* full year, 2008 and later for both
preserve
drop if year < 2008 & source == 1

reghdfe employed fullyearBTBxBlackNH fullyearBTBxHisp fullyearBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH, absorb(time#gereg#group#source age#group#source enrolledschool#group#source highestEdu#group#source source#metroFIPS#black##c.time source#metroFIPS#hispanic##c.time source#metroFIPS#white##c.time, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = fullyearBTBxBlackNH

test BTBxHisp = fullyearBTBxHisp

test BTBxWhiteNH = fullyearBTBxWhiteNH

restore

********************************************************************************
*** stacking: table 3 col 1 and 4 vs corrected CPS ***
drop if source == 1 & firstBTByr != 0

* donut year, all years cps
reghdfe employed BTBxBlackNH donutBTBxBlack BTBxHisp donutBTBxHisp BTBxWhiteNH donutBTBxWhite, absorb(time#gereg#group#source age#group#source enrolledschool#group#source highestEdu#group#source source#metroFIPS#black##c.time source#metroFIPS#hispanic##c.time source#metroFIPS#white##c.time, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = donutBTBxBlack

test BTBxHisp = donutBTBxHisp

test BTBxWhiteNH = donutBTBxWhite

* donut year, 2008 and later for both
drop if year < 2008 & source == 1

reghdfe employed BTBxBlackNH donutBTBxBlack BTBxHisp donutBTBxHisp BTBxWhiteNH donutBTBxWhite, absorb(time#gereg#group#source age#group#source enrolledschool#group#source highestEdu#group#source source#metroFIPS#black##c.time source#metroFIPS#hispanic##c.time source#metroFIPS#white##c.time, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = donutBTBxBlack

test BTBxHisp = donutBTBxHisp

test BTBxWhiteNH = donutBTBxWhite

********************************************************************************
*** stacking: table 3 col 3 and 6 vs. corrected CPS ***

*** the following dataset is made in "$analyze/analysis_btb_cps_annual.do": ***
use "$analysis_data/cps_annualized.dta", clear
gen source = 1
keep if hrmis == 1

append using "$analysis_data/minimal_cps_data.dta"
replace source = 0 if source == .

replace fullyearBTBxBlackNH = 0 if source == 0
replace fullyearBTBxHisp = 0 if source == 0
replace fullyearBTBxWhiteNH = 0 if source == 0
replace BTBxBlackNH = 0 if source == 1
replace BTBxHisp = 0 if source == 1
replace BTBxWhiteNH = 0 if source == 1


reghdfe employed BTBxBlackNH fullyearBTBxBlackNH BTBxHisp fullyearBTBxHisp BTBxWhiteNH fullyearBTBxWhiteNH, absorb(time#gereg#group#source age#group#source enrolledschool#group#source highestEdu#group#source source#metroFIPS#black##c.time source#metroFIPS#hispanic##c.time source#metroFIPS#white##c.time, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = fullyearBTBxBlackNH

test BTBxHisp = fullyearBTBxHisp

test BTBxWhiteNH = fullyearBTBxWhiteNH


drop if year < 2008 & source == 1

* restrict to 2008 and later to match acs years
reghdfe employed BTBxBlackNH fullyearBTBxBlackNH BTBxHisp fullyearBTBxHisp BTBxWhiteNH fullyearBTBxWhiteNH, absorb(time#gereg#group#source age#group#source enrolledschool#group#source highestEdu#group#source source#metroFIPS#black##c.time source#metroFIPS#hispanic##c.time source#metroFIPS#white##c.time, savefe) vce(cluster stateFIPS)

test BTBxBlackNH = fullyearBTBxBlackNH

test BTBxHisp = fullyearBTBxHisp

test BTBxWhiteNH = fullyearBTBxWhiteNH


********************************************************************************
*** stacking: weighted vs. unweighted ACS (both corrected) ***
use "$analysis_data/minimal_acs_data.dta", clear
gen source = 0

append using "$analysis_data/minimal_acs_data.dta"
replace source = 1 if source == .

drop if (no_coll_deg != 1)
keep if (year >= 2008)

gen wBTBxBlackNH = BTBxBlackNH
gen wBTBxHisp = BTBxHisp
gen wBTBxWhiteNH = BTBxWhiteNH

replace BTBxBlackNH = 0 if source == 1
replace BTBxHisp = 0 if source == 1
replace BTBxWhiteNH = 0 if source == 1
replace wBTBxBlackNH = 0 if source == 0
replace wBTBxHisp = 0 if source == 0
replace wBTBxWhiteNH = 0 if source == 0

gen weight = perwt
replace weight = 1 if source == 0


reghdfe employed wBTBxBlackNH wBTBxHisp wBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH [aw = weight], absorb(source#dh_group source#dh_time#gereg#dh_group source#age#dh_group source#in_school#dh_group source#educd#dh_group metroFIPS#dh_blackNH#source metroFIPS#dh_hisp#source metroFIPS#dh_whiteNH#source source#metroFIPS#dh_blackNH##c.dh_time source#metroFIPS#dh_hisp##c.dh_time source#metroFIPS#dh_whiteNH##c.dh_time, savefe) vce(cluster stateFIPS)


test wBTBxBlackNH = BTBxBlackNH

test wBTBxHisp = BTBxHisp

test wBTBxWhiteNH = BTBxWhiteNH

********************************************************************************
* weighted ACS vs. weighted CPS
use "$analysis_data/minimal_acs_data.dta", clear
keep if (no_coll_deg == 1)
keep if (year >= 2008)

gen source = "acs"

append using "$analysis_data/minimal_cps_data.dta"
replace source = "cps" if (source == "")

rename black black_cps
rename white white_cps

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

*corrected BTB laws
gen acsBTBxBlack = 0
replace acsBTBxBlack = BTBxBlackNH if (source == "acs")

gen cpsBTBxBlack = 0
replace cpsBTBxBlack = BTBxBlackNH if (source == "cps")

gen acsBTBxHisp = 0
replace acsBTBxHisp = BTBxHisp if (source == "acs")

gen cpsBTBxHisp = 0
replace cpsBTBxHisp = BTBxHisp if (source == "cps")

gen acsBTBxWhite = 0
replace acsBTBxWhite = BTBxWhite if (source == "acs")

gen cpsBTBxWhite = 0
replace cpsBTBxWhite = BTBxWhite if (source == "cps")

gen acs_data = (source == "acs")

gen weight = perwt
*replace weight = 1 if source == "cps"

replace weight = pwcmpwgt if source == "cps"

reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite [aw = weight], absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

********************************************************************************
* weighted ACS, no group quarters vs. weighted CPS, 2008+
replace weight = pwcmpwgt if source == "cps"
drop if (gq == 3 | gq == 4) & source == "acs"

reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite if year >= 2008 [aw = weight], absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite


********************************************************************************
* unweighted ACS, no group quarters vs. unweighted CPS 
reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite


********************************************************************************
*** stacking: MSAs in both ***

*** the following dataset is made in "$analyze/analysis_btb_acs_correctDH.do": ***
use "$analysis_data/dh_acs_analysistable_corrected.dta", clear

*** the using dataset is made in "$analyze/analysis_btb_cps_acs_matching.do" ***
merge m:1 metroFIPS year using "$analysis_data/msas_in_both.dta", keep(match)
drop _merge

keep if (year >= 2008)

keep employed dhBTBxBlackNH dhBTBxHisp dhBTBxWhiteNH BTBxBlackNH BTBxHisp BTBxWhiteNH dh_time gereg dh_group age in_school educd metroFIPS us_citizen no_coll_deg dh_blackNH dh_hisp dh_whiteNH stateFIPS year dh_noCollege perwt gq

gen source = "acs"

tempfile minimal_acs_data_msas_in_both
save "`minimal_acs_data_msas_in_both'", replace


*** the following dataset is made in "$analyze/analysis_btb_cps_acs_matching.do": ***
use "$analysis_data/dh_analysis_table_corrected_cps_acs_matching.dta", clear

*** the using dataset is made in "$analyze/analysis_btb_cps_acs_matching.do" ***
merge m:1 metroFIPS year using "$analysis_data/msas_in_both.dta", keep(match)
drop _merge

keep employed BTBxWhiteNH BTBxBlackNH BTBxHisp dhBTBxWhiteNH dhBTBxBlackNH dhBTBxHisp year time gereg group age enrolledschool highestEdu metroFIPS raw_metroFIPS black hispanic white stateFIPS  *BTB* pwcmpwgt

gen source = "cps"

append using "`minimal_acs_data_msas_in_both'"

rename black black_cps
rename white white_cps

gen time_both = .
replace time_both = dh_time if (source == "acs")
replace time_both = time if (source == "cps")

gen group_both = .
replace group_both = dh_group if (source == "acs")
replace group_both = group if (source == "cps")

gen enrolled_both = .
replace enrolled_both = in_school if (source == "acs")
replace enrolled_both = enrolledschool if (source == "cps")

gen highedu_both = .
replace highedu_both = educd if (source == "acs")
replace highedu_both = highestEdu if (source == "cps")

gen black_both = .
replace black_both = dh_blackNH if (source == "acs")
replace black_both = black_cps if (source == "cps")

gen hisp_both = .
replace hisp_both = dh_hisp if (source == "acs")
replace hisp_both = hispanic if (source == "cps")

gen white_both = .
replace white_both = dh_whiteNH if (source == "acs")
replace white_both = white_cps if (source == "cps")

*corrected BTB laws
gen acsBTBxBlack = 0
replace acsBTBxBlack = BTBxBlackNH if (source == "acs")

gen cpsBTBxBlack = 0
replace cpsBTBxBlack = BTBxBlackNH if (source == "cps")

gen acsBTBxHisp = 0
replace acsBTBxHisp = BTBxHisp if (source == "acs")

gen cpsBTBxHisp = 0
replace cpsBTBxHisp = BTBxHisp if (source == "cps")

gen acsBTBxWhite = 0
replace acsBTBxWhite = BTBxWhite if (source == "acs")

gen cpsBTBxWhite = 0
replace cpsBTBxWhite = BTBxWhite if (source == "cps")

gen acs_data = (source == "acs")

gen weight = perwt
replace weight = pwcmpwgt if source == "cps"

* unweighted ACS vs. unweighted CPS, MSAs in both
reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

********************************************************************************
* unweighted ACS, no GQ vs. unweighted CPS, MSAs in both
drop if (gq == 3 | gq == 4) & source == "acs"

reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite, absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

********************************************************************************
* weighted ACS, no GQ vs. weighted CPS, MSAs in both
reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite [aw = weight], absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite

********************************************************************************
* weighted ACS, no GQ vs. weighted CPS 2008+, MSAs in both
reghdfe employed acsBTBxBlack cpsBTBxBlack acsBTBxHisp cpsBTBxHisp acsBTBxWhite cpsBTBxWhite if year >= 2008 [aw = weight], absorb(time_both#gereg#group_both#acs_data age#group_both#acs_data enrolled_both#group_both#acs_data highedu_both#group_both#acs_data acs_data#metroFIPS#black_both##c.time_both acs_data#metroFIPS#hisp_both##c.time_both acs_data#metroFIPS#white_both##c.time_both, savefe) vce(cluster stateFIPS)

test acsBTBxBlack = cpsBTBxBlack

test acsBTBxHisp = cpsBTBxHisp

test acsBTBxWhite = cpsBTBxWhite


log close