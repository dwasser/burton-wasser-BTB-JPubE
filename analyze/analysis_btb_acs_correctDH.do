* BTB: Corrected ACS results in Doleac and Hansen (2020)
* Use corrected policy assignment variable (BTB instead of dhBTB)
* Correctly specify the fully-interacted linear time trends
* Exclude individuals with an Associate Degree

set more off
capture log close

log using "$analyze_log/analysis_btb_acs_correctDH.txt", text replace

********************************************************************************
local sample "sex == 1 & age >= 25 & age <= 34 & us_citizen == 1"
local demog = "age in_school educd"
local demog_int = "age#dh_group in_school#dh_group educd#dh_group"

********************************************************************************

*** the following dataset is made in "$build/build_acs_data.do": ***
use "$analysis_data/btb_acs_analysis_table.dta", clear

*** analysis dataset ***
keep if `sample'
keep if (no_coll_deg == 1)

save "$analysis_data/dh_acs_analysistable_corrected.dta", replace


*** Graphs of ACS Cell Sizes ***
preserve
keep dh_blackNH dh_hisp dh_whiteNH dh_group metroFIPS year

* count the number of observations in each MSA-year-race cell
bys metroFIPS year: egen cell_black = total(dh_blackNH == 1)
bys metroFIPS year: egen cell_hisp = total(dh_hisp == 1)
bys metroFIPS year: egen cell_white = total(dh_whiteNH == 1)


* count the number of years each MSA-race pair is sampled
egen temp1 = tag(metroFIPS year dh_group)
bys metroFIPS dh_group: egen n_years = total(temp1)
drop temp1

sort year metroFIPS dh_group

* calculate the minimum observations in an MSA-year-race cell for each MSA-race pair
bys metroFIPS: egen cell_black_min = min(cell_black)
bys metroFIPS: egen cell_hisp_min = min(cell_hisp)
bys metroFIPS: egen cell_white_min = min(cell_white)

tab cell_black_min
tab cell_hisp_min
tab cell_white_min


local races "black hisp white"

* tabulate the MSAs that are sampled every month or every year with at least `i' observations in each MSA-period-race cell
forvalues i = 0(1)9 {
	foreach race of local races {
	local j = `i' + 1
	disp "at least `j' `race' men sampled every year"
	tab metroFIPS if cell_`race'_min > `i' & n_years == 10
	egen temp = tag(metroFIPS) if cell_`race'_min > `i' & n_years == 10
	egen n_MSAs_yr_`race'_min`j' = total(temp)
	drop temp
	}
}
sort year metroFIPS dh_group
keep n_MSAs_yr_*
gen id = 1
duplicates drop

reshape long n_MSAs_yr_black_min n_MSAs_yr_hisp_min n_MSAs_yr_white_min, i(id) j(number)
gen numberB = number-0.2
gen numberH = number+0.2

label variable n_MSAs_yr_black_min "Black Men"
label variable n_MSAs_yr_hisp_min "Hispanic Men"
label variable n_MSAs_yr_white_min "White Men"

*** figure 1c: Black/Hispanic ***
twoway (bar n_MSAs_yr_black_min numberB, barw(0.4) fcolor("90 90 90") lcolor(black)) (bar n_MSAs_yr_hisp_min numberH, barw(0.4) fcolor(gs12) lcolor(black)), subtitle(`"Number of MSAs in ACS Sample"', size(5) pos(11) margin(l=-9.5)) xtitle(`"Minimum Number of Men in Each MSA-Year-Race Cell"', size(5)) xscale(range(1 10)) xlabel(1(1)10, labsize(5)) title(`""') graphregion(fcolor(white)) ylabel(0(50)300, angle(horizontal) labsize(5) nogrid) legend(size(5))

graph export "$out/acs_cell_sample_size_BH.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figure1c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

*** figure 1d: white ***
twoway (bar n_MSAs_yr_white_min number, barw(0.4) fcolor(gs1) lcolor(black)), ytitle("") subtitle(`"Number of MSAs in ACS Sample"', size(5) pos(11) margin(l=-9.5)) xtitle(`"Minimum Number of Men in Each MSA-Year-Race Cell"', size(5)) xscale(range(1 10)) xlabel(1(1)10, labsize(5)) title(`""') graphregion(fcolor(white)) legend(on) yscale(range(0 300)) ylabel(0(50)300, angle(horizontal) labsize(5) nogrid) legend(size(5))

