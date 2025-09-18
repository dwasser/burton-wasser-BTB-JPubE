*** Figure showing employment rates for Black men for CPS and ACS

set more off
capture log close

log using "$analyze_log/cps_acs_employmentfigure.txt", text replace

********************************************************************************
*** Start with CPS
* Confirm 5 MSAs with largest sample size in CPS for Black men

*** the following dataset is made in "$analyze/analysis_btb_cps_correctDH.do": ***
use "$analysis_data/dh_analysis_table_corrected.dta", clear
 
gen n = 1
collapse (sum) n, by(time_moyr metroFIPS group)

* Black men
preserve
keep if (group == 2)
tsset metroFIPS time_moyr
tsfill, full
replace n = 0 if n == .
replace group = 2 if group == .
drop if time_moyr < ym(2004, 05)
drop if metroFIPS < 57
collapse (mean) n, by(metroFIPS group)
sort n
list n metroFIPS if inrange(_n, _N-4, _N)

/*
1. 47900: Washington, DC
2. 35620: New York
3. 37980: Philadelphia
4. 12060: Atlanta
5. 16980: Chicago
*/
restore 


*** Calculate Black employment rate in the 5 MSAs with the largest sample of Black men in DH sample
* Monthly

*** the following dataset is made in "$analyze/analysis_btb_cps_correctDH.do": ***
use "$analysis_data/dh_analysis_table_corrected.dta", clear

preserve
drop if (metroFIPS == stateFIPS)
keep if (metroFIPS == 47900 | metroFIPS == 35620 | metroFIPS == 37980 | metroFIPS == 12060 | metroFIPS == 16980)
keep if (group == 2)

gen n = 1
replace n = . if employed == .
collapse (mean) employed (sum) n, by(time_moyr metroFIPS)
rename employed monthly_cps_employ
rename n cps_mon_n

keep time_moyr metroFIPS monthly_cps_employ cps_mon_n
tempfile cps_monthly
save "`cps_monthly'", replace

restore 

* Annual
preserve
drop if (metroFIPS == stateFIPS)
keep if (metroFIPS == 47900 | metroFIPS == 35620 | metroFIPS == 37980 | metroFIPS == 12060 | metroFIPS == 16980)
keep if (group == 2)

gen n = 1
replace n = . if employed == .
collapse (mean) employed (sum) n, by(year metroFIPS)
rename employed ann_cps_employ
rename n cps_ann_n

gen time_moyr = ym(year, 1)
format time_moyr %tm

keep time_moyr metroFIPS ann_cps_employ cps_ann_n
tempfile cps_annual
save "`cps_annual'", replace

restore 


* Switch to ACS

*** the following dataset is made in "$analyze/analysis_btb_acs_correctDH.do": ***
use "$analysis_data/dh_acs_analysistable_corrected.dta", clear
rename dh_group group

preserve
drop if (metroFIPS == stateFIPS)
keep if (metroFIPS == 47900 | metroFIPS == 35620 | metroFIPS == 37980 | metroFIPS == 12060 | metroFIPS == 16980)
keep if (group == 2)

gen n = 1
replace n = . if employed == .
collapse (mean) employed (sum) n, by(year metroFIPS)
rename employed ann_acs_employ
rename n acs_ann_n

gen time_moyr = ym(year, 1)
format time_moyr %tm

keep time_moyr metroFIPS ann_acs_employ acs_ann_n
tempfile acs_annual
save "`acs_annual'", replace

restore 

*** Put everything together
use "`cps_monthly'", clear
merge 1:1 metroFIPS time_moyr using "`cps_annual'"
rename _merge intracps_merge
merge 1:1 metroFIPS time_moyr using "`acs_annual'"
rename _merge acs_merge


* Add recession variables
gen gr = .
replace gr = 1 if (time_moyr >= 575 & time_moyr <= 593)


*** Make figures ***

* appendix figure A7.a: dc msa employment rates *
capture graph drop dc
twoway (bar gr time_moyr, color(gs13) lstyle(none)) (line monthly_cps_employ time_moyr if metroFIPS == 47900, lc(black) lpattern(longdash)) (line ann_cps_employ time_moyr if metroFIPS == 47900, lc(black) lpattern(dash_dot)) (line ann_acs_employ time_moyr if metroFIPS == 47900, lc(black) lpattern(solid)), legend(order(2 "CPS (Monthly)" 3 "CPS (Annual)" 4 "ACS (Annual)") region(lstyle(none)) cols(3) size(4)) ylabel(0.2(0.2)1.0, angle(horizontal) format(%02.1f) labsize(5)) title("") subtitle("Employment Rate", size(5) pos(11) margin(l=-9.5 b=2)) xlabel(, labsize(5)) xline(612, lcolor("black")) text(0.97 633 "BTB Implemented", size(4.75)) xtitle("") scheme(s1color) plotregion(margin(tiny)) name(dc) 

