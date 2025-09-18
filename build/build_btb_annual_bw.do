clear all
set more off
capture log close

set maxvar 120000

log using "$build_log/build_btb_annual_bw.txt", text replace


* get msa codes from omb delineation file, feb. 2013: https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html
import excel "$build_data/msa_delineation_file_feb2013.xls", sheet("List 1") cellrange(A3:L1885) firstrow clear

* only keep metropolitan statistical areas (as opposed to including micropolitan statistical areas)
keep if MetropolitanMicropolitanStatis == "Metropolitan Statistical Area"

* rename the variables I want to keep
ren CBSACode metroFIPS
ren CBSATitle msa_name
ren CountyCountyEquivalent county_name
ren StateName state_name
ren FIPSStateCode stateFIPS
ren FIPSCountyCode fips_county_code

keep metroFIPS msa_name county_name state_name stateFIPS fips_county_code

* destring my fips code variables
destring metroFIPS, replace
destring stateFIPS, replace
destring fips_county_code, replace

save "$build_data/msa_2013.dta", replace

*import principal city info, from feb. 2013: https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html
import excel "$build_data/msa_principal_cities_feb2013.xls", sheet("List 2") cellrange(A3:F1252) firstrow clear

*only keep metropolitan statistical areas (as opposed to including micropolitan statistical areas)
keep if MetropolitanMicropolitanStatis == "Metropolitan Statistical Area"

ren CBSACode metroFIPS
ren CBSATitle msa_name
ren PrincipalCityName principal_city
ren FIPSStateCode stateFIPS
ren FIPSPlaceCode fips_place_code

keep metroFIPS msa_name principal_city stateFIPS fips_place_code

destring metroFIPS, replace
destring stateFIPS, replace
destring fips_place_code, replace


/*rename some principal cities that have names that won't match with central city file

Current name in principal city										metroFIPS		stateFIPS		fips_place_code
------------------------------------------------------------------------------------------------------------------------
Athens-Clarke County unified government (balance)					12020			13					03440
Augusta-Richmond County consolidated government (balance)			12260			13					04204
Indianapolis city (balance)											26900			18					36003
Louisville/Jefferson County metro government (balance)				31140			21					48006
Nashville-Davidson metropolitan government (balance)				34980			47					52006
San Buenaventura (Ventura)											37100			6					65042
El Paso de Robles (Paso Robles)										42020			6					22300
*/

*need to duplicate the observations for athens-clarke county and augusta-richmond county b/c they list each of those as a central city (so you need 2 principal cities for each msa)
expand 2 if metroFIPS == 12020 & stateFIPS == 13 & fips_place_code == 3440
expand 2 if metroFIPS == 12260 & stateFIPS == 13 & fips_place_code == 4204
bysort metroFIPS stateFIPS fips_place_code: gen temp = _n
tab temp
replace fips_place_code = . if temp == 2
drop temp

replace principal_city = "Athens" if metroFIPS == 12020 & stateFIPS == 13 & fips_place_code == 3440
replace principal_city = "Clarke County" if metroFIPS == 12020 & stateFIPS == 13 & fips_place_code == .
replace principal_city = "Augusta" if metroFIPS == 12260 & stateFIPS == 13 & fips_place_code == 4204
replace principal_city = "Richmond County" if metroFIPS == 12260 & stateFIPS == 13 & fips_place_code == .
replace principal_city = "Indianapolis" if metroFIPS == 26900 & stateFIPS == 18 & fips_place_code == 36003
replace principal_city = "Louisville/Jefferson County" if metroFIPS == 31140 & stateFIPS == 21 & fips_place_code == 48006
replace principal_city = "Nashville/Davidson County" if metroFIPS == 34980 & stateFIPS == 47 & fips_place_code == 52006
replace principal_city = "Ventura" if metroFIPS == 37100 & stateFIPS == 6 & fips_place_code == 65042
replace principal_city = "Paso Robles" if metroFIPS == 42020 & stateFIPS == 6 & fips_place_code == 22300


sort metroFIPS principal_city
by metroFIPS: gen number = _n

* reshape to merge with the other datasets
reshape wide principal_city stateFIPS fips_place_code, i(metroFIPS msa_name) j(number)

save "$build_data/msa_principal_cities_2013_acs.dta", replace

* import central city info, from feb. 2013
import excel "$build_data/msa2013_names.xlsx", sheet("Sheet1") cellrange(A1:E295) firstrow clear

ren Code metroFIPS
ren Label msa_label
forvalues i = 1(1)3 {
	ren CentralCity`i' central_city_`i'
}

save "$build_data/msa_central_cities_2013.dta", replace

* merge msa file with principal city info
use "$build_data/msa_2013.dta", clear
merge m:1 metroFIPS msa_name using "$build_data/msa_principal_cities_2013_acs.dta"

drop _merge

