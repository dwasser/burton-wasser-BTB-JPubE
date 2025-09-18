clear all
set more off
capture log close

set maxvar 120000

log using "$build_log/build_btb_monthly_bw.txt", text replace


*import principal city info, from feb. 2013: https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html
import excel "$build_data/msa_principal_cities_feb2013.xls", sheet("List 2") cellrange(A3:F1252) firstrow clear

*only keep metropolitan statistical areas (as opposed to including micropolitan statistical areas)
keep if MetropolitanMicropolitanStatis == "Metropolitan Statistical Area"

*rename the variables i want to keep
ren CBSACode metroFIPS
ren CBSATitle msa_name
ren PrincipalCityName principal_city
ren FIPSStateCode stateFIPS
ren FIPSPlaceCode fips_place_code

keep metroFIPS msa_name principal_city stateFIPS fips_place_code

destring metroFIPS, replace
destring stateFIPS, replace
destring fips_place_code, replace

sort metroFIPS principal_city
by metroFIPS: gen number = _n

*reshape to merge with the other datasets
reshape wide principal_city stateFIPS fips_place_code, i(metroFIPS msa_name) j(number)

save "$build_data/msa_principal_cities_2013_cps.dta", replace

*** merge msa file with principal city info ***

*** the following dataset is made in "$build/build_btb_annual_bw.do" ***
use "$build_data/msa_2013.dta", clear
merge m:1 metroFIPS msa_name using "$build_data/msa_principal_cities_2013_cps.dta"

drop _merge

*** merge msa file with central city info ***

*** the using dataset is made in "$build/build_btb_annual_bw.do" ***
merge m:1 metroFIPS using "$build_data/msa_central_cities_2013.dta"

*fix some unmerged from master
*there are no unmerged MSAs with more than 3 principal cities, so, make the central cities be the first 3 principal cities
replace central_city_1 = principal_city1 if _merge == 1
replace central_city_2 = principal_city2 if _merge == 1
replace central_city_3 = principal_city3 if _merge == 1

*verified by checking that the MSA name matches the central cities from this method ^^

gen flag = 1
replace flag = 0 if msa_name == msa_label
tab flag _merge
drop _merge

ren stateFIPS v1_stateFIPS

*reshape again so to get correct btb law based on central city
reshape long principal_city stateFIPS fips_place_code, i(metroFIPS msa_name v1_stateFIPS fips_county_code) j(number)

ren stateFIPS pc_stateFIPS
ren v1_stateFIPS stateFIPS
label variable pc_stateFIPS "principal city's state fips"
label variable fips_place_code "principal city's place fips"
label variable stateFIPS "MSA-state-county's state fips"
label variable fips_county_code "MSA-state-county's county fips"

drop if principal_city == ""

drop if pc_stateFIPS != stateFIPS & number > 1
bysort metroFIPS stateFIPS: egen number2 = max(number)
drop if pc_stateFIPS != stateFIPS & number == 1 & number2 > 1

drop number number2

save "$build_data/msa_w_cities_cps.dta", replace


*expand the dataset to make it a time series
expand 132
bysort metroFIPS stateFIPS fips_county_code principal_city: gen number = _n
gen data_start = tm(2004m01)
format data_start %tm
gen time_moyr = data_start + number - 1
format time_moyr %tm
drop number data_start

*** BTB code for CPS ***
* we assign treatment based on Table 1 of Doleac and Hansen (2020), Avery and Lu (2020), and law firm/news websites to verify effective dates

*considered as treated if BTB is effective on the 15th of the month

*make btb effective date and btb treated variables
gen btb_eff_city = .
gen btb_eff_city_pub = .
gen btb_eff_city_con = .
gen btb_eff_city_pri = .
gen btb_city = .
gen btb_city_pub = .
gen btb_city_con = .
gen btb_city_pri = .


/* 
*** cities/counties are commented out in this section of code for 2 reasons: ***
	1. they are not/do not contain a principal city in an MSA. in this case, if they were the first "city" law implemented in the MSA, we
			re-code the effective treatment date for these MSAs below
	2. they implemented a law after the county that they are in did. we want the earliest law implemented so we do not use these later city
			laws
		
	* note: some of these effective dates are outside our sample period. we are including them for completeness but we do not use them in our
			analysis
*/