graph export "$out/acs_cell_sample_size_white.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figure1d.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

restore


*********************
*** Event Studies ***
*********************

* for years after the treatment date
forvalues i = 1(1)5 {
	local j = `i' - 1
	gen BTBpub_lag_`j'to`i' = (year == btb_eff_year + `j')
}

	// Is the current time at least 4 years after BTB went into effect?
	gen BTBpub_lag4plus = (year >= btb_eff_year + 4)

* for years before the treatment date
forvalues i = 1(1)4 {
	local j = `i' - 1
	gen BTBpub_lead_`j'to`i' = (year == btb_eff_year - `i')
}

	// Is the current time more than 3 years before BTB went into effect?
	gen BTBpub_lead3minus = (year <= btb_eff_year - 4)

	
gen BTBpub_neg1 = 0
replace BTBpub_lead_3to4 = 0

*** appendix figure a.3a: Black ***
eststo clear

reghdfe employed BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_lead_0to1 BTBpub_neg1 BTBpub_lag_* if dh_blackNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_black
coefplot (baseline_black, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black)) ///
		(baseline_black, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_black, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_black_corrected.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA3a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure a.3b: Hispanic ***
eststo clear

reghdfe employed BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_lead_0to1 BTBpub_neg1 BTBpub_lag_* if dh_hisp==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_hisp
coefplot (baseline_hisp, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black)) ///
		(baseline_hisp, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_hisp, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_hispanic_corrected.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA3b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure a.3c: white ***
eststo clear

reghdfe employed BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_lead_0to1 BTBpub_neg1 BTBpub_lag_* if dh_whiteNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_white
coefplot (baseline_white, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black)) ///
		(baseline_white, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_white, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_white_corrected.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA3c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace



*** public-sector employment ***

*** appendix figure a4.a: Black ***
eststo clear

reghdfe employed_public BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_neg1  BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5 if dh_blackNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_black
coefplot (baseline_black, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black)) ///
		(baseline_black, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_black, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.1(.05)0.1, angle(horizontal) labsize(5) nogrid) yscale(range(-0.1 0.1)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_black_public.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA4a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure a4.b: Hispanic ***
eststo clear

reghdfe employed_public BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_neg1  BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5 if dh_hisp==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_hisp
coefplot (baseline_hisp, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_hisp, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_hisp, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.1(.05)0.1, angle(horizontal) labsize(5) nogrid) yscale(range(-0.1 0.1)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_hispanic_public.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA4b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure a4.c: white ***

eststo clear
	
reghdfe employed_public BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_neg1  BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5 if dh_whiteNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_white
coefplot (baseline_white, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_white, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_white, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.1(.05)0.1, angle(horizontal) labsize(5) nogrid) yscale(range(-0.1 0.1)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")
	
graph export "$out/event_study_acs_annual_white_public.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA4c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace



*** drop group quarters ***
preserve

drop if (gq == 3 | gq == 4)

*** appendix figure a.5a: Black ***
eststo clear

reghdfe employed BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_neg1  BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5 if dh_blackNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_black
coefplot (baseline_black, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black)) ///
		(baseline_black, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_black, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_black_nogq.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA5a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


*** appendix figure a.5b: Hispanic ***
eststo clear

reghdfe employed BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_neg1  BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5 if dh_hisp==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_hisp
coefplot (baseline_hisp, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_hisp, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_hisp, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")

graph export "$out/event_study_acs_annual_hispanic_nogq.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA5b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace

	
*** appendix figure a.5c: white ***
eststo clear
	
reghdfe employed BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2 BTBpub_neg1  BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5 if dh_whiteNH==1 & year >= 2008, vce(cluster stateFIPS) absorb(age in_school educd dh_time#gereg metroFIPS##c.dh_time)
estimate store baseline_white
coefplot (baseline_white, keep(BTBpub_lead_3to4 BTBpub_lead_2to3 BTBpub_lead_1to2) lcolor(black) mcolor(black) offset(-0.01)) ///
		(baseline_white, keep(BTBpub_neg1) omitted lcolor(black) mcolor(black)) ///
		(baseline_white, keep(BTBpub_lag_0to1 BTBpub_lag_1to2 BTBpub_lag_2to3 BTBpub_lag_3to4 BTBpub_lag_4to5) lcolor(black) mcolor(black) offset(-0.01)) ///
	, vertical ytitle("") xtitle("Years Since BTB Implementation", size(5)) subtitle("Effect Size", size(5) pos(11) margin(l=-9.5)) title(`""') xlabel(, labsize(5)) ylabel(-0.2(.1)0.2, angle(horizontal) labsize(5) nogrid) yscale(range(-0.2 0.2)) recast(connected) label  graphregion(fcolor(white))  lwidth(*2)  legend(off) yline(0, lcolor(gs12)) xline(4, lpattern(dash)) ciopts(recast(rline) lpattern(dash) lcolor(black)) coeflabels(BTBpub_lead_3to4 = "t-4" BTBpub_lead_2to3 = "t-3" BTBpub_lead_1to2 = "t-2" BTBpub_neg1 = "t-1" BTBpub_lag_0to1 = "t" BTBpub_lag_1to2 = "t+1" BTBpub_lag_2to3 = "t+2" BTBpub_lag_3to4 = "t+3" BTBpub_lag_4to5 = "t+4")
	
graph export "$out/event_study_acs_annual_white_nogq.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA5c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


restore
	
*******************
*** Regressions ***
*******************

eststo clear

local outcome "employed"

* table 2, column 1: reproduction of Doleac and Hansen (2020) preferred ACS specification, made in "analysis_btb_acs_reproduceDH.do"

* table 2, column 2: specification not included in Doleac and Hansen (2020): "fully interacted" controls, all sample years, no time trends
eststo m1: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH, vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH metroFIPS#dh_hisp metroFIPS#dh_whiteNH)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* table 2, column 3: correction of Doleac and Hansen (2020) preferred ACS specification--"fully interacted" controls and linear time trends
eststo m2: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH, vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* table 2, column 4: MSAs only 
eststo m3: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH  if (metroFIPS != stateFIPS), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & metroFIPS != stateFIPS)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* table 2, column 5: BTB adopting-only 
eststo m4: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if (BTBever == 1), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* table 2, column 6 (corrected Doleac and Hansen, 2020 preferred specification): full sample, 2008 and later 
eststo m5: reghdfe `outcome' BTBxBlackNH BTBxHisp BTBxWhiteNH if (year >= 2008), vce(cluster stateFIPS) absorb(dh_time#gereg#dh_group `demog_int' metroFIPS#dh_blackNH##c.dh_time metroFIPS#dh_hisp##c.dh_time metroFIPS#dh_whiteNH##c.dh_time)

qui summ `outcome' if (dh_blackNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar black_mean = r(mean), replace
qui estadd scalar black_percent = 100*(e(b)[1,1]/r(mean))
qui summ `outcome' if (dh_hisp == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar hispanic_mean = r(mean), replace
qui estadd scalar hispanic_percent = 100*(e(b)[1,2]/r(mean))
qui summ `outcome' if (dh_whiteNH == 1 & BTB == 0 & BTBever == 1 & year >= 2008)
qui estadd scalar white_mean = r(mean), replace 
qui estadd scalar white_percent = 100*(e(b)[1,3]/r(mean))

* Save estimates for retro_design_analysis
global acs_blk_correct = e(b)[1,1]
global acs_his_correct = e(b)[1,2]
global acs_wht_correct = e(b)[1,3]
global s_acs_blk_correct = sqrt(e(V)[1,1])
global s_acs_his_correct = sqrt(e(V)[2,2])
global s_acs_wht_correct = sqrt(e(V)[3,3])

global df_acs = e(df_r)


local include_models "m1 m2 m3 m4 m5"

* Output regression table
estfe `include_models', labels(metroFIPS "MSA FE" dh_time#gereg "Year-Region FE" age#dh_group "Demographics" metroFIPS#c.dh_time "MSA-Specific Trends")

esttab `include_models' using "$out/table2.tex", replace compress noconstant se(4) b(4) r2(4) nogaps indicate(`r(indicate_fe)') noomitted nobase scalars("black_mean Pre-BTB Mean: Black" "hispanic_mean Pre-BTB Mean: Hispanic" "white_mean Pre-BTB Mean: White" "black_percent \% Effect: Black" "hispanic_percent \% Effect: Hispanic" "white_percent \% Effect: White") sfmt(4 4 4 2 2 2) nomtitles keep(BTBx*) coeflabels(BTBxWhiteNH "BTB x White" BTBxBlackNH "BTB x Black" BTBxHisp "BTB x Hispanic") star(* 0.10 ** 0.05 *** 0.01)


log close