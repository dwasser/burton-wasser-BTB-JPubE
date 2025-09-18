* Corrected CPS results in Doleac and Hansen (2020)
set more off
capture log close

log using "$analyze_log/analysis_btb_cps_correctDH.txt", text replace

********************************************************************************
*** Harmonize CBSAs and NECTAs to account for 2004 and later changes
********************************************************************************

* This file crosswalks Feb. 2003 MSA delineations to Feb. 2013 MSA delineations based off the files provided here: 
* https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/historical-delineation-files.html  
import excel "$build_data/cps_msa_xwalk.xlsx", sheet("final_xwalk") cellrange(A1:B933) firstrow clear

tempfile msa_2013_definition
save "`msa_2013_definition'", replace


*** the following dataset is made in "$analyze/analysis_btb_cps_reproduceDH.do": ***
use "$analysis_data/dh_analysis_table_reproduced.dta", clear


*** Harmonize NECTAs

* first save old ones under a different name
gen raw_metroFIPS = metroFIPS

* Bangor, ME
qui replace metroFIPS = 12620 if (metroFIPS == 70750)

* Barnstable Town, MA
qui replace metroFIPS = 12700 if (metroFIPS == 70900)

* Boston-Cambridge-Quincy, MA-NH
qui replace metroFIPS = 14460 if (metroFIPS == 71650)

* Bridgeport-Stamford-Norwalk, CT
qui replace metroFIPS = 14860 if (metroFIPS == 71950)

* Burlington-South Burlington, VT
qui replace metroFIPS = 15540 if (metroFIPS == 72400)

* Danbury, CT 
qui replace metroFIPS = 14860 if (metroFIPS == 72850)

* Hartford-West Hartford-East Hartford 
qui replace metroFIPS = 25540 if (metroFIPS == 73450)

* Leominster-Fitchburg-Gardner, MA 
qui replace metroFIPS = 49340 if (metroFIPS == 74500)

* Manchester, NH 
qui replace metroFIPS = 31700 if (metroFIPS == 74950)

* New Bedford, MA 
qui replace metroFIPS = 39300 if (metroFIPS == 75550)

* New Haven, CT 
qui replace metroFIPS = 35300 if (metroFIPS == 75700)

* Norwich-New London, CT-RI 
qui replace metroFIPS = 35980 if (metroFIPS == 76450)

* Portland-South Portland, ME 
qui replace metroFIPS = 38860 if (metroFIPS == 76750)

* Providence-New Bedford-Fall River, RI-MA 
qui replace metroFIPS = 39300 if (metroFIPS == 77200)

* Rochester-Dover, NH-ME 
qui replace metroFIPS = 14460 if (metroFIPS == 77350)

* Springfield, MA-CT 
qui replace metroFIPS = 44140 if (metroFIPS == 78100)

* Waterbury, CT 
qui replace metroFIPS = 35300 if (metroFIPS == 78700)

* Worcester, MA 
qui replace metroFIPS = 49340 if (metroFIPS == 79600)


*** Harmonize code changes for select cities 
* Appleton, WI
qui replace metroFIPS = 11540 if (metroFIPS == 00460)

* Grand Rapids, MI
qui replace metroFIPS = 24340 if (metroFIPS == 03000)

* Greenville-Spartanburg-Anderson, SC
qui replace metroFIPS = 24860 if (metroFIPS == 03160)

* Jamestown-Dunkirk-Fredonia, NY
replace metroFIPS = 27460 if (metroFIPS == 03610)

* Kalamazoo-Battle Creek, MI
qui replace metroFIPS = 28020 if (metroFIPS == 03720)

* Portsmouth-Rochester, NH-ME
qui replace metroFIPS = 14460 if (metroFIPS == 06450)

* Holland, MI 
replace metroFIPS = 26100 if (metroFIPS == 26090)

* Los Angeles 
replace metroFIPS = 31100 if (metroFIPS == 31080)

* California-Lexington Park, MD
replace metroFIPS = 30500 if (metroFIPS == 15680)

* Florence-Muscle Shoals, AL
replace metroFIPS = 22460 if (metroFIPS == 22520)

* Lafayette-West Lafayette, IN
replace metroFIPS = 29140 if (metroFIPS == 29200)

* Sarasota-Bradenton-Venice, FL
qui replace metroFIPS = 42260 if (metroFIPS == 35840)