* merge msa file with central city info
merge m:1 metroFIPS using "$build_data/msa_central_cities_2013.dta"

* fix some unmerged from master
* there are no unmerged MSAs with more than 3 principal cities, so, make the central cities be the first 3 principal cities
replace central_city_1 = principal_city1 if _merge == 1
replace central_city_2 = principal_city2 if _merge == 1
replace central_city_3 = principal_city3 if _merge == 1

* verified by checking that the MSA name matches the central cities from this method ^^

gen flag = 1
replace flag = 0 if msa_name == msa_label
tab flag _merge
drop _merge

ren stateFIPS v1_stateFIPS

* reshape again to get correct btb law based on central city
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

save "$build_data/msa_w_cities_acs.dta", replace




* now make our BTB variables

*expand the dataset to make it a time series
expand 11
bysort metroFIPS stateFIPS fips_county_code principal_city: gen number = _n
gen year = 2003 + number
drop number

*** adapted version of BTB_treatment to work for ACS ***
* BTB effective on January 15 of that year (corresponds to our CPS treatment definition of 15th of the month, approximating the CPS reference week)

*make btb effective date variables
gen btb_eff_city = .
gen btb_eff_city_eos = . // for the map of MSAs/states with BTB by end of sample period
gen btb_eff_city_con = .
gen btb_eff_city_pri = .

gen county_special = .

//California
* Compton July 1, 2011 (public): needs to be made further down bc it's not a principal city
* Carson City March 6, 2012 (public)
replace btb_eff_city = 2013 if metroFIPS == 31080 & stateFIPS == 6 & fips_place_code == 11530
* Pasadena July 1, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 31080 & stateFIPS == 6 & fips_place_code == 56000
* Santa Clara May 1, 2012 (public)
replace btb_eff_city = 2013 if metroFIPS == 41940 & stateFIPS == 6 & fips_place_code == 69084
* East Palo Alto January 1, 2005 (public): needs to be made further down bc it's not a principal city
* San Francisco October 11, 2005 (public)
replace btb_eff_city = 2006 if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 67000
* Oakland January 1, 2007 (public)
replace btb_eff_city = 2007 if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 53000
* Alameda County March 1, 2007 (public covered by Oakland and covers Berkeley)
replace btb_eff_city = 2008 if metroFIPS == 41860 & stateFIPS == 6 & fips_county_code == 1 & fips_place_code != 53000
replace county_special = 1 if stateFIPS == 6 & fips_county_code == 1
* Berkeley October 1, 2008 (public covered by Alameda County)
*replace btb_eff_city = 2009 if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 06000
* Richmond November 22, 2011 (public): needs to be made further down bc it's not a principal city
* Richmond July 30, 2013 (contract): needs to be made further down bc it's not a principal city
* San Francisco April 4, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_con = 2015 if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 67000
* San Francisco April 4, 2014 (private): not effective during ACS sample
replace btb_eff_city_pri = 2015 if metroFIPS == 41860 & stateFIPS == 6 & fips_place_code == 67000


//Connecticut
* Bridgeport October 5, 2009 (public)
replace btb_eff_city = 2010 if metroFIPS == 14860 & stateFIPS == 9 & fips_place_code == 08000
* Hartford, CT August 9, 2009 (public)
replace btb_eff_city = 2010 if metroFIPS == 25540 & stateFIPS == 9 & fips_place_code == 37000
* Hartford, CT August 9, 2009 (contract)
replace btb_eff_city_con = 2010 if metroFIPS == 25540 & stateFIPS == 9 & fips_place_code == 37000
* New Haven, CT enacted February 17, 2009. effective date unknown, so we assume it becomes effective one month later, which would make treatment start in April (public)
replace btb_eff_city = 2010 if metroFIPS == 35300 & stateFIPS == 9 & fips_place_code == 52000
* New Haven, CT enacted February 17, 2009. effective date unknown, so we assume it becomes effective one month later, which would make treatment start in April (contract)
replace btb_eff_city_con = 2010 if metroFIPS == 35300 & stateFIPS == 9 & fips_place_code == 52000
* Norwich December 1, 2008 (public)
replace btb_eff_city = 2009 if metroFIPS == 35980 & stateFIPS == 9 & fips_place_code == 56200


//Delaware 
* Wilmington December 10, 2012 (public covers New Castle County January 2014)
replace btb_eff_city = 2013 if metroFIPS == 37980 & stateFIPS == 10 & fips_place_code == 77580
* New Castle County January 28, 2014 (public covered by Wilmington): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 37980 & stateFIPS == 10 & fips_county_code == 3 & fips_place_code != 77580
*replace county_special = 1 if stateFIPS == 10 & fips_county_code == 3


