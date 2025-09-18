* Revisiting the Unintended Consequences of Ban the Box
* Anne Burton and David Wasser
* August 2025
* This file calls all scripts
clear all 
capture log close

********************************************************************************
*** Set Directory Here
********************************************************************************
global base "your_path_here"
cd "$base"
include "config.do"


********************************************************************************
*** Build Ban the Box Laws ***
********************************************************************************
* Doleac and Hansen (2020) Coding of Laws
include "$build/dh_replication_btb_policy.do"

* Our Coding of Laws
include "$build/build_btb_annual_bw.do" 
include "$build/build_btb_monthly_bw.do"


********************************************************************************
*** Build ACS and CPS Analysis Data from Raw Data ***
********************************************************************************
include "$build/build_acs_data.do" 
include "$build/build_cps_data.do"


********************************************************************************
*** Analysis: ACS ***
********************************************************************************
include "$analyze/analysis_btb_acs_reproduceDH.do"
include "$analyze/analysis_btb_acs_correctDH.do"
include "$analyze/analysis_btb_acs_additional.do"
include "$analyze/summary_stats_acs.do"


********************************************************************************
*** Analysis: CPS ***
********************************************************************************
include "$analyze/analysis_btb_cps_reproduceDH.do"
include "$analyze/analysis_btb_cps_correctDH.do"
include "$analyze/analysis_btb_cps_additional.do"
include "$analyze/analysis_btb_cps_annual.do"


********************************************************************************
*** Analysis: ACS and CPS Comparisons ***
********************************************************************************
include "$analyze/retro_design_analysis.do"
include "$analyze/analysis_btb_cps_acs_matching.do"
include "$analyze/stat_difference.do"


********************************************************************************
*** Analysis: Other Figures ***
********************************************************************************
include "$analyze/cps_acs_employmentfigure.do"
include "$analyze/county_maps_creation.do"

*** End