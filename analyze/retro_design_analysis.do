*** Gelman and Carlin (2014) Retrospective Design Analysis ***
clear
capture log close 
log using "$analyze_log/retro_design_analysis.txt", text replace

graph set window fontface "Times New Roman"

local n_obs = 150 
set obs `n_obs'

set seed 20001
local alpha = 0.05
local reps = 10000 


* Make estimates and x-axis ranges include both largest (Hispanic Men) and smallest (White men) estimates 
local start = 2*$cps_his_correct
local end = 0.015

gen drange = `start' + (`end' - `start')*((_n-1)/(_N-1))

qui levelsof drange, local(pts)


***** Black men *****

* CPS
retrodesign `pts', se($s_cps_blk_correct) alpha(`alpha') seed(`seed') reps(`reps') df($df_cps)
matrix define Bcps = r(table)
svmat Bcps

rename Bcps1 power_cps
rename Bcps2 type_s_cps
rename Bcps3 type_m_cps
drop if (drange == .)

tempfile cps_blk
save "`cps_blk'", replace 

keep drange 
drop if (drange == .)

* ACS
retrodesign `pts', se($s_acs_blk_correct) alpha(`alpha') seed(`seed') reps(`reps') df($df_acs)
matrix define B = r(table)
svmat B

rename B1 power_acs
rename B2 type_s_acs
rename B3 type_m_acs
drop if (drange == .)

merge 1:1 drange using "`cps_blk'"

* figure 2A1: power for Black men
twoway (line power_cps drange, lpattern(solid) lcolor(black)) (line power_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) ylabel(0(0.2)1, labsize(7) angle(horizontal) nogrid) xline($cps_blk_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS"))  ytitle("") subtitle(`"Power"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(1 -0.0185 "CPS Estimate", size(7))
graph export "$out/fig2a1.pdf", replace

* figure 2A2: type-s error for Black men
twoway (line type_s_cps drange, lpattern(solid) lcolor(black)) (line type_s_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) xline($cps_blk_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ylabel(0(0.1)0.5, angle(horizontal) nogrid labsize(7)) ytitle("") subtitle(`"Type-S Error"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(0.5 -0.019 "CPS Estimate", size(7))
graph export "$out/fig2a2.pdf", replace

gen abs_tm_cps = abs(type_m_cps)
gen abs_tm_acs = abs(type_m_acs)

* figure 2A3: type-m error for Black men
twoway (line abs_tm_cps drange, lpattern(solid) lcolor(black)) (line abs_tm_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) ylabel(0(50)150, labsize(7) angle(horizontal) nogrid) xline($cps_blk_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ytitle("") subtitle(`"Type-M Error"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(150 -0.018 "CPS Estimate", size(7))
graph export "$out/fig2a3.pdf", replace


***** Hispanic men *****
keep drange
drop if (drange == .)

* CPS
retrodesign `pts', se($s_cps_his_correct) alpha(`alpha') seed(`seed') reps(`reps')  df($df_cps)
matrix define Hcps = r(table)
svmat Hcps

rename Hcps1 power_cps
rename Hcps2 type_s_cps
rename Hcps3 type_m_cps
drop if (drange == .)

tempfile cps_his
save "`cps_his'", replace 

keep drange
drop if (drange == .)

* ACS
retrodesign `pts', se($s_acs_his_correct) alpha(`alpha') seed(`seed') reps(`reps') df($df_acs)
matrix define H = r(table)
svmat H

rename H1 power_acs
rename H2 type_s_acs
rename H3 type_m_acs
drop if (drange == .)

merge 1:1 drange using "`cps_his'"

* figure 2B1: power for Hispanic men
twoway (line power_cps drange, lpattern(solid) lcolor(black)) (line power_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) ylabel(0(0.2)1, labsize(7) angle(horizontal) nogrid) xline($cps_his_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ytitle("") subtitle(`"Power"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(0.05 -0.056 "CPS Estimate", size(7))
graph export "$out/fig2b1.pdf", replace

* figure 2B2: type-s error for Hispanic men
twoway (line type_s_cps drange, lpattern(solid) lcolor(black)) (line type_s_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) xline($cps_his_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ylabel(0(0.1)0.5, angle(horizontal) nogrid labsize(7)) ytitle("") subtitle(`"Type-S Error"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(0.5 -0.056 "CPS Estimate", size(7))
graph export "$out/fig2b2.pdf", replace

gen abs_tm_cps = abs(type_m_cps)
gen abs_tm_acs = abs(type_m_acs)

* figure 2B3: type-m error for Hispanic men
twoway (line abs_tm_cps drange, lpattern(solid) lcolor(black)) (line abs_tm_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) xline($cps_his_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ylabel(0(50)150, angle(horizontal) nogrid labsize(7)) ytitle("") subtitle(`"Type-M Error"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(150 -0.057 "CPS Estimate", size(7))
graph export "$out/fig2b3.pdf", replace


***** White men *****
keep drange
drop if (drange == .)

* CPS
retrodesign `pts', se($s_cps_wht_correct) alpha(`alpha') seed(`seed') reps(`reps') df($df_cps)
matrix define Wcps = r(table)
svmat Wcps

rename Wcps1 power_cps
rename Wcps2 type_s_cps
rename Wcps3 type_m_cps
drop if (drange == .)

tempfile cps_wht
save "`cps_wht'", replace 

keep drange 
drop if (drange == .)

* ACS
retrodesign `pts', se($s_acs_wht_correct) alpha(`alpha') seed(`seed') reps(`reps') df($df_acs)
matrix define W = r(table)
svmat W

rename W1 power_acs
rename W2 type_s_acs
rename W3 type_m_acs
drop if (drange == .)

merge 1:1 drange using "`cps_wht'"

* figure 2C1: power for white men
twoway (line power_cps drange, lpattern(solid) lcolor(black)) (line power_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) ylabel(0(0.2)1, labsize(7)) xline($cps_wht_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ylabel(, angle(horizontal) nogrid) ytitle("") subtitle(`"Power"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(0.01 -0.013 "CPS Estimate", size(7))
graph export "$out/fig2c1.pdf", replace

* figure 2C2: type-s error for white men
twoway (line type_s_cps drange, lpattern(solid) lcolor(black)) (line type_s_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7)) xline($cps_wht_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ylabel(0(0.1)0.5, angle(horizontal) nogrid labsize(7)) ytitle("") subtitle(`"Type-S Error"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(0.5 -0.0135 "CPS Estimate", size(7))
graph export "$out/fig2c2.pdf", replace


gen abs_tm_cps = abs(type_m_cps)
gen abs_tm_acs = abs(type_m_acs)

* figure 2C3: type-m error for white men
twoway (line abs_tm_cps drange, lpattern(solid) lcolor(black)) (line abs_tm_acs drange, lpattern(longdash) lcolor(black)), xlabel(-0.08(0.02)0.02, labsize(7))xline($cps_wht_correct, lcolor(black)) legend(label(1 "CPS") label(2 "ACS")) ylabel(0(50)150, angle(horizontal) nogrid labsize(7)) ytitle("") subtitle(`"Type-M Error"', size(7) pos(11) margin(l=-9.5)) xtitle(`"Effect Size"', size(7)) title(`""') graphregion(fcolor(white)) legend(on size(7)) text(150 -0.0145 "CPS Estimate", size(7))
graph export "$out/fig2c3.pdf", replace


graph set window fontface default

log close 