//District of Columbia
* Washington DC January 1, 2011 (public)
replace btb_eff_city = 2011 if metroFIPS == 47900 & stateFIPS == 11 & fips_place_code == 50000
* Washington, DC December 17, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_con = 2015 if metroFIPS == 47900 & stateFIPS == 11 & fips_place_code == 50000
* Washington, DC December 17, 2014 (private): not effective during ACS sample
*replace btb_eff_city_pri = 2015 if metroFIPS == 47900 & stateFIPS == 11 & fips_place_code == 50000


//Florida 
* Jacksonville November 10, 2008 (public)
replace btb_eff_city = 2009 if metroFIPS == 27260 & stateFIPS == 12 & fips_place_code == 35000
* Jacksonville, FL November 10, 2008 (contract)
replace btb_eff_city_con = 2009 if metroFIPS == 27260 & stateFIPS == 12 & fips_place_code == 35000
* Pompano Beach December 1, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 33100 & stateFIPS == 12 & fips_place_code == 58050
* Tampa January 14, 2013 (public)
replace btb_eff_city = 2013 if metroFIPS == 45300 & stateFIPS == 12 & fips_place_code == 71000


//Georgia 
* Atlanta January 1, 2013 (public)
replace btb_eff_city = 2013 if metroFIPS == 12060 & stateFIPS == 13 & fips_place_code == 04000
* Fulton County July 16, 2014 (public covered by Atlanta): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 12060 & stateFIPS == 13 & fips_county_code == 121 & fips_place_code != 04000
*replace county_special = 1 if stateFIPS == 13 & fips_county_code == 121


//Illinois 
* Chicago June 6, 2007 (public)
replace btb_eff_city = 2008 if metroFIPS == 16980 & stateFIPS == 17 & fips_place_code == 14000
* Chicago November 5, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_con = 2015 if metroFIPS == 16980 & stateFIPS == 17 & fips_place_code == 14000
* Chicago November 5, 2014 (private): not effective during ACS sample
*replace btb_eff_city_pri = 2015 if metroFIPS == 16980 & stateFIPS == 17 & fips_place_code == 14000


//Indiana 
* Indianapolis, IN June 5, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 26900 & stateFIPS == 18 & fips_place_code == 36003
* Indianapolis, IN June 5, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_con = 2015 if metroFIPS == 26900 & stateFIPS == 18 & fips_place_code == 36003


//Kentucky 
* Louisville, KY March 25, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 31140 & stateFIPS == 21 & fips_place_code == 48006
* Louisville, KY March 25, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_con = 2015 if metroFIPS == 31140 & stateFIPS == 21 & fips_place_code == 48006


//Kansas 
* Kansas City November 6, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 28140 & stateFIPS == 20 & fips_place_code == 36000
* Wyandotte County November 6, 2014 (public covered by Kansas City): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 28140 & stateFIPS == 20 & fips_county_code == 209 & fips_place_code != 36000
*replace county_special = 1 if stateFIPS == 20 & fips_county_code == 209


//Louisiana 
* New Orleans January 10, 2014 (public)
replace btb_eff_city = 2014 if metroFIPS == 35380 & stateFIPS == 22 & fips_place_code == 55000


//Maryland 
* Baltimore December 1, 2007 (public)
replace btb_eff_city = 2008 if metroFIPS == 12580 & stateFIPS == 24 & fips_place_code == 04000
* Baltimore, MD August 13, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_con = 2015 if metroFIPS == 12580 & stateFIPS == 24 & fips_place_code == 04000
* Baltimore, MD August 13, 2014 (private): not effective during ACS sample
*replace btb_eff_city_pri = 2015 if metroFIPS == 12580 & stateFIPS == 24 & fips_place_code == 04000
* Prince George's County December 4, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 33
* Prince George's County, MD January 20, 2015 (contract): not effective during ACS sample
*replace btb_eff_city_w_dec_con = 2015 if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 33
* Prince George's County, MD January 20, 2015 (private): not effective during ACS sample
*replace btb_eff_city_w_dec_pri = 2015 if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 33
* Montgomery County January 1, 2015 (public Bethesda, Gaithersburg, Rockville, Silver Spring): not effective during ACS sample
*replace btb_eff_city = 2015 if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 31
* Montgomery County, MD January 1, 2015 (contract): not effective during ACS sample
*replace btb_eff_city_w_dec_con = 2015 if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 31
* Montgomery County, MD January 1, 2015 (private): not effective during ACS sample
*replace btb_eff_city_w_dec_pri = 2015 if metroFIPS == 47900 & stateFIPS == 24 & fips_county_code == 31


//Massachusetts 
* Boston July 1, 2006 (public)
replace btb_eff_city = 2007 if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 07000
* Boston July 1, 2006 (contract)  
replace btb_eff_city_con = 2007 if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 07000
* Cambridge May 1, 2007 (public)
replace btb_eff_city = 2008 if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 11000
* Cambridge January 28, 2008 (contract)
replace btb_eff_city_con = 2009 if metroFIPS == 14460 & stateFIPS == 25 & fips_place_code == 11000
* Worcester September 1, 2009 (public)
replace btb_eff_city = 2010 if metroFIPS == 49340 & stateFIPS == 25 & fips_place_code == 82000
* Worcester, MA September 1, 2009 (contract)
replace btb_eff_city_con = 2010 if metroFIPS == 49340 & stateFIPS == 25 & fips_place_code == 82000