* Santa Maria-Santa Barbara, CA
qui replace metroFIPS = 42060 if (metroFIPS == 42200)

* Honolulu, HI 
qui replace metroFIPS = 26180 if (metroFIPS == 46520)



*** Merge on harmonized MSA definitions that correspond to Feb. 2013 delineations
di _N 

merge m:1 metroFIPS using "`msa_2013_definition'"
keep if (_merge == 1 | _merge == 3)
rename _merge msaxwalk_merge

di _N

*** For rural areas, assign state FIPS code for synthetic MSA 
replace new2013_metroFIPS = stateFIPS if (new2013_metroFIPS == . & (metroFIPS == stateFIPS))

*** Use new, harmonized metroFIPS variable for here on
drop metroFIPS
rename new2013_metroFIPS metroFIPS

*** Make flags for some areas that went from Metro SAs to Micro SAs by Feb. 2013
* Holland, MI
capture drop holland_flag
gen holland_flag = (metroFIPS == 26090)
replace metroFIPS = 26 if (metroFIPS == 26090)

* Jamestown-Dunkirk-Fredonia, NY
capture drop jamestown_flag
gen jamestown_flag = (metroFIPS == 27460)
replace metroFIPS = 36 if (metroFIPS == 27460)



********************************************************************************
*** Merge on corrected BTB laws ("using" file will only code MSAs)
********************************************************************************
di _N

*** the following dataset is made in "$build/build_btb_monthly_bw.do": ***
merge m:1 time_moyr metroFIPS using "$analysis_data/btb_monthly_laws.dta"

keep if (_merge == 1 | _merge == 3)
rename _merge law_merge 

di _N

capture drop BTBpub_*
replace btb_eff_moyr = . if btb_eff_moyr > ym(2014, 12)

*** Add in treatment dates for non-MSAs covered by state laws
replace BTB = 0 if (metroFIPS == stateFIPS)

replace BTB = 1 if (metroFIPS == 06 & time >= 79) // California (July 2010)
replace BTB = 1 if (metroFIPS == 08 & time >= 104) // Colorado (August 2012)
replace BTB = 1 if (metroFIPS == 09 & time >= 82) // Connecticut (October 2010)
replace BTB = 1 if (metroFIPS == 10 & time >= 125) // Delaware (May 2014)
replace BTB = 1 if (metroFIPS == 15 & year >= 1998) // Hawaii (January 1998)
replace BTB = 1 if (metroFIPS == 17 & time >= 121) // Illinois (January 2014)
replace BTB = 1 if (metroFIPS == 24 & time >= 118) // Maryland (October 2013)
replace BTB = 1 if (metroFIPS == 25 & time >= 80) // Massachusetts (August 2010)
replace BTB = 1 if (metroFIPS == 27 & time >= 61) // Minnesota (January 2009)
replace BTB = 1 if (metroFIPS == 31 & time >= 124) // Nebraska (May 2014)
replace BTB = 1 if (metroFIPS == 35 & time >= 75) // New Mexico (March 2010)
replace BTB = 1 if (metroFIPS == 44 & time >= 115) // Rhode Island (July 2013)

replace btb_eff_moyr = ym(2010, 07) if metroFIPS == 06 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2012, 08) if metroFIPS == 08 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2010, 10) if metroFIPS == 09 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2014, 05) if metroFIPS == 10 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(1998, 01) if metroFIPS == 15 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2014, 01) if metroFIPS == 17 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2013, 10) if metroFIPS == 24 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2010, 08) if metroFIPS == 25 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2009, 01) if metroFIPS == 27 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2014, 05) if metroFIPS == 31 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2010, 03) if metroFIPS == 35 & metroFIPS == stateFIPS
replace btb_eff_moyr = ym(2013, 07) if metroFIPS == 44 & metroFIPS == stateFIPS

bys metroFIPS: egen BTBever = max(BTB)

* full-year btb law (equivalent to ACS treatment definition)
gen fullyearBTB = 0
replace fullyearBTB = 1 if year > yofd(dofm(btb_eff_moyr))
replace fullyearBTB = 1 if year == yofd(dofm(btb_eff_moyr)) & month(dofm(btb_eff_moyr)) == 1

* find first year BTB is in place (for any part of the year) to use when estimating "donut hole" treatment
gen firstBTByr = (year == yofd(dofm(btb_eff_moyr)))

