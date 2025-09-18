log using "$base/config.txt", text replace

* config.do
* This file sets the working directory and installs packages required for running the code.


* Define paths
global build "$base/build"  		// This directory contains everything needed to build the analysis dataset
global RAW_DATA "$build/RawData"
global analysis_data "$base/build/analysis_data"
global build_data "$base/build/build_data"
global build_log "$base/build/log"
global analyze "$base/analyze"    	// This directory contains everything needed to run all analyses, after the data are built
global out  "$base/analyze/out"
global analyze_log "$base/analyze/log"
global dh_replication "$base/dh_replication" // Replication Archive for Doleac and Hansen, accessed here: https://www.journals.uchicago.edu/doi/suppl/10.1086/705880
global map "$base/map"
global adobase "$base/ado"			// All required packages will be installed locally
global logdir "$map"
global datadir "$map"
global mapdir "$map"
global finishedmap "$map"
global maptile "$adobase/ado/personal/maptile_geographies/"

set more off
set maxvar 20000


* Install packages locally
capture mkdir "$adobase"
sysdir set PERSONAL "$adobase/ado/personal"
sysdir set PLUS     "$adobase/ado/plus"
sysdir set SITE     "$adobase/ado/site"

* Required packages
capture ssc install reghdfe, replace
capture ssc install ftools, replace
capture ssc install estout, replace 
capture ssc install erepost, replace
capture ssc install spmap, replace 
capture ssc install maptile, replace
capture ssc install carryforward, replace
capture ssc install ereplace, replace
capture ssc install coefplot, replace
capture ssc install retrodesign, replace


* Store information about the system running the code
local variant = cond(c(MP),"MP",cond(c(SE),"SE",c(flavor)) )   

di "=== SYSTEM DIAGNOSTICS ==="
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `variant'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"
di "=========================="

log close