//Michigan 
* Ann Arbor May 5, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 11460 & stateFIPS == 26 & fips_place_code == 03000
* Detroit September 13, 2010 (public)
replace btb_eff_city = 2011 if metroFIPS == 19820 & stateFIPS == 26 & fips_place_code == 22000
* Detroit, MI February 1, 2012 (contract)
replace btb_eff_city_con = 2013 if metroFIPS == 19820 & stateFIPS == 26 & fips_place_code == 22000
* East Lansing April 15, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 29620 & stateFIPS == 26 & fips_place_code == 24120
* Genesee County June 1, 2014 (public Flint): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 22420 & stateFIPS == 26 & fips_county_code == 49
*replace county_special = 1 if stateFIPS == 26 & fips_county_code == 49
* Kalamazoo January 1, 2010 (public)
replace btb_eff_city = 2010 if metroFIPS == 28020 & stateFIPS == 26 & fips_place_code == 42160
* Muskegon January 12, 2012 (public)
replace btb_eff_city = 2012 if metroFIPS == 34740 & stateFIPS == 26 & fips_place_code == 56320


//Minnesota
* Minneapolis December 1, 2006 (public)
replace btb_eff_city = 2007 if metroFIPS == 33460 & stateFIPS == 27 & fips_place_code == 43000
* St. Paul December 5, 2006 (public)
replace btb_eff_city = 2007 if metroFIPS == 33460 & stateFIPS == 27 & fips_place_code == 58000


//Missouri
* Columbia December 1, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 17860 & stateFIPS == 29 & fips_place_code == 15670
* Columbia December 1, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_w_dec_con = 2014 if metroFIPS == 17860 & stateFIPS == 29 & fips_place_code == 15670
* Columbia December 1, 2014 (private): not effective during ACS sample
*replace btb_eff_city_w_dec_pri = 2014 if metroFIPS == 17860 & stateFIPS == 29 & fips_place_code == 15670
* Kansas City April 4, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 28140 & stateFIPS == 29 & fips_place_code == 38000
* St. Louis October 1, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 41180 & stateFIPS == 29 & fips_place_code == 65000


//New Jersey
* Atlantic City December 23, 2011 (public)
replace btb_eff_city = 2012 if metroFIPS == 12100 & stateFIPS == 34 & fips_place_code == 02080
* Atlantic City December 23, 2011 (contract)
replace btb_eff_city_con = 2012 if metroFIPS == 12100 & stateFIPS == 34 & fips_place_code == 02080
* Newark, NJ November 18, 2012 (public)
replace btb_eff_city = 2013 if metroFIPS == 35620 & stateFIPS == 34 & fips_place_code == 51000
* Newark, NJ November 18, 2012 (contract)
replace btb_eff_city_con = 2013 if metroFIPS == 35620 & stateFIPS == 34 & fips_place_code == 51000
* Newark, NJ November 18, 2012 (private)
replace btb_eff_city_con = 2013 if metroFIPS == 35620 & stateFIPS == 34 & fips_place_code == 51000


//New York
* New York City October 3, 2011 (public covers Yonkers November 2014)
replace btb_eff_city = 2012 if metroFIPS == 35620 & stateFIPS == 36 & fips_place_code == 51000
* Yonkers November 1, 2014 (public): not effective during ACS sample
* New York City October 3, 2011 (contract)
replace btb_eff_city_con = 2012 if metroFIPS == 35620 & stateFIPS == 36 & fips_place_code == 51000
* Buffalo June 11, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 15380 & stateFIPS == 36 & fips_place_code == 11000
* Buffalo June 11, 2013 (contract)
replace btb_eff_city_con = 2014 if metroFIPS == 15380 & stateFIPS == 36 & fips_place_code == 11000
* Buffalo June 11, 2013 (private)
replace btb_eff_city_pri = 2014 if metroFIPS == 15380 & stateFIPS == 36 & fips_place_code == 11000
* Rochester May 20, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 40380 & stateFIPS == 36 & fips_place_code == 63000
* Rochester May 20, 2014 (contract): not effective during ACS sample
*replace btb_eff_city_w_dec_con = 2014 if metroFIPS == 40380 & stateFIPS == 36 & fips_place_code == 63000
* Rochester May 20, 2014 (private): not effective during ACS sample
*replace btb_eff_city_w_dec_pri = 2014 if metroFIPS == 40380 & stateFIPS == 36 & fips_place_code == 63000
* Woodstock November 18, 2014 (public Kingston): would need to be made further down bc it's not a principal city but not eff during ACS sample