//California
* Compton July 1, 2011 (public)
*replace btb_eff_city_pub = tm(2011m07) if metroFIPS == 31080 & stateFIPS == 6 & fips_place_code == 
* Compton July 1, 2011 (contract)
*replace btb_eff_city_con = tm(2011m07) if metroFIPS == 31080 & stateFIPS == 6 & fips_place_code == 
* Carson City March 6, 2012 (public)
replace btb_eff_city_pub = tm(2012m03) if metroFIPS == 31080 & stateFIPS == 6 & fips_place_code == 11530
* Pasadena July 1, 2013 (public)
replace btb_eff_city_pub = tm(2013m07) if metroFIPS == 31080 & stateFIPS == 6 & fips_place_code == 56000
* Santa Clara May 1, 2012 (public)
replace btb_eff_city_pub = tm(2012m05) if metroFIPS == 41940 & stateFIPS == 6 & fips_place_code == 69084
* East Palo Alto January 1, 2005 (public)
*replace btb_eff_city_pub = tm(2005m01) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 
* San Francisco October 11, 2005 (public)
replace btb_eff_city_pub = tm(2005m10) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 67000
* Oakland January 1, 2007 (public)
replace btb_eff_city_pub = tm(2007m01) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 53000
* Alameda County March 1, 2007 (public covered by Oakland)
replace btb_eff_city_pub = tm(2007m03) if metroFIPS == 41860 & stateFIPS == 6 & fips_county_code == 1 & fips_place_code != 53000
* Berkeley October 1, 2008 (public covered by Alameda County)
*replace btb_eff_city_pub = tm(2008m10) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 06000
* Richmond November 22, 2011 (treatment effective in December. public)
*replace btb_eff_city_pub = tm(2011m12) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 
* Richmond July 30, 2013 (treatment effective in August. contract)
*replace btb_eff_city_con = tm(2013m08) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 
* San Francisco April 4, 2014 (contract)
replace btb_eff_city_con = tm(2014m04) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 67000
* San Francisco April 4, 2014 (private)
replace btb_eff_city_pri = tm(2014m04) if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 67000


//Connecticut
* Bridgeport October 5, 2009 (public)
replace btb_eff_city_pub = tm(2009m10) if metroFIPS == 14860 & stateFIPS == 9 & fips_place_code == 08000
* Hartford August 9, 2009 (public)
replace btb_eff_city_pub = tm(2009m08) if metroFIPS == 25540 & stateFIPS == 9 & fips_place_code == 37000
* Hartford August 9, 2009 (contract)
replace btb_eff_city_con = tm(2009m08) if metroFIPS == 25540 & stateFIPS == 9 & fips_place_code == 37000
* New Haven enacted February 17, 2009. effective date unknown, so we assume it becomes effective one month later (treatment effective in April. public)
replace btb_eff_city_pub = tm(2009m04) if metroFIPS == 35300 & stateFIPS == 9 & fips_place_code == 52000
* New Haven enacted February 17, 2009. effective date unknown, so we assume it becomes effective one month later (treatment effective in April. contract)
replace btb_eff_city_con = tm(2009m04) if metroFIPS == 35300 & stateFIPS == 9 & fips_place_code == 52000
* Norwich December 1, 2008 (public)
replace btb_eff_city_pub = tm(2008m12) if metroFIPS == 35980 & stateFIPS == 9 & fips_place_code == 56200


//Delaware 
* Wilmington December 10, 2012 (public)
replace btb_eff_city_pub = tm(2012m12) if metroFIPS == 37980 & stateFIPS == 10 & fips_place_code == 77580
* New Castle County January 28, 2014 (treatment effective in February. public covered by Wilmington)
replace btb_eff_city_pub = tm(2014m02) if metroFIPS == 37980 & stateFIPS == 10 & fips_county_code == 3 & fips_place_code != 77580


//District of Columbia
* Washington, DC January 1, 2011 (public)
replace btb_eff_city_pub = tm(2011m01) if metroFIPS == 47900 & stateFIPS == 11 & fips_place_code == 50000
* Washington, DC December 17, 2014 (treatment effective in January 2015. contract)
replace btb_eff_city_con = tm(2015m01) if metroFIPS == 47900 & stateFIPS == 11 & fips_place_code == 50000
* Washington, DC December 17, 2014 (treatment effective in January 2015. private)
replace btb_eff_city_pri = tm(2015m01) if metroFIPS == 47900 & stateFIPS == 11 & fips_place_code == 50000


//Florida 
* Jacksonville November 10, 2008 (public)
replace btb_eff_city_pub = tm(2008m11) if metroFIPS == 27260 & stateFIPS == 12 & fips_place_code == 35000
* Jacksonville November 10, 2008 (contract)
replace btb_eff_city_con = tm(2008m11) if metroFIPS == 27260 & stateFIPS == 12 & fips_place_code == 35000
* Pompano Beach December 1, 2014 (public)
replace btb_eff_city_pub = tm(2014m12) if metroFIPS == 33100 & stateFIPS == 12 & fips_place_code == 58050
* Tampa January 14, 2013 (public)
replace btb_eff_city_pub = tm(2013m01) if metroFIPS == 45300 & stateFIPS == 12 & fips_place_code == 71000


//Georgia 
* Atlanta January 1, 2013 (public))
replace btb_eff_city_pub = tm(2013m01) if metroFIPS == 12060 & stateFIPS == 13 & fips_place_code == 04000
* Fulton County July 16, 2014 (treatment effective in August. covered by Atlanta)
replace btb_eff_city_pub = tm(2014m08) if metroFIPS == 12060 & stateFIPS == 13 & fips_county_code == 121 & fips_place_code != 04000