*** Create new treatment variables for each race/ethnicity
gen BTBxBlackNH = BTB*blackNH
gen BTBxWhiteNH = BTB*whiteNH
gen BTBxHisp = BTB*hispanic

gen fullyearBTBxBlackNH = fullyearBTB*blackNH
gen fullyearBTBxWhiteNH = fullyearBTB*whiteNH
gen fullyearBTBxHisp = fullyearBTB*hispanic


* Save file with corrected laws
save "$analysis_data/dh_analysis_table_corrected.dta", replace



*** Graphs of CPS Cell Sizes ***
preserve
keep if time_moyr > ym(2004, 04)
keep blackNH hispanic whiteNH metroFIPS time time_moyr year

* make a categorical race variable for the tag command
gen race = 1 if blackNH == 1
replace race = 2 if hispanic == 1
replace race = 3 if whiteNH == 1

* count the number of observations in each MSA-month-race cell
bys metroFIPS time: egen cell_black = total(black == 1)
bys metroFIPS time: egen cell_hisp = total(hispanic == 1)
bys metroFIPS time: egen cell_white = total(white == 1)

* count the number of observations in each MSA-year-race cell
bys metroFIPS year: egen cell_black_year = total(black == 1)
bys metroFIPS year: egen cell_hisp_year = total(hispanic == 1)
bys metroFIPS year: egen cell_white_year = total(white == 1)

* count the number of months each MSA-race pair is sampled
egen temp1 = tag(metroFIPS time_moyr race)
bys metroFIPS race: egen n_months = total(temp1)
drop temp1

* count the number of years each MSA-race pair is sampled
egen temp2 = tag(metroFIPS year race)
bys metroFIPS race: egen n_years = total(temp2)
drop temp2

sort time_moyr metroFIPS race

* calculate the minimum, average, and maximum observations in an MSA-time-race cell for each MSA-race pair
bys metroFIPS: egen cell_black_min = min(cell_black)
bys metroFIPS: egen cell_hisp_min = min(cell_hisp)
bys metroFIPS: egen cell_white_min = min(cell_white)

bys metroFIPS: egen cell_black_year_min = min(cell_black_year)
bys metroFIPS: egen cell_hisp_year_min = min(cell_hisp_year)
bys metroFIPS: egen cell_white_year_min = min(cell_white_year)

tab cell_black_min
tab cell_hisp_min
tab cell_white_min

tab cell_black_year_min
tab cell_hisp_year_min
tab cell_white_year_min

local races "black hisp white"

* tabulate the MSAs that are sampled every month or every year with at least `i' observations in each MSA-period-race cell
forvalues i = 0(1)9 {
	foreach race of local races {
	local j = `i' + 1
	disp "at least `j' `race' men sampled every month"
	tab metroFIPS if cell_`race'_min > `i' & n_months == 128
	egen temp = tag(metroFIPS) if cell_`race'_min > `i' & n_months == 128
	egen n_MSAs_mo_`race'_min`j' = total(temp)
	drop temp
	disp "at least `j' `race' men sampled every year"
	tab metroFIPS if cell_`race'_year_min > `i' & n_years == 11
	egen temp = tag(metroFIPS) if cell_`race'_year_min > `i' & n_years == 11
	egen n_MSAs_yr_`race'_min`j' = total(temp)
	drop temp
	}
}

sort time_moyr metroFIPS race
keep n_MSAs_mo_* n_MSAs_yr_*
gen id = 1
duplicates drop

reshape long n_MSAs_mo_black_min n_MSAs_mo_hisp_min n_MSAs_mo_white_min n_MSAs_yr_black_min n_MSAs_yr_hisp_min n_MSAs_yr_white_min, i(id) j(number)
gen numberB = number-0.2
gen numberH = number+0.2

label variable n_MSAs_mo_black_min "Black Men"
label variable n_MSAs_mo_hisp_min "Hispanic Men"
label variable n_MSAs_mo_white_min "White Men"

label variable n_MSAs_yr_black_min "Black Men"
label variable n_MSAs_yr_hisp_min "Hispanic Men"
label variable n_MSAs_yr_white_min "White Men"


*** figure 1a: Black/Hispanic ***
twoway (bar n_MSAs_mo_black_min numberB, barw(0.4) fcolor("90 90 90") lcolor(black)) (bar n_MSAs_mo_hisp_min numberH, barw(0.4) fcolor(gs12) lcolor(black)), subtitle(`"Number of MSAs in CPS Sample"', size(5) pos(11) margin(l=-9.5)) xtitle(`"Minimum Number of Men in Each MSA-Month-Race Cell"', size(5)) xscale(range(1 10)) xlabel(1(1)10, labsize(5)) title(`""') graphregion(fcolor(white)) ylabel(0(5)30, angle(horizontal) labsize(5) nogrid) legend(size(5))

graph export "$out/cps_cell_sample_size_BH.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figure1a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

*** figure 1b: white ***
twoway (bar n_MSAs_mo_white_min number, barw(0.4) fcolor(gs1) lcolor(black)), ytitle("") subtitle(`"Number of MSAs in CPS Sample"', size(5) pos(11) margin(l=-9.5)) xtitle(`"Minimum Number of Men in Each MSA-Month-Race Cell"', size(5))  xscale(range(1 10)) xlabel(1(1)10, labsize(5)) title(`""') graphregion(fcolor(white)) legend(on) yscale(range(0 140)) ylabel(0(20)140, angle(horizontal) labsize(5) nogrid) legend(size(5))

graph export "$out/cps_cell_sample_size_white.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figure1b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

restore


*** Event Studies ***
* for years after the treatment date
gen BTB_lag0to1 = time_moyr>=btb_eff_moyr & time_moyr<(btb_eff_moyr + 12)
gen BTB_lag1to2 = time_moyr>=(btb_eff_moyr + 12) & time_moyr<(btb_eff_moyr + 24)
gen BTB_lag2to3 = time_moyr>=(btb_eff_moyr + 24) & time_moyr<(btb_eff_moyr + 36)
gen BTB_lag3to4 = time_moyr>=(btb_eff_moyr + 36) & time_moyr<(btb_eff_moyr + 48)
gen BTB_lag4to5 = time_moyr>=(btb_eff_moyr + 48) & time_moyr<(btb_eff_moyr + 60)
gen BTB_lag4plus = time_moyr>=(btb_eff_moyr + 48) 

* for years before the treatment date
gen BTB_lead0to1 = time_moyr<btb_eff_moyr & time_moyr>=(btb_eff_moyr - 12)
gen BTB_lead1to2 = time_moyr<(btb_eff_moyr - 12) & time_moyr>=(btb_eff_moyr - 24)
gen BTB_lead2to3 = time_moyr<(btb_eff_moyr - 24) & time_moyr>=(btb_eff_moyr - 36)
gen BTB_lead3minus = time_moyr<(btb_eff_moyr - 36)

	
gen BTB_neg1 = 0
gen BTB_lead3to4 = 0

fvset base 2 metroFIPS
fvset base 60 age


*** event studies with time trends, no binned endpoints, and correctly omitting 2 periods (t-1, t-4) ***

*** appendix figure a.2a: Black ***
eststo clear

reghdfe employed BTB_lead3to4 BTB_lead2to3 BTB_lead1to2 BTB_neg1  BTB_lag0to1 BTB_lag1to2 BTB_lag2to3 BTB_lag3to4 BTB_lag4to5 if blackNH==1, vce(cluster stateFIPS) absorb(metroFIPS##c.time age enrolledschool highestEdu time#gereg)
estimate store baseline_black
coefplot (baseline_black, keep(BTB_lead3to4 BTB_lead2to3 BTB_lead1to2) lcolor(black) mcolor(black)) ///
		(baseline_black, keep(BTB_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_black, keep(BTB_lag0to1 BTB_lag1to2 BTB_lag2to3 BTB_lag3to4 BTB_lag4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTB_lead3to4 = "t-4" BTB_lead2to3 = "t-3" BTB_lead1to2 = "t-2" BTB_neg1 = "t-1" BTB_lag0to1 = "t" BTB_lag1to2 = "t+1" BTB_lag2to3 = "t+2" BTB_lag3to4 = "t+3" BTB_lag4to5 = "t+4")

graph export "$out/event_study_cps_annual_black_corrected.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA2a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure a.2b: Hispanic ***
eststo clear

reghdfe employed BTB_lead3to4 BTB_lead2to3 BTB_lead1to2 BTB_neg1  BTB_lag0to1 BTB_lag1to2 BTB_lag2to3 BTB_lag3to4 BTB_lag4to5 if hispanic==1, vce(cluster stateFIPS) absorb(metroFIPS##c.time age enrolledschool highestEdu time#gereg)
estimate store baseline_hisp
coefplot (baseline_hisp, keep(BTB_lead3to4 BTB_lead2to3 BTB_lead1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_hisp, keep(BTB_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_hisp, keep(BTB_lag0to1 BTB_lag1to2 BTB_lag2to3 BTB_lag3to4 BTB_lag4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTB_lead3to4 = "t-4" BTB_lead2to3 = "t-3" BTB_lead1to2 = "t-2" BTB_neg1 = "t-1" BTB_lag0to1 = "t" BTB_lag1to2 = "t+1" BTB_lag2to3 = "t+2" BTB_lag3to4 = "t+3" BTB_lag4to5 = "t+4")

graph export "$out/event_study_cps_annual_hispanic_corrected.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA2b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

	
*** appendix figure A.2c: white ***
eststo clear
	
reghdfe employed BTB_lead3to4 BTB_lead2to3 BTB_lead1to2 BTB_neg1  BTB_lag0to1 BTB_lag1to2 BTB_lag2to3 BTB_lag3to4 BTB_lag4to5 if whiteNH==1, vce(cluster stateFIPS) absorb(metroFIPS##c.time age enrolledschool highestEdu time#gereg)
estimate store baseline_white
coefplot (baseline_white, keep(BTB_lead3to4 BTB_lead2to3 BTB_lead1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_white, keep(BTB_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_white, keep(BTB_lag0to1 BTB_lag1to2 BTB_lag2to3 BTB_lag3to4 BTB_lag4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTB_lead3to4 = "t-4" BTB_lead2to3 = "t-3" BTB_lead1to2 = "t-2" BTB_neg1 = "t-1" BTB_lag0to1 = "t" BTB_lag1to2 = "t+1" BTB_lag2to3 = "t+2" BTB_lag3to4 = "t+3" BTB_lag4to5 = "t+4")

graph export "$out/event_study_cps_annual_white_corrected.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA2c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace



********************************************************************************
*** Regressions ***
********************************************************************************
local demog = "age enrolledschool highestEdu group"
local demog_int = "age#group enrolledschool#group highestEdu#group"
local outcome "employed"

* table 1, column 1: reproduction of Doleac and Hansen (2020) preferred CPS specification, made in "analysis_btb_cps_reproduceDH.do"

* table 1, column 2: specification not included in Doleac and Hansen (2020): "fully interacted" controls, all sample years, no time trends
eststo m1: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black metroFIPS#hispanic metroFIPS#white)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))

* table 2, column 3: correction of Doleac and Hansen 2020 preferred CPS specification: "fully interacted" controls and linear time trends
eststo m2: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp, vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))

* Save estimates for retro_design_analysis
global cps_blk_correct = e(b)[1,2]
global cps_his_correct = e(b)[1,3]
global cps_wht_correct = e(b)[1,1]
global s_cps_blk_correct = sqrt(e(V)[2,2])
global s_cps_his_correct = sqrt(e(V)[3,3])
global s_cps_wht_correct = sqrt(e(V)[1,1])

global df_cps = e(df_r)


* table 1, column 4: MSAs only
eststo m3: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp if (metroFIPS != stateFIPS), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))

* table 1, column 5: BTB-adopting only
eststo m4: reghdfe `outcome' BTBxWhiteNH BTBxBlackNH BTBxHisp if (BTBever == 1), vce(cluster stateFIPS) absorb(time#gereg#group `demog_int' metroFIPS#black##c.time metroFIPS#hispanic##c.time metroFIPS#white##c.time)

qui summ `outcome' if (black == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (hispanic == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,3]/r(mean))
qui summ `outcome' if (white == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,1]/r(mean))



local include_models "m1 m2 m3 m4"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" time#gereg#group "Year-Region FE" age#group "Demographics" metroFIPS##c.time "MSA-Specific Trends")

esttab `include_models' using "$out/table1.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent \% Effect: Black" "hispanic_percent \% Effect: Hispanic" "white_percent \% Effect: White") sfmt(4 4 4 2 2 2) nomtitles keep(*BTBx*) order(BTBxBlackNH BTBxHisp BTBxWhiteNH) coeflabels(BTBxWhiteNH "BTB x White" BTBxBlackNH "BTB x Black" BTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)

log close