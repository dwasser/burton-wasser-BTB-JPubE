*****
/*
Anne Burton and David Wasser
Build CPS Data
*/

clear all


* Start loop here
local months 01 02 03 04 05 06 07 08 09 10 11 12
local years 03 04 05 06 07 08 09 10 11 12 13 14
local counter = 0

foreach y in `years' {
	foreach m in `months' {
		*** Set up counter and load data
		local counter = `counter' + 1
		use "$RAW_DATA/cpsb20`y'`m'.dta", clear
		di hryear4*(10^2) + hrmonth
		qui gen year_month = hryear4*(10^2) + hrmonth
		qui gen t = `counter'

		*** Sample filters
		* Filter on age: 25-64
		if (year_month < 201301) {
			qui keep if (peage >= 25 & peage <= 64)
			qui rename peage age
		}
		else {
			qui keep if (prtage >= 25 & prtage <= 64)
			qui rename prtage age
		}

		* Create demographic variables
		qui gen male = (pesex == 1)
		
		qui rename gestfips stateFIPS
		qui tab gereg, gen(region)
		
		if (year_month < 200405) {
			qui gen metroFIPS = .
			qui replace metroFIPS = stateFIPS
		}
		else {
			qui gen metroFIPS = gtcbsa
			qui replace metroFIPS = stateFIPS if (gtcbsa == 0 | gtcbsa == .)
		}
		
		if (year_month < 200508) {
			qui gen whiteNH = (prdtrace == 1 & pehspnon == 2)
			qui gen blackNH = (prdtrace == 2 & pehspnon == 2)
			qui gen race_var = prdtrace
		}
		else {
			qui gen whiteNH = (ptdtrace == 1 & pehspnon == 2)
			qui gen blackNH = (ptdtrace == 2 & pehspnon == 2)
			qui gen race_var = ptdtrace
		}
		qui gen hispanic = (pehspnon == 1)
		qui label var whiteNH "White, non-Hispanic"
		qui label var blackNH "Black, non-Hispanic"
		qui label var hispanic "Hispanic"
		
		qui keep if (whiteNH == 1 | blackNH == 1 | hisp == 1)

		*** Analysis variables
		* Education
		qui gen noHS = (peeduca <= 38)
		qui gen college = (peeduca >= 41)
		qui gen noCollege = (peeduca < 41)
		qui label var noHS "No high school diploma or GED"
		qui label var college "At least an associate's degree"
		qui label var noCollege "No college degree"

		* Employment
		qui gen in_lf = (pemlr > 0 & pemlr <= 4)
		qui replace in_lf = . if (pemlr < 0)
		qui label var in_lf "In the labor force (pemlr > 0 & pemlr <= 4)"
		qui gen employed = (puwk == 1 & puwk >= 0)
		qui replace employed  = . if (puwk < 0)
		qui label var employed "Worked for pay last week (puwk == 1 & puwk >= 0)"
		qui gen employed_pemlr = (pemlr == 1 | pemlr == 2)
		qui label var employed_pemlr "Worked for pay last week (pemlr == 1 | pemlr == 2)"

		* Enrolled in school
		qui gen enrolledschool = (peschenr == 1)
		qui label var enrolledschool "Enrolled in school last week (peschenr == 1)"

		*** Save/append
		if (hrmonth == 01 & hryear4 == 2003) {
			qui save "$analysis_data/dh_analysis_table.dta", replace
		}
		else {
			qui append using "$analysis_data/dh_analysis_table.dta"
			qui save "$analysis_data/dh_analysis_table.dta", replace
		}
	}
}

sort hryear4 hrmonth


gen citizen = (prcitshp < 5)
gen retired = (puwk == 3)
rename peeduca highestEdu 

gen group = .
replace group = 1 if whiteNH == 1
replace group = 2 if blackNH == 1
replace group = 3 if hispanic == 1

save "$analysis_data/dh_analysis_table.dta", replace

***** END