//North Carolina
* Durham February 1, 2011 (public) 
replace btb_eff_city = 2012 if metroFIPS == 20500 & stateFIPS == 37 & fips_place_code == 19000
* Carrboro October 16, 2012 (public covered by Durham County)
*replace btb_eff_city = 2013 if metroFIPS == 20500 & stateFIPS == 37 & fips_place_code == 
* Durham County October 1, 2012 (public covered by Durham)
replace btb_eff_city = 2013 if metroFIPS == 20500 & stateFIPS == 37 & fips_county_code == 63 & fips_place_code != 19000
replace county_special = 1 if stateFIPS == 37 & fips_county_code == 63
* Charlotte February 28, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 16740 & stateFIPS == 37 & fips_place_code == 12000
* Cumberland County September 6, 2011 (public Fayetteville covers Spring Lake)
replace btb_eff_city = 2012 if metroFIPS == 22180 & stateFIPS == 37 & fips_county_code == 51
replace county_special = 1 if stateFIPS == 37 & fips_county_code == 51
* Spring Lake June 25, 2012 (public covered by Cumberland County)
*replace btb_eff_city = 2013 if metroFIPS == 22180 & stateFIPS == 37 & fips_place_code == 


//Ohio 
* Cincinnati August 1, 2010 (public)
replace btb_eff_city = 2011 if metroFIPS == 17140 & stateFIPS == 39 & fips_place_code == 15000
* Hamilton County March 1, 2012 (public covered by Cincinnati)
replace btb_eff_city = 2013 if metroFIPS == 17140 & stateFIPS == 39 & fips_county_code == 61 & fips_place_code != 15000
replace county_special = 1 if stateFIPS == 39 & fips_county_code == 61
* Cleveland September 26, 2011 (public)
replace btb_eff_city = 2012 if metroFIPS == 17460 & stateFIPS == 39 & fips_place_code == 16000
* Cuyahoga County September 30, 2012 (public covered by Cleveland)
replace btb_eff_city = 2013 if metroFIPS == 17460 & stateFIPS == 39 & fips_county_code == 35 & fips_place_code != 16000
replace county_special = 1 if stateFIPS == 39 & fips_county_code == 35
* Stark County May 1, 2013 (public Canton, Massillon, Alliance)
replace btb_eff_city = 2014 if metroFIPS == 15940 & stateFIPS == 39 & fips_county_code == 151
replace county_special = 1 if stateFIPS == 39 & fips_county_code == 151
* Canton May 15, 2013 (public covered by Stark County)
*replace btb_eff_city = 2014 if metroFIPS == 15940 & stateFIPS == 39 & fips_place_code == 12000
* Massillon January 3, 2014 (public covered by Stark County)
replace btb_eff_city = 2014 if metroFIPS == 15940 & stateFIPS == 39 & fips_place_code == 48244
* Alliance December 1, 2014 (public): not effective during ACS sample, not a principal city, and preceded by another law in MSA
*replace btb_eff_city_eos = 2014 if metroFIPS == 15940 & stateFIPS == 39 & fips_place_code == 
* Franklin County June 19, 2012 (public Columbus)
replace btb_eff_city = 2013 if metroFIPS == 18140 & stateFIPS == 39 & fips_county_code == 49
replace county_special = 1 if stateFIPS == 39 & fips_county_code == 49
* Lucas County October 29, 2013 (public Toledo)
replace btb_eff_city = 2014 if metroFIPS == 45780 & stateFIPS == 39 & fips_county_code == 95
replace county_special = 1 if stateFIPS == 39 & fips_county_code == 95
* Summit County September 1, 2012 (public covers Akron)
replace btb_eff_city = 2013 if metroFIPS == 10420 & stateFIPS == 39 & fips_county_code == 153
replace county_special = 1 if stateFIPS == 39 & fips_county_code == 153
* Akron October 29, 2013 (public covered by Summit County)
*replace btb_eff_city = 2014 if metroFIPS == 10420 & stateFIPS == 39 & fips_place_code == 01000
* Youngstown March 19, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 49660 & stateFIPS == 39 & fips_place_code == 88000


//Oregon
* Multnomah County October 10, 2007 (public Portland)
replace btb_eff_city = 2008 if metroFIPS == 38900 & stateFIPS == 41 & fips_county_code == 51
replace county_special = 1 if stateFIPS == 41 & fips_county_code == 51
* Portland July 9, 2014 (public covered by Multnomah County): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 38900 & stateFIPS == 41 & fips_place_code == 59000