//Illinois 
* Chicago June 6, 2007 (public)
replace btb_eff_city_pub = tm(2007m06) if metroFIPS == 16980 & stateFIPS == 17 & fips_place_code == 14000
* Chicago November 5, 2014 (contract)
replace btb_eff_city_con = tm(2014m11) if metroFIPS == 16980 & stateFIPS == 17 & fips_place_code == 14000
* Chicago November 5, 2014 (private)
replace btb_eff_city_pri = tm(2014m11) if metroFIPS == 16980 & stateFIPS == 17 & fips_place_code == 14000


//Indiana 
* Indianapolis June 5,2014 (public)
replace btb_eff_city_pub = tm(2014m06) if metroFIPS == 26900 & stateFIPS == 18 & fips_place_code == 36003
* Indianapolis June 5,2014 (contract)
replace btb_eff_city_con = tm(2014m06) if metroFIPS == 26900 & stateFIPS == 18 & fips_place_code == 36003


//Kentucky 
* Louisville March 25, 2014 (treatment effective in April. public)
replace btb_eff_city_pub = tm(2014m04) if metroFIPS == 31140 & stateFIPS == 21 & fips_place_code == 48006
* Louisville March 25, 2014 (treatment effective in April. contract)
replace btb_eff_city_con = tm(2014m04) if metroFIPS == 31140 & stateFIPS == 21 & fips_place_code == 48006


//Kansas 
* Kansas City November 6, 2014 (public)
replace btb_eff_city_pub = tm(2014m11) if metroFIPS == 28140 & stateFIPS == 20 & fips_place_code == 36000
* Wyandotte County November 6, 2014 (public covered by Kansas City)
replace btb_eff_city_pub = tm(2014m11) if metroFIPS == 28140 & stateFIPS == 20 & fips_county_code == 209 & fips_place_code != 36000


//Louisiana 
* New Orleans January 10, 2014 (public)	
replace btb_eff_city_pub = tm(2014m01) if metroFIPS == 35380 & stateFIPS == 22 & fips_place_code == 55000


//Maryland 
* Baltimore December 1, 2007 (public)
replace btb_eff_city_pub = tm(2007m12) if metroFIPS == 12580 & stateFIPS == 24 & fips_place_code == 04000
* Baltimore August 13, 2014 (contract)
replace btb_eff_city_con = tm(2014m08) if metroFIPS == 12580 & stateFIPS == 24 & fips_place_code == 04000
* Baltimore August 13, 2014 (private)
replace btb_eff_city_pri = tm(2014m08) if metroFIPS == 12580 & stateFIPS == 24 & fips_place_code == 04000
* Montgomery County January 1, 2015 (public Bethesda, Gaithersburg, Rockville, Silver Spring)
replace btb_eff_city_pub = tm(2015m01) if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 31
* Montgomery County January 1, 2015 (contract)
replace btb_eff_city_con = tm(2015m01) if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 31
* Montgomery County January 1, 2015 (private)
replace btb_eff_city_pri = tm(2015m01) if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 31
* Prince George's County December 4, 2014 (public)
replace btb_eff_city_pub = tm(2014m12) if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 33
* Prince George's County January 20, 2015 (treatment effective in February. contract)
replace btb_eff_city_con = tm(2015m02) if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 33
* Prince George's County January 20, 2015 (treatment effective in February. private)
replace btb_eff_city_pri = tm(2015m02) if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 33


//Massachusetts 
* Boston July 1, 2006 (public)
replace btb_eff_city_pub = tm(2006m07) if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 07000
* Boston July 1, 2006 (contract)  
replace btb_eff_city_con = tm(2006m07) if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 07000
* Cambridge May 1, 2007 (public)
replace btb_eff_city_pub = tm(2007m05) if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 11000
* Cambridge January 28, 2008 (treatment effective in February. contract)
replace btb_eff_city_con = tm(2008m02) if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 11000
* Worcester September 1, 2009 (public)
replace btb_eff_city_pub = tm(2009m09) if metroFIPS == 49340 & stateFIPS == 25 & fips_place_code == 82000
* Worcester September 1, 2009 (contract)
replace btb_eff_city_con = tm(2009m09) if metroFIPS == 49340 & stateFIPS == 25 & fips_place_code == 82000


