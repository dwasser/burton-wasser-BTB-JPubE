*****
/*
Anne Burton and David Wasser
Build alternative data source using ACS data
*/

clear all
set more off
capture log close
set maxvar 120000

log using "$build_log/build_acs_data.txt", text replace


/*------------------------------------------------------------------------------
build_acs_data.do

CREATED BY: Anne M. Burton
CREATED ON: 24 September 2019 by Anne M. Burton
UPDATED ON: 27 August 2025 by Anne M. Burton (final check for replication package)

SOURCES: ACS from IPUMS

DESCRIPTION: code for cleaning ACS data
-----------------------------------------------------------------------------*/

use "$build_data/usa_00008.dta", clear

*** Sample filters
* Filter on year: 2004+
qui keep if year >= 2004	

*** Analysis variables
* Citizenship
gen us_citizen = (citizen <= 2)
drop citizen

* Skills/education
qui gen no_hs = (educd <= 61)
qui gen hs_deg = (educd == 62 | educd == 63 | educd == 64)
qui gen no_coll_deg = (educd <= 71)
qui gen coll_deg = (educd == 81 | educd == 101 | educd == 114 | educd == 115 | educd == 116)
qui label var no_hs "No high school diploma or GED"
qui label var hs_deg "High school diploma or GED"
qui label var no_coll_deg "Less than a college degree"
qui label var coll_deg "At least an associate's degree"

* Doleac and Hansen (2020) sample
gen dh_sample = (us_citizen == 1 & educ <=8 & year >= 2004 & year <= 2014) // Note that educ <= 8 actually includes workers with associate degrees

* Employment
qui gen employed = (empstat == 1)
qui label var employed "Worked for pay last week (empstat == 1)"

* Public sector employment 
gen employed_public = (ind1990 >= 900 & ind1990 <= 932 & empstat == 1)
		
* Enrolled in school
qui gen in_school = (school == 2)
qui label var in_school "Enrolled in school (school == 2)"

*rename some variables
rename statefip stateFIPS
rename countyfip fips_county_code
rename metarea msa_code
rename met2013 msa_2013
		
gen metroFIPS = msa_2013 
replace metroFIPS = stateFIPS if (msa_2013 == . | msa_2013 == 0)

***** Clean data and refine sample 
rename msa_2013 cbsa_code

* Keep only men for now 
keep if (sex == 1)

* Stop sample in 2014
drop if (year > 2014)

* Code region and divisions for FEs
gen gereg = 1 if (region == 11 | region == 12)
replace gereg = 2 if (region == 21 | region == 22)
replace gereg = 3 if (region == 31 | region == 32 | region == 33)
replace gereg = 4 if (region == 41 | region == 42)
label define lab_gereg 1 "Northeast" 2 "Midwest" 3 "South" 4 "West"
label values gereg lab_gereg
label var gereg "Census Regions"
qui tab gereg, gen(reg)
label var reg1 "Northeast"
label var reg2 "Midwest"
label var reg3 "South"
label var reg4 "West"

rename region division
label var division "Census division"

********************************************************************************
* Merge on BTB policy assignment from Doleac and Hansen (2020)
merge m:1 year metroFIPS stateFIPS using "$analysis_data/dh_btb_policy_assignment.dta"
drop _merge

gen dh_hisp = (hispan >= 1 & hispan <= 4)
gen dh_blackNH = (racblk == 2 & dh_hisp == 0)
gen dh_whiteNH = (racwht == 2 & dh_hisp == 0)

gen dh_group = . 
replace dh_group = 1 if (dh_whiteNH == 1)
replace dh_group = 2 if (dh_blackNH == 1)
replace dh_group = 3 if (dh_hisp == 1)
label define lab_dh_group 1 "White, non-Hispanic" 2 "Black, non-Hispanic" 3 "Hispanic"
label values dh_group lab_dh_group

keep if (dh_group != .)

* BTB X race dummies
gen dhBTBxBlackNH = dhBTB*dh_blackNH
gen dhBTBxWhiteNH = dhBTB*dh_whiteNH
gen dhBTBxHisp = dhBTB*dh_hisp

********************************************************************************
* Merge on corrected BTB policy assignment
merge m:1 metroFIPS stateFIPS year using "$analysis_data/btb_annual_laws.dta"
keep if (_merge == 1 | _merge == 3)
drop _merge 

* Add in treatment dates for non-MSAs covered by state laws
replace BTB = 0 if (metroFIPS == stateFIPS)
replace BTB = 1 if (metroFIPS == 06 & year >= 2011) // California
replace BTB = 1 if (metroFIPS == 08 & year >= 2013) // Colorado
replace BTB = 1 if (metroFIPS == 09 & year >= 2011) // Connecticut
replace BTB = 1 if (metroFIPS == 10 & year >= 2015) // Delaware
replace BTB = 1 if (metroFIPS == 15 & year >= 1998) // Hawaii
replace BTB = 1 if (metroFIPS == 17 & year >= 2014) // Illinois
replace BTB = 1 if (metroFIPS == 24 & year >= 2014) // Maryland
replace BTB = 1 if (metroFIPS == 25 & year >= 2011) // Massachusetts
replace BTB = 1 if (metroFIPS == 27 & year >= 2009) // Minnesota
replace BTB = 1 if (metroFIPS == 31 & year >= 2015) // Nebraska
replace BTB = 1 if (metroFIPS == 35 & year >= 2011) // New Mexico
replace BTB = 1 if (metroFIPS == 44 & year >= 2014) // Rhode Island


bys metroFIPS: egen BTBever = max(BTB)
replace BTBever = 1 if (BTBever > 0) 

* Corrected treatment variable
gen BTBxBlackNH = BTB*dh_blackNH
gen BTBxWhiteNH = BTB*dh_whiteNH
gen BTBxHisp = BTB*dh_hisp

ren btb_eff btb_eff_year

********************************************************************************
* Note: this actually includes people with an associate's degree and also those with some college credit but no degree
gen dh_noCollege = (educd <= 81)

* Time variable
gen dh_time = 0
replace dh_time = 12 if year == 2005
replace dh_time = 24 if year == 2006
replace dh_time = 36 if year == 2007
replace dh_time = 48 if year == 2008
replace dh_time = 60 if year == 2009
replace dh_time = 72 if year == 2010
replace dh_time = 84 if year == 2011
replace dh_time = 96 if year == 2012
replace dh_time = 108 if year == 2013
replace dh_time = 120 if year == 2014


***** Save the dataset
compress
save "$analysis_data/btb_acs_analysis_table.dta", replace 

log close