//Pennsylvania
* Lancaster October 1, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 29540 & stateFIPS == 42 & fips_place_code == 41216
* Philadelphia June 29, 2011 (public)
replace btb_eff_city = 2012 if metroFIPS == 37980 & stateFIPS == 42 & fips_place_code == 60000
* Philadelphia June 29, 2011 (contract)
replace btb_eff_city_con = 2012 if metroFIPS == 37980 & stateFIPS == 42 & fips_place_code == 60000
* Philadelphia June 29, 2011 (private)
replace btb_eff_city_pri = 2012 if metroFIPS == 37980 & stateFIPS == 42 & fips_place_code == 60000
* Pittsburgh, PA December 31, 2012 (public covers Allegheny County November 2014)
replace btb_eff_city = 2013 if metroFIPS == 38300 & stateFIPS == 42 & fips_place_code == 61000
* Pittsburgh, PA December 31, 2012 (contract)
replace btb_eff_city_con = 2013 if metroFIPS == 38300 & stateFIPS == 42 & fips_place_code == 61000
* Allegheny County November 24, 2014 (public covered by Pittsburgh): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 38300 & stateFIPS == 42 & fips_county_code == 3 & fips_place_code != 61000
*replace county_special = 1 if stateFIPS == 42 & fips_county_code == 3


//Rhode Island
* Providence April 1, 2009 (public)
replace btb_eff_city = 2010 if metroFIPS == 39300 & stateFIPS == 44 & fips_place_code == 59000


//Tennessee
* Memphis July 9, 2010 (public)
replace btb_eff_city = 2011 if metroFIPS == 32820 & stateFIPS == 47 & fips_place_code == 48000
* Hamilton County January 1, 2012 (public Chattanooga)
replace btb_eff_city = 2012 if metroFIPS == 16860 & stateFIPS == 47 & fips_county_code == 65
replace county_special = 1 if stateFIPS == 47 & fips_county_code == 65


//Texas 
* Travis County April 15, 2008 (public covers Austin October 2008)
replace btb_eff_city = 2009 if metroFIPS == 12420 & stateFIPS == 48 & fips_county_code == 453
replace county_special = 1 if stateFIPS == 48 & fips_county_code == 453
* Austin October 16, 2008 (public covered by Travis County)
*replace btb_eff_city = 2009 if metroFIPS == 12420 & stateFIPS == 48 & fips_place_code == 05000


//Virginia
* Newport News October 1, 2012 (public)
replace btb_eff_city = 2013 if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 56000
* Virginia Beach November 1, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 82000
* Portsmouth April 1, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 64000
* Norfolk July 23, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 47260 & stateFIPS == 51 & fips_place_code == 57000
* Richmond March 25, 2013 (public)
replace btb_eff_city = 2014 if metroFIPS == 40060 & stateFIPS == 51 & fips_place_code == 67000
* Petersburg September 3, 2013 (public): would need to be made further down bc it's not a principal city but it's preceded by another law in msa
* Charlottesville March 1, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 16820 & stateFIPS == 51 & fips_place_code == 14968
* Danville, VA July 1, 2014 (public): Danville is a micropolitan statistical area and not effective during ACS sample
*replace btb_eff_city = 2015 if metroFIPS == 19260 & stateFIPS == 51 & fips_place_code == 21344
* Fredericksburg, VA enacted June 5, 2014. effective date unknown so assume it's one month later (public): would need to be made further down bc it's not a principal city but it's preceded by another law in msa
* Roanoke, VA January 2015 (public): not effective during ACS sample
*replace btb_eff_city = 2015 if metroFIPS == 40220 & stateFIPS == 51 & fips_place_code == 68000
* Alexandria March 19, 2014 (public): not effective during ACS sample
replace btb_eff_city_eos = 2014 if metroFIPS == 47900 & stateFIPS == 51 & fips_place_code == 01000
* Arlington County November 3, 2014 (public Arlington): not effective during ACS sample
replace btb_eff_city_eos = 2014 if metroFIPS == 47900 & stateFIPS == 51 & fips_county_code == 13
*replace county_special = 1 if stateFIPS == 51 & fips_county_code == 13


//Washington
* Seattle April 24, 2009 (public)
replace btb_eff_city = 2010 if metroFIPS == 42660 & stateFIPS == 53 & fips_place_code == 63000
* Seattle, WA November 1, 2013 (contract)
replace btb_eff_city_con = 2014 if metroFIPS == 42660 & stateFIPS == 53 & fips_place_code == 63000
* Seattle, WA November 1, 2013 (private)
replace btb_eff_city_pri = 2014 if metroFIPS == 42660 & stateFIPS == 53 & fips_place_code == 63000
* Pierce County January 1, 2012 (public Tacoma)
replace btb_eff_city = 2012 if metroFIPS == 42660 & stateFIPS == 53 & fips_county_code == 53
replace county_special = 1 if stateFIPS == 53 & fips_county_code == 53
* Spokane, WA March 6, 2015 (public): not effective during sample
*replace btb_eff_city = 2016 if metroFIPS == 44060 & stateFIPS == 53 & fips_place_code == 67000


