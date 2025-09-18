*DATASETS
local dataname "test_mig_map" 

*VARIABLES
local mapvar in_returns
local countyvar receiving_county

*MAP OPTIONS
local mapname "Test Map"
local clmethod "custom"
local clcuts "25 50 75"
local mapcolor Blues
local ndfcolor white

set more off

cap log close
log using "$logdir/county_maps_creation.log", replace

*** the following dataset is made in "$build/btb_annual_laws.do": ***
use "$analysis_data/btb_annual_laws_map.dta", clear

* Drop Puerto Rico
drop if (stateFIPS == 72)

* Create BTBever variable
bys metroFIPS: egen BTBever = max(BTB_eos)

gen county = stateFIPS*1000 + fips_county_code

* merge in maptile's county file to get non-MSA counties
merge m:1 county using "$maptile/county2014_database.dta"
* bedford city, va only in master

replace stateFIPS = statefips if _merge == 2
replace fips_county_code = county-stateFIPS*1000 if _merge == 2
replace year = 2014 if _merge == 2
replace BTBever = 0 if _merge == 2

bys stateFIPS: egen BTBstate = max(btb_state_eos) 

tab stateFIPS BTBstate
replace BTBever = BTBstate if _merge == 2


* Only keep necessary variables 
keep metroFIPS msa_name fips_county_code county BTBever
collapse (first) BTBever, by(metroFIPS msa_name fips_county_code county)

rename metroFIPS cbsa2013

*** appendix figure a.1: map of MSAs and states covered by BTB by December 2014 (end of sample period) ***
maptile BTBever, geo(county2014) cutvalues(0(1)1) twopt(legend(off)) fcolor(""255 255 255" "90 90 90"") ndfcolor(white) stateoutline(vthin)

graph export "$out/BTB_msas.eps", replace
graph export "$out/figureA1.pdf", replace

log close