//Michigan 
* Ann Arbor May 5, 2014 (public)
replace btb_eff_city_pub = tm(2014m05) if metroFIPS == 11460 & stateFIPS == 26 & fips_place_code == 03000
* Detroit September 13, 2010 (public)
replace btb_eff_city_pub = tm(2010m09) if metroFIPS == 19820 & stateFIPS == 26 & fips_place_code == 22000
* Detroit February 1, 2012 (contract)
replace btb_eff_city_con = tm(2012m02) if metroFIPS == 19820 & stateFIPS == 26 & fips_place_code == 22000
* East Lansing April 15, 2014 (public)
replace btb_eff_city_pub = tm(2014m04) if metroFIPS == 29620 & stateFIPS == 26 & fips_place_code == 24120
* Genesee County June 1, 2014 (public Flint)
replace btb_eff_city_pub = tm(2014m06) if metroFIPS == 22420 & stateFIPS == 26 & fips_county_code == 49
* Kalamazoo January 1, 2010 (public)
replace btb_eff_city_pub = tm(2010m01) if metroFIPS == 28020 & stateFIPS == 26 & fips_place_code == 42160
* Muskegon January 12, 2012 (public)
replace btb_eff_city_pub = tm(2012m01) if metroFIPS == 34740 & stateFIPS == 26 & fips_place_code == 56320


//Minnesota
* Minneapolis December 1, 2006 (public)
replace btb_eff_city_pub = tm(2006m12) if metroFIPS == 33460 & stateFIPS == 27 & fips_place_code == 43000
* St. Paul December 5, 2006 (public)
replace btb_eff_city_pub = tm(2006m12) if metroFIPS == 33460 & stateFIPS == 27 & fips_place_code == 58000


//Missouri
* Columbia December 1, 2014 (public)	
replace btb_eff_city_pub = tm(2014m12) if metroFIPS == 17860 & stateFIPS == 29 & fips_place_code == 15670
* Columbia December 1, 2014 (contract)	
replace btb_eff_city_con = tm(2014m12) if metroFIPS == 17860 & stateFIPS == 29 & fips_place_code == 15670
* Columbia December 1, 2014 (private)	
replace btb_eff_city_pri = tm(2014m12) if metroFIPS == 17860 & stateFIPS == 29 & fips_place_code == 15670
* Kansas City April 4, 2013 (public)
replace btb_eff_city_pub = tm(2013m04) if metroFIPS == 28140 & stateFIPS == 29 & fips_place_code == 38000
* St. Louis October 1, 2014 (public)
replace btb_eff_city_pub = tm(2014m10) if metroFIPS == 41180 & stateFIPS == 29 & fips_place_code == 65000


//New Jersey
* Atlantic City December 23, 2011 (treatment effective in January 2012. public)
replace btb_eff_city_pub = tm(2012m01) if metroFIPS == 12100 & stateFIPS == 34 & fips_place_code == 02080
* Atlantic City December 23, 2011 (treatment effective in January 2012. contract)
replace btb_eff_city_con = tm(2012m01) if metroFIPS == 12100 & stateFIPS == 34 & fips_place_code == 02080
* Newark November 18, 2012 (treatment effective in December. public)
replace btb_eff_city_pub = tm(2012m12) if metroFIPS == 35620 & stateFIPS == 34 & fips_place_code == 51000
* Newark November 18, 2012 (treatment effective in December. contract)
replace btb_eff_city_con = tm(2012m12) if metroFIPS == 35620 & stateFIPS == 34 & fips_place_code == 51000
* Newark November 18, 2012 (treatment effective in December. private)
replace btb_eff_city_pri = tm(2012m12) if metroFIPS == 35620 & stateFIPS == 34 & fips_place_code == 51000


//New York
* New York City October 3, 2011 (public)
replace btb_eff_city_pub = tm(2011m10) if metroFIPS == 35620 & stateFIPS == 36 & fips_place_code == 51000
* Yonkers November 1, 2014 (public)
*replace btb_eff_city_pub = tm(2014m11) if metroFIPS == 35620 & stateFIPS == 36 & fips_place_code ==
* New York City October 3, 2011 (contract)
replace btb_eff_city_con = tm(2011m10) if metroFIPS == 35620 & stateFIPS == 36 & fips_place_code == 51000
* Buffalo June 11, 2013 (public)
replace btb_eff_city_pub = tm(2013m06) if metroFIPS == 15380 & stateFIPS == 36 & fips_place_code == 11000
* Buffalo June 11, 2013 (contract)
replace btb_eff_city_con = tm(2013m06) if metroFIPS == 15380 & stateFIPS == 36 & fips_place_code == 11000
* Buffalo June 11, 2013 (private)
replace btb_eff_city_pri = tm(2013m06) if metroFIPS == 15380 & stateFIPS == 36 & fips_place_code == 11000
* Rochester May 20, 2014 (treatment effective in June. public)
replace btb_eff_city_pub = tm(2014m06) if metroFIPS == 40380 & stateFIPS == 36 & fips_place_code == 63000
* Rochester May 20, 2014 (treatment effective in June. contract)
replace btb_eff_city_con = tm(2014m06) if metroFIPS == 40380 & stateFIPS == 36 & fips_place_code == 63000
* Rochester May 20, 2014 (treatment effective in June. private)
replace btb_eff_city_pri = tm(2014m06) if metroFIPS == 40380 & stateFIPS == 36 & fips_place_code == 63000
* Woodstock November 18, 2014 (treatment effective in December. public Kingston)
*replace btb_eff_city_pub = tm(2014m12) if metroFIPS == 28740 & stateFIPS == 36 & fips_place_code == 


//North Carolina
* Durham February 1, 2011 (public)
replace btb_eff_city_pub = tm(2011m02) if metroFIPS == 20500 & stateFIPS == 37 & fips_place_code == 19000
* Carrboro October 16, 2012 (treatment effective in November. public)
*replace btb_eff_city_pub = tm(2012m11) if metroFIPS == 20500 & stateFIPS == 37 & fips_place_code == 
* Durham County October 1, 2012 (public covered by Durham)
replace btb_eff_city_pub = tm(2012m10) if metroFIPS == 20500 & stateFIPS == 37 & fips_county_code == 63 & fips_place_code != 19000
* Charlotte February 28, 2014 (treatment effective in March. public)
replace btb_eff_city_pub = tm(2014m03) if metroFIPS == 16740 & stateFIPS == 37 & fips_place_code == 12000
* Cumberland County September 6, 2011 (public Fayetteville)
replace btb_eff_city_pub = tm(2011m09) if metroFIPS == 22180 & stateFIPS == 37 & fips_county_code == 51
* Spring Lake June 25, 2012 (treatment effective in July. public covered by Cumberland County)
*replace btb_eff_city_pub = tm(2012m07) if metroFIPS == 22180 & stateFIPS == 37 & fips_place_code == 


//Ohio 
* Cincinnati August 1, 2010 (public)
replace btb_eff_city_pub = tm(2010m08) if metroFIPS == 17140 & stateFIPS == 39 & fips_place_code == 15000
* Hamilton County March 1, 2012 (public covered by Cincinnati)
replace btb_eff_city_pub = tm(2012m03) if metroFIPS == 17140 & stateFIPS == 39 & fips_county_code == 61 & fips_place_code != 15000
* Cleveland September 26, 2011 (treatment effective in October. public)
replace btb_eff_city_pub = tm(2011m10) if metroFIPS == 17460 & stateFIPS == 39 & fips_place_code == 16000
* Cuyahoga County September 30, 2012 (treatment effective in October. public covered by Cleveland)
replace btb_eff_city_pub = tm(2012m10) if metroFIPS == 17460 & stateFIPS == 39 & fips_county_code == 35 & fips_place_code != 16000
* Stark County May 1, 2013 (public Canton, Massillon, Alliance)
replace btb_eff_city_pub = tm(2013m05) if metroFIPS == 15940 & stateFIPS == 39 & fips_county_code == 151
* Canton May 15, 2013 (public covered by Stark County)
*replace btb_eff_city_pub = tm(2013m05) if metroFIPS == 15940 & stateFIPS == 39 & fips_place_code == 12000
* Massillon January 3, 2014 (public covered by Stark County)
*replace btb_eff_city_pub = tm(2014m01) if metroFIPS == 15940 & stateFIPS == 39 & fips_place_code == 48244
* Alliance December 1, 2014 (public covered by Stark County)
*replace btb_eff_city_pub = tm(2014m12) if metroFIPS == 15940 & stateFIPS == 39 & fips_place_code == 
* Franklin County June 19, 2012 (treatment effective in July. public Columbus)
replace btb_eff_city_pub = tm(2012m07) if metroFIPS == 18140 & stateFIPS == 39 & fips_county_code == 49
* Lucas County October 29, 2013 (treatment effective in November. public Toledo)
replace btb_eff_city_pub = tm(2013m11) if metroFIPS == 45780 & stateFIPS == 39 & fips_county_code == 95
* Summit County September 1, 2012 (public Akron)
replace btb_eff_city_pub = tm(2012m09) if metroFIPS == 10420 & stateFIPS == 39 & fips_county_code == 153
* Akron October 29, 2013 (treatment effective in November. public covered by Summit County)
*replace btb_eff_city_pub = tm(2013m11) if metroFIPS == 10420 & stateFIPS == 39 & fips_place_code == 01000
* Youngstown March 19, 2014 (treatment effective in April. public)
replace btb_eff_city_pub = tm(2014m04) if metroFIPS == 49660 & stateFIPS == 39 & fips_place_code == 88000


//Oregon
* Multnomah County October 10, 2007 (public Portland)
replace btb_eff_city_pub = tm(2007m10) if metroFIPS == 38900 & stateFIPS == 41 & fips_county_code == 51
* Portland July 9, 2014 (public covered by Multnomah County)
*replace btb_eff_city_pub = tm(2014m07) if metroFIPS == 38900 & stateFIPS == 41 & fips_place_code == 59000


//Pennsylvania
* Lancaster October 1, 2014 (public)
replace btb_eff_city_pub = tm(2014m10) if metroFIPS == 29540 & stateFIPS == 42 & fips_place_code == 41216
* Philadelphia June 29, 2011 (treatment effective in July. public)
replace btb_eff_city_pub = tm(2011m07) if metroFIPS == 37980 & stateFIPS == 42 & fips_place_code == 60000
* Philadelphia June 29, 2011 (treatment effective in July. contract)
replace btb_eff_city_con = tm(2011m07) if metroFIPS == 37980 & stateFIPS == 42 & fips_place_code == 60000
* Philadelphia June 29, 2011 (treatment effective in July. private)
replace btb_eff_city_pri = tm(2011m07) if metroFIPS == 37980 & stateFIPS == 42 & fips_place_code == 60000
* Pittsburgh December 31, 2012 (treatment effective in January 2013. public)
replace btb_eff_city_con = tm(2013m01) if metroFIPS == 38300 & stateFIPS == 42 & fips_place_code == 61000
* Pittsburgh December 31, 2012 (treatment effective in January 2013. contract)
replace btb_eff_city_con = tm(2013m01) if metroFIPS == 38300 & stateFIPS == 42 & fips_place_code == 61000
* Allegheny County November 24, 2014 (treatment effective in December. public covered by Pittsburgh)
replace btb_eff_city_pub = tm(2014m12) if metroFIPS == 38300 & stateFIPS == 42 & fips_county_code == 3 & fips_place_code != 61000


//Rhode Island
* Providence April 1, 2009 (public)
replace btb_eff_city_pub = tm(2009m04) if metroFIPS == 39300 & stateFIPS == 44 & fips_place_code == 59000


//Tennessee
* Memphis July 9, 2010 (public)
replace btb_eff_city_pub = tm(2010m07) if metroFIPS == 32820 & stateFIPS == 47 & fips_place_code == 48000
* Hamilton County January 1, 2012 (public Chattanooga)
replace btb_eff_city_pub = tm(2012m01) if metroFIPS == 16860 & stateFIPS == 47 & fips_county_code == 65


//Texas 
* Travis County April 15, 2008 (public Austin)
replace btb_eff_city_pub = tm(2008m04) if metroFIPS == 12420 & stateFIPS == 48 & fips_county_code == 453
* Austin October 16, 2008 (treatment effective in November. public covered by Travis County)
*replace btb_eff_city_pub = tm(2008m11) if metroFIPS == 12420 & stateFIPS == 48 & fips_place_code == 05000


//Virginia
* Newport News October 1, 2012 (public)
replace btb_eff_city_pub = tm(2012m10) if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 56000
* Virginia Beach November 1, 2013 (public)
replace btb_eff_city_pub = tm(2013m11) if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 82000
* Portsmouth April 1, 2013 (public)
replace btb_eff_city_pub = tm(2013m04) if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 64000
* Norfolk July 23, 2013 (treatment effective in August. public)
replace btb_eff_city_pub = tm(2013m08) if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 57000
* Richmond March 25, 2013 (treatment effective in April. public)
replace btb_eff_city_pub = tm(2013m04) if metroFIPS == 40060 & stateFIPS == 51 & fips_place_code == 67000
* Petersburg September 3, 2013 (public)
*replace btb_eff_city_pub = tm(2013m09) if metroFIPS == 40060 & stateFIPS == 51 & fips_place_code == 
* Charlottesville March 1, 2014 (public)
replace btb_eff_city_pub = tm(2014m03) if metroFIPS == 16820 & stateFIPS == 51 & fips_place_code == 14968
* Danville July 1, 2014 (public)
replace btb_eff_city_pub = tm(2014m07) if metroFIPS == 19260 & stateFIPS == 51 & fips_place_code == 21344
* Fredericksburg, VA enacted June 5, 2014. effective date unknown so assume it's one month later (public)
*replace btb_eff_city_pub = tm(2014m07) if metroFIPS == 47900 & stateFIPS == 51 & fips_place_code == 
* Alexandria March 19, 2014 (treatment effective in April. public)
replace btb_eff_city_pub = tm(2014m04) if metroFIPS == 47900 & stateFIPS == 51 & fips_place_code == 01000
* Arlington County November 3, 2014 (public Arlington)
replace btb_eff_city_pub = tm(2014m11) if metroFIPS == 47900 & stateFIPS == 51 & fips_county_code == 13
* Roanoke, VA January 2015 (public)
replace btb_eff_city_pub = tm(2015m01) if metroFIPS == 40220 & stateFIPS == 51 & fips_place_code == 68000


//Washington
* Seattle April 24, 2009 (treatment effective in May. public)
replace btb_eff_city_pub = tm(2009m05) if metroFIPS == 42660 & stateFIPS == 53 & fips_place_code == 63000
* Seattle November 1, 2013 (contract)
replace btb_eff_city_con = tm(2013m11) if metroFIPS == 42660 & stateFIPS == 53 & fips_place_code == 63000
* Seattle November 1, 2013 (private)
replace btb_eff_city_pri = tm(2013m11) if metroFIPS == 42660 & stateFIPS == 53 & fips_place_code == 63000
* Pierce County January 1, 2012 (public Tacoma)
replace btb_eff_city_pub = tm(2012m01) if metroFIPS == 42660 & stateFIPS == 53 & fips_county_code == 53
* Spokane March 6, 2015 (public)	
replace btb_eff_city_pub = tm(2015m03) if metroFIPS == 44060 & stateFIPS == 53 & fips_place_code == 67000


//Wisconsin
* Dane County February 1, 2014 (public Madison)
replace btb_eff_city_pub = tm(2014m02) if metroFIPS == 31540 & stateFIPS == 55 & fips_county_code == 25
* Milwaukee October 7, 2011 (public)
replace btb_eff_city_pub = tm(2011m10) if metroFIPS == 33340 & stateFIPS == 55 & fips_place_code == 53000


*now make statewide btb variables
gen btb_eff_state_pub = .
gen btb_eff_state_con = .
gen btb_eff_state_pri = .
gen btb_state_pub = .
gen btb_state_con = .
gen btb_state_pri = .

*California June 25, 2010 (treatment effective in July. public)
replace btb_eff_state_pub = tm(2010m07) if stateFIPS == 06
*Colorado August 8, 2012 (public)
replace btb_eff_state_pub = tm(2012m08) if stateFIPS == 08
*Connecticut October 1, 2010 (public)
replace btb_eff_state_pub = tm(2010m10) if stateFIPS == 09
*Delaware May 8, 2014 (public)
replace btb_eff_state_pub = tm(2014m05) if stateFIPS == 10
*Hawaii January 1, 1998 (public)
replace btb_eff_state_pub = tm(1998m01) if stateFIPS == 15
*Hawaii January 1, 1998 (contract)
replace btb_eff_state_con = tm(1998m01) if stateFIPS == 15
*Hawaii January 1, 1998 (private)
replace btb_eff_state_pri = tm(1998m01) if stateFIPS == 15
*Illinois January 1, 2014 (public)
replace btb_eff_state_pub = tm(2014m01) if stateFIPS == 17
*Illinois July 19, 2014 (treatment effective in August. contract)
replace btb_eff_state_con = tm(2014m08) if stateFIPS == 17
*Illinois July 19, 2014 (treatment effective in August. private)
replace btb_eff_state_pri = tm(2014m08) if stateFIPS == 17
*Maryland October 1, 2013 (public)
replace btb_eff_state_pub = tm(2013m10) if stateFIPS == 24
*Massachusetts August 6, 2010 (public)
replace btb_eff_state_pub = tm(2010m08) if stateFIPS == 25
*Massachusetts August 6, 2010 (private)
replace btb_eff_state_pri = tm(2010m08) if stateFIPS == 25
*Minnesota January 1, 2009 (public)
replace btb_eff_state_pub = tm(2009m01) if stateFIPS == 27
*Minnesota January 1, 2009 (contract)
replace btb_eff_state_con = tm(2009m01) if stateFIPS == 27
*Minnesota May 13, 2013 (private)
replace btb_eff_state_pri = tm(2013m05) if stateFIPS == 27
*Nebraska April 16, 2014 (treatment effective in May. public)
replace btb_eff_state_pub = tm(2014m05) if stateFIPS == 31
*New Mexico March 8, 2010 (public)
replace btb_eff_state_pub = tm(2010m03) if stateFIPS == 35
*Rhode Island July 15, 2013 (public)
replace btb_eff_state_pub = tm(2013m07) if stateFIPS == 44
*Rhode Island July 15, 2013 (contract)
replace btb_eff_state_con = tm(2013m07) if stateFIPS == 44
*Rhode Island July 15, 2013 (private)
replace btb_eff_state_pri = tm(2013m07) if stateFIPS == 44


*format the effective date variables 
local types = "pub con pri"
local geo1 = "city state"
foreach type of local types {
	foreach geo of local geo1 {
		format btb_eff_`geo'_`type' %tm
	}
}


foreach type of local types {
	gen btb_met_`type' = .
}


foreach type of local types {
	*make a btb effective variable that is the first city btb law (no matter how small the city)
	bysort metroFIPS: egen btb_eff_met_`type' = min(btb_eff_city_`type')
	format btb_eff_met_`type' %tm
}


*** replace btb for a few MSAs where the first adopters were non-principal cities ***
* Compton, CA July 1, 2011 (public)
replace btb_eff_met_pub = tm(2011m07) if metroFIPS == 31080 & stateFIPS == 6

*Compton, CA July 1, 2011 (contract)
replace btb_eff_met_con = tm(2011m07) if metroFIPS == 31080 & stateFIPS == 6

* East Palo Alto January 1, 2005 (public)
replace btb_eff_met_pub = tm(2005m01) if metroFIPS == 41860 & stateFIPS == 6

* Richmond, CA July 30, 2013 (treatment effective in August. contract)
replace btb_eff_met_con = tm(2013m08) if metroFIPS == 41860 & stateFIPS == 6

* Woodstock, NY November 18, 2014 (treatment effective in December. public Kingston)
replace btb_eff_met_pub = tm(2014m12) if metroFIPS == 28740 & stateFIPS == 36


*reshape here--don't need an observation for each principal city-county-msa-state-time combo--moving the principal city to wide
sort metroFIPS stateFIPS fips_county_code time_moyr principal_city 
by metroFIPS stateFIPS fips_county_code time_moyr: gen number = _n
reshape wide principal_city pc_stateFIPS fips_place_code btb_eff_city_pub btb_eff_city_con btb_eff_city_pri, i(metroFIPS msa_name stateFIPS fips_county_code time_moyr) j(number)

*make variables to use in case we only want 1 per msa (right now it's msa-county-state-time-principal city)
sort metroFIPS stateFIPS time_moyr fips_county_code
by metroFIPS stateFIPS time_moyr: gen keep1 = _n
label variable keep1 "use if only want 1 obs for each msa-state-time unit"
sort metroFIPS time_moyr stateFIPS fips_county_code
by metroFIPS time_moyr: gen keep2 = _n
label variable keep2 "use if only want 1 obs for each msa-time"

gen btb_eff_met = .
format btb_eff_met %tm
gen btb_met = .
gen btb_state = .

*make a metro area btb effective variable that is the first effective date of all law types
replace btb_eff_met = min(btb_eff_met_pub, btb_eff_met_con, btb_eff_met_pri)
format btb_eff_met %tm

*make a state btb effective variable that is the first effective date in the MSA for a state law
bysort metroFIPS: egen btb_eff_state = min(btb_eff_state_pub)
format btb_eff_state %tm

*make binary metro area btb variables that = 1 if time is at or after the effective date
replace btb_met = 1 if time_moyr >= btb_eff_met
replace btb_met = 0 if time_moyr < btb_eff_met
replace btb_met = 0 if missing(btb_met)

*make binary state btb variables that = 1 if time is at or after the effective date
replace btb_state = 1 if time_moyr >= btb_eff_state
replace btb_state = 0 if time_moyr < btb_eff_state
replace btb_state = 0 if missing(btb_state)

*make binary btb variables for each law type that = 1 if time is at or after the effective date
foreach type of local types {
	replace btb_met_`type' = 1 if time_moyr >= btb_eff_met_`type'
	replace btb_met_`type' = 0 if time_moyr < btb_eff_met_`type'
	replace btb_met_`type' = 0 if missing(btb_met_`type')
	format btb_eff_met_`type' %tm

	replace btb_state_`type' = 1 if time_moyr >= btb_eff_state_`type'
	replace btb_state_`type' = 0 if time_moyr < btb_eff_state_`type'
	replace btb_state_`type' = 0 if missing(btb_state_`type')
}

*make a btb effective variable that is the first effective date of all geographies
gen btb_eff_moyr = min(btb_eff_met, btb_eff_state)
format btb_eff_moyr %tm

*make a binary btb variable that = 1 if time is at or after the effective date
gen BTB = max(btb_met, btb_state)

foreach type of local types {
	*make a btb effective variable for each law type that is the first effective date of all geographies
	bysort metroFIPS: egen btb_eff_state_`type'_temp = min(btb_eff_state_`type')
	drop btb_eff_state_`type'
	ren btb_eff_state_`type'_temp btb_eff_state_`type'
	format btb_eff_state_`type' %tm
	gen btb_eff_`type' = min(btb_eff_met_`type', btb_eff_state_`type')
	format btb_eff_`type' %tm
	
	*make a binary btb variable for each law type that = 1 if time is at or after the effective date
	bysort metroFIPS: egen btb_state_`type'_temp = max(btb_state_`type')
	drop btb_state_`type'
	ren btb_state_`type'_temp btb_state_`type'
	gen btb_`type' = max(btb_met_`type', btb_state_`type')
}

label variable btb_eff_moyr "BTB eff date"
label variable BTB "=1 if BTB"

label variable btb_eff_met "local BTB eff date"
label variable btb_met "=1 if local BTB"
	
label variable btb_eff_state "state BTB eff date"
label variable btb_state "=1 if state BTB"

label variable time_moyr "month and year"

* this is the comprehensive dataset that includes public, contract, and private BTB laws and effective dates for MSAs, states, and "local" parts of MSAs--we do not use but may be helpful for other researchers who want BTB dates
save "$analysis_data/btb_monthly_laws_v0.dta", replace

keep metroFIPS msa_name time_moyr BTB btb_state btb_eff_moyr btb_eff_state
duplicates drop

* this is the sparse dataset with only MSA, year, and BTB variables that we use in our analysis
save "$analysis_data/btb_monthly_laws.dta", replace

log close