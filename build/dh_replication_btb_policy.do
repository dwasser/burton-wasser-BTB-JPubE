* Get Doleac and Hansen (2020) BTB assignment from their posted replication materials

********************************************************************************
* ACS data
********************************************************************************

use "$dh_replication/BTB_ACS.dta", clear

local dh_sample = "male==1 & age>=25 & age<35  & citizen==1"
keep if `dh_sample'

keep year metroFIPS stateFIPS blackNH whiteNH hisp BTBever BTBx* time*

duplicates drop 
label drop _all 

gen BTB = 0
replace BTB = 1 if (BTBxWhiteNH == 1 & whiteNH == 1)
replace BTB = 1 if (BTBxBlackNH == 1 & blackNH == 1)
replace BTB = 1 if (BTBxHisp == 1 & hisp == 1)

keep year metroFIPS stateFIPS BTB BTBever

ren BTB dhBTB
ren BTBever dhBTBever

duplicates drop

save "$analysis_data/dh_btb_policy_assignment.dta", replace

********************************************************************************
* CPS data
********************************************************************************
use  "$dh_replication/BTB_data.dta", clear

local dh_sample = "male==1 & age>=25 & age<35  & citizen==1 & retired==0 & noCollege==1"
keep if `dh_sample'

keep month year time stateFIPS metroFIPS BTB BTBever time_BTBpub

duplicates drop 
label drop _all 

ren BTB dhBTB
ren BTBever dhBTBever

save "$analysis_data/dh_btb_policy_assignment_cps_original.dta", replace