graph export "$out/cps_acs_employmentfigure_dc.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA7a.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


* appendix figure A7.b: new york city msa employment rates *
capture graph drop ny
twoway (bar gr time_moyr, color(gs13) lstyle(none)) (line monthly_cps_employ time_moyr if metroFIPS == 35620, lc(black) lpattern(longdash)) (line ann_cps_employ time_moyr if metroFIPS == 35620, lc(black) lpattern(dash_dot)) (line ann_acs_employ time_moyr if metroFIPS == 35620, lc(black) lpattern(solid)), legend(order(2 "CPS (Monthly)" 3 "CPS (Annual)" 4 "ACS (Annual)") region(lstyle(none)) cols(3) size(4)) ylabel(0.2(0.2)1.0, angle(horizontal) format(%02.1f) labsize(5)) title("") subtitle("Employment Rate", size(5) pos(11) margin(l=-9.5 b=2)) xlabel(, labsize(5)) xline(621, lcolor("black")) text(0.97 600 "BTB Implemented", size(4.75)) xtitle("") scheme(s1color) plotregion(margin(tiny)) name(ny) 

graph export "$out/cps_acs_employmentfigure_nyc.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA7b.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


* appendix figure A7.c: philadelphia msa employment rates *
capture graph drop ph
twoway (bar gr time_moyr, color(gs13) lstyle(none)) (line monthly_cps_employ time_moyr if metroFIPS == 37980, lc(black) lpattern(longdash)) (line ann_cps_employ time_moyr if metroFIPS == 37980, lc(black) lpattern(dash_dot)) (line ann_acs_employ time_moyr if metroFIPS == 37980, lc(black) lpattern(solid)), legend(order(2 "CPS (Monthly)" 3 "CPS (Annual)" 4 "ACS (Annual)") region(lstyle(none)) cols(3) size(4)) ylabel(0.2(0.2)1.0, angle(horizontal) format(%02.1f) labsize(5)) title("") subtitle("Employment Rate", size(5) pos(11) margin(l=-9.5 b=2)) xlabel(, labsize(5)) xline(618, lcolor("black")) text(0.97 639 "BTB Implemented", size(4.75)) xtitle("") scheme(s1color) plotregion(margin(tiny)) name(ph) 

graph export "$out/cps_acs_employmentfigure_phi.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA7c.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


* appendix figure A7.d: atlanta msa employment rates *
capture graph drop at
twoway (bar gr time_moyr, color(gs13) lstyle(none)) (line monthly_cps_employ time_moyr if metroFIPS == 12060, lc(black) lpattern(longdash)) (line ann_cps_employ time_moyr if metroFIPS == 12060, lc(black) lpattern(dash_dot)) (line ann_acs_employ time_moyr if metroFIPS == 12060, lc(black) lpattern(solid)), legend(order(2 "CPS (Monthly)" 3 "CPS (Annual)" 4 "ACS (Annual)") region(lstyle(none)) cols(3) size(4)) ylabel(0.2(0.2)1.0, angle(horizontal) format(%02.1f) labsize(5)) title("") subtitle("Employment Rate", size(5) pos(11) margin(l=-9.5 b=2)) xlabel(, labsize(5)) xline(636, lcolor("black")) text(0.97 615 "BTB Implemented", size(4.75)) xtitle("") scheme(s1color) plotregion(margin(tiny)) name(at) 

graph export "$out/cps_acs_employmentfigure_atl.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA7d.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


* appendix figure A7.e: chicago msa employment rates *
capture graph drop ch
twoway (bar gr time_moyr, color(gs13) lstyle(none)) (line monthly_cps_employ time_moyr if metroFIPS == 16980, lc(black) lpattern(longdash)) (line ann_cps_employ time_moyr if metroFIPS == 16980, lc(black) lpattern(dash_dot)) (line ann_acs_employ time_moyr if metroFIPS == 16980, lc(black) lpattern(solid)), legend(order(2 "CPS (Monthly)" 3 "CPS (Annual)" 4 "ACS (Annual)") region(lstyle(none)) cols(3) size(4)) ylabel(0.2(0.2)1.0, angle(horizontal) format(%02.1f) labsize(5)) title("") subtitle("Employment Rate", size(5) pos(11) margin(l=-9.5 b=2)) xlabel(, labsize(5)) xline(569, lcolor("black")) text(0.97 590 "BTB Implemented", size(4.75)) xtitle("") scheme(s1color) plotregion(margin(tiny)) name(ch)

graph export "$out/cps_acs_employmentfigure_chi.eps", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace
graph export "$out/figureA7e.pdf", fontface(Times) fontfacesans(Times) fontfaceserif(Times) fontfacemono(Times) fontfacesymbol(Times) replace


log close