//Wisconsin
* Dane County February 1, 2014 (public Madison): not effective during ACS sample but needed for map
replace btb_eff_city_eos = 2014 if metroFIPS == 31540 & stateFIPS == 55 & fips_county_code == 25
*replace county_special = 1 if stateFIPS == 55 & fips_county_code == 25
* Milwaukee October 7, 2011 (public)
replace btb_eff_city = 2012 if metroFIPS == 33340 & stateFIPS == 55 & fips_place_code == 53000

gen btb_eff_city_pub = btb_eff_city


*** now make statewide btb variables ***

*make btb effective date and btb treated variables
gen btb_eff_state_pub = .
gen btb_eff_state_eos = . // for map
gen btb_eff_state_con = .
gen btb_eff_state_pri = .


*California June 25, 2010 (public)
replace btb_eff_state_pub = 2011 if stateFIPS == 06
*Colorado August 8, 2012 (public)
replace btb_eff_state_pub = 2013 if stateFIPS == 08
*Connecticut October 1, 2010 (public)
replace btb_eff_state_pub = 2011 if stateFIPS == 09
*Delaware May 8, 2014 (public): not effective during ACS sample but needed for map
replace btb_eff_state_eos = 2014 if stateFIPS == 10
*Hawaii January 1, 1998 (public)
replace btb_eff_state_pub = 1998 if stateFIPS == 15
*Hawaii January 1, 1998 (contract)
replace btb_eff_state_con = 1998 if stateFIPS == 15
*Hawaii January 1, 1998 (private)
replace btb_eff_state_pri = 1998 if stateFIPS == 15
*Illinois January 1, 2014 (public)
replace btb_eff_state_pub = 2014 if stateFIPS == 17
*Illinois July 19, 2014 (contract): not effective during ACS sample
*replace btb_eff_state_con = 2015 if stateFIPS == 17
*Illinois July 19, 2014 (private): not effective during ACS sample
*replace btb_eff_state_pri = 2015 if stateFIPS == 17
*Maryland October 1, 2013 (public)
replace btb_eff_state_pub = 2014 if stateFIPS == 24
*Massachusetts August 6, 2010 (public)
replace btb_eff_state_pub = 2011 if stateFIPS == 25
*Massachusetts August 6, 2010 (contract)
replace btb_eff_state_con = 2011 if stateFIPS == 25
*Massachusetts August 6, 2010 (private)
replace btb_eff_state_pri = 2011 if stateFIPS == 25
*Minnesota January 1, 2009 (public)
replace btb_eff_state_pub = 2009 if stateFIPS == 27
*Minnesota January 1, 2009 (contract)
replace btb_eff_state_con = 2009 if stateFIPS == 27
*Minnesota May 13, 2013 (private)
replace btb_eff_state_pri = 2014 if stateFIPS == 27
*Nebraska April 16, 2014 (public): not effective during ACS sample
replace btb_eff_state_eos = 2014 if stateFIPS == 31
*New Mexico March 8, 2010 (public)
replace btb_eff_state_pub = 2011 if stateFIPS == 35
*Rhode Island July 15, 2013 (public)
replace btb_eff_state_pub = 2014 if stateFIPS == 44
*Rhode Island July 15, 2013 (contract)
replace btb_eff_state_con = 2014 if stateFIPS == 44
*Rhode Island July 15, 2013 (private)
replace btb_eff_state_pri = 2014 if stateFIPS == 44

replace btb_eff_city_eos = btb_eff_city if btb_eff_city_eos == .
replace btb_eff_state_eos = btb_eff_state_pub if btb_eff_state_eos == .

*make a btb effective variable that is the first city btb law in the MSA (no matter how small the city)
bysort metroFIPS: egen btb_eff_met = min(btb_eff_city)
bysort metroFIPS: egen btb_eff_met_eos = min(btb_eff_city_eos)
bysort metroFIPS: egen btb_eff_met_con = min(btb_eff_city_con)
bysort metroFIPS: egen btb_eff_met_pri = min(btb_eff_city_pri)

*make a state btb effective variable that is the first effective date in the MSA for a state law
bysort metroFIPS: egen btb_eff_state = min(btb_eff_state_pub)
format btb_eff_state %tm

*replace btb for a few MSAs where the first adopters were non-principal cities

* Compton, CA July 1, 2011 (public)
replace btb_eff_met = 2012 if metroFIPS == 31080
* Compton, CA July 1, 2011 (contract)
replace btb_eff_met_con = 2012 if metroFIPS == 31080
* East Palo Alto January 1, 2005 (public)
replace btb_eff_met = 2005 if metroFIPS == 41860
* Richmond, CA July 30, 2013 (contract)
replace btb_eff_met_con = 2014 if metroFIPS == 41860
* Woodstock, NY November 18, 2014 (public)
replace btb_eff_met_eos = 2014 if metroFIPS == 28740

gen btb_eff_met_pub = btb_eff_met

replace btb_eff_met_eos = btb_eff_met if btb_eff_met_eos == .


*reshape here--don't need an observation for each principal city-county-msa-state-time combo--moving the principal city to wide
sort metroFIPS stateFIPS fips_county_code year principal_city 
by metroFIPS stateFIPS fips_county_code year: gen number = _n
reshape wide principal_city pc_stateFIPS fips_place_code btb_eff_city btb_eff_city_eos btb_eff_city_pub btb_eff_city_con btb_eff_city_pri, i(metroFIPS msa_name stateFIPS fips_county_code year) j(number)

*make binary metro area btb variable that = 1 if time is at or after the effective date
gen btb_met = .
replace btb_met = 1 if year >= btb_eff_met
replace btb_met = 0 if year < btb_eff_met
replace btb_met = 0 if missing(btb_met)

gen btb_met_eos = .
replace btb_met_eos = 1 if year >= btb_eff_met_eos
replace btb_met_eos = 0 if year < btb_eff_met_eos
replace btb_met_eos = 0 if missing(btb_met_eos)

*make binary state btb variable that = 1 if time is at or after the effective date
gen btb_state = .
replace btb_state = 1 if year >= btb_eff_state
replace btb_state = 0 if year < btb_eff_state
replace btb_state = 0 if missing(btb_state)

gen btb_state_eos = .
replace btb_state_eos = 1 if year >= btb_eff_state_eos
replace btb_state_eos = 0 if year < btb_eff_state_eos
replace btb_state_eos = 0 if missing(btb_state_eos)

*make binary metro area btb variable for public laws
gen btb_met_pub = .
replace btb_met_pub = 1 if year > btb_eff_met_pub
replace btb_met_pub = 0 if year < btb_eff_met_pub
replace btb_met_pub = 0 if missing(btb_eff_met_pub)

*make binary metro area btb variables for contract and private laws
gen btb_met_con = .
replace btb_met_con = 1 if year > btb_eff_met_con
replace btb_met_con = 0 if year < btb_eff_met_con
replace btb_met_con = 0 if missing(btb_eff_met_con)

gen btb_met_pri = .
replace btb_met_pri = 1 if year > btb_eff_met_pri
replace btb_met_pri = 0 if year < btb_eff_met_pri
replace btb_met_pri = 0 if missing(btb_eff_met_pri)

*make binary state btb variable for public laws
gen btb_state_pub = .
replace btb_state_pub = 1 if year > btb_eff_state_pub
replace btb_state_pub = 0 if year < btb_eff_state_pub
replace btb_state_pub = 0 if missing(btb_eff_state_pub)

*make binary state btb variables for contract and private laws
gen btb_state_con = .
replace btb_state_con = 1 if year > btb_eff_state_con
replace btb_state_con = 0 if year < btb_eff_state_con
replace btb_state_con = 0 if missing(btb_eff_state_con)

gen btb_state_pri = .
replace btb_state_pri = 1 if year > btb_eff_state_pri
replace btb_state_pri = 0 if year < btb_eff_state_pri
replace btb_state_pri = 0 if missing(btb_eff_state_pri)

*public btb variable
gen btb_eff = min(btb_eff_met, btb_eff_state)
gen BTB = max(btb_met, btb_state)

gen btb_eff_eos = min(btb_eff_met_eos, btb_eff_state_eos)
gen BTB_eos = max(btb_met_eos, btb_state_eos)

*contract and private
gen btb_eff_con = min(btb_eff_met_con, btb_eff_state_con)
gen btb_eff_pri = min(btb_eff_met_pri, btb_eff_state_pri)

*public btb variable
gen btb_pub = max(btb_met_pub, btb_state_pub)

*contract btb variable
gen btb_con = max(btb_met_con, btb_state_con)

*private btb variable
gen btb_pri = max(btb_met_pri, btb_state_pri)


label variable btb_eff "BTB eff date"
label variable BTB "=1 if BTB"

label variable btb_eff_met "local BTB eff date"
label variable btb_met "=1 if local BTB"
	
label variable btb_eff_state "state BTB eff date"
label variable btb_state "=1 if state BTB"

* this is the comprehensive dataset that includes public, contract, and private BTB laws and effective dates for MSAs, states, and "local" parts of MSAs--we do not use but may be helpful for other researchers who want BTB dates
save "$analysis_data/btb_annual_laws_v0.dta", replace

keep metroFIPS msa_name stateFIPS fips_county_code year BTB btb_eff btb_state BTB_eos btb_state_eos
duplicates drop

* this is the dataset with only MSA, county, state, year, and BTB (public) variables that we use in our map figure
save "$analysis_data/btb_annual_laws_map.dta", replace

keep metroFIPS msa_name stateFIPS year BTB btb_eff btb_state
duplicates drop

* this is the sparse dataset with only MSA, state, year, and BTB variables that we use in our analysis
save "$analysis_data/btb_annual_laws.dta", replace

log close
exit