* Create summary statistics and figures using ACS data

set more off
capture log close

log using "$analyze_log/summary_stats_acs.txt", text replace

*** the following dataset is made in "$analyze/analysis_btb_acs_correctDH.do": ***
use "$analysis_data/dh_acs_analysistable_corrected.dta", clear

***** Summary statistics table
gen employed_ever_btb_pre = employed if (BTB == 0 & BTBever == 1)
label var employed_ever_btb_pre "Employed: before BTB"

gen employed_ever_btb = employed if (BTBever == 1)
label var employed_ever_btb "Employed: ever BTB"

gen employed_never_btb = employed if (BTBever == 0) 
label var employed_never_btb "Employed: never BTB"


gen metro_area = (metroFIPS != stateFIPS)

* No sub-state geographies in 2004 ACS
replace metro_area = . if year == 2004 
label var metro_area "Live in MSA"

capture drop ged_or_hs
gen ged_or_hs = (educd == 62 | educd == 63 | educd == 64)
label variable ged_or_hs "High School Diploma or GED"

label variable age "Age"
label variable BTBever "Ever BTB"
label variable in_school "Enrolled in school"
label variable employed "Employed"

local summ_vars "BTB BTBever dh_white dh_black dh_hisp age in_school no_hs ged_or_hs metro_area reg1 reg2 reg3 reg4 employed_ever_btb employed_ever_btb_pre employed_never_btb"


eststo clear
bys dh_group BTBever : eststo: qui estpost summ `summ_vars'
esttab using "$out/tableA1.tex", replace compress nogaps main(mean 4) aux(sd 4) label nostar nodepvar unstack nonotes mtitles("White" "White" "Black" "Black" "Hispanic" "Hispanic")


log close 