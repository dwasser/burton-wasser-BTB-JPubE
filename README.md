# Replication Package for "Revisiting the Unintended Consequences of Ban the Box": Anne M. Burton and David N. Wasser, JPubE-105473

## Overview
The code in this replication package constructs all of the analysis in "Revisiting the Unintended Consequences of Ban the Box" (JPubE-105473). Everything is executed in Stata, with master.do calling all other scripts in order to generate all tables and figures. Throughout this replication package we use "BTB" to abbreviate "Ban the Box." The replicator should expect the code to run for about 10 hours.

## Data Availability and Provenance Statements
### Statement about Rights

- [X] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript. 
- [ ] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permission are documented in the [LICENSE.txt](LICENSE.txt) file.

### Summary of Availability

- [X] All data **are** publicly available.
- [ ] Some data **cannot be made** publicly available.
- [ ] **No data can be made** publicly available. 

### Details on each Data Source

| Data Name  | Data Files | Location | Provided | Citation |
| -- | -- | -- | -- | -- | 
| Current Population Survey (CPS) 2004-2014 | cbspYYYYMM.dta | /build/RawData | No | U.S. Census Bureau and U.S. Bureau of Labor Statistics (2004-2014) |
| American Community Survey (ACS) (2004-2014) | usa_00008.dta | /build/build_data | No | Ruggles, et al. (2004-2018) |
| Doleac and Hansen (2020) BTB Law Coding | BTB_data.dta, BTB_ACS.dta | /dh_replication | Yes | Doleac and Hansen (2020) |
| Burton and Wasser (2025) BTB Law Coding | btb_annual_laws.dta, btb_monthly_laws.dta | /build/analysis_data | Yes | Burton and Wasser (2025) |



### Current Population Survey (CPS) 2004-2014

The paper uses publicly available CPS basic monthly microdata covering January 2004-December 2014. Data was accessed via the National Bureau of Economic Research (NBER). https://doi.org/10.60592/d7gd-cx91

These data are not provided here. They must be downloaded at the link above and placed in /build/RawData.

### American Community Survey (ACS) (2004-2014)

The paper uses publicly available ACS microdata covering 2004-2014. Data were accessed via IPUMS (Ruggles et al., 2004-2018). Details on the specifics of the IPUMS extract are provided in ipums_acs_extract_info.pdf. https://usa.ipums.org/usa/

These data are not provided here. They must be downloaded at the link above and placed in /build/build_data.

### Doleac and Hansen (2020) BTB Law Coding 

The paper uses data shared with us by Doleac and Hansen that includes their coding of BTB laws. These same data are also posted with their replication package on the *Journal of Labor Economics* website: https://doi.org/10.1086/705880

These data are provided in /dh_replication.

### Burton and Wasser (2025) BTB Law Coding 

Our coding of BTB laws used in this study has been deposited in the [Github](https://github.com/dwasser/burton-wasser-BTB-JPubE) repository. The data were collected by the authors, and are available under a Creative Commons Non-commercial license.

These data are provided in /build/analysis_data.

### MSA Delineation Files and Crosswalks

In addition to the data used above, we also use the following MSA delineation files and crosswalks, all of which are provided in /build/build_data:

| Name  | File | Source | 
| -- | -- | -- | 
| U.S. Office of Management and Budget February 2013 MSA Delineations | msa_delineation_file_feb2013.xls | https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/historical-delineation-files.html |
| U.S. Office of Management and Budget February 2013 MSA Principal Cities | msa_principal_cities_feb2013.xls | https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/historical-delineation-files.html |
| CPS MSA Crosswalk: Harmonize Feb. 2003 Delineations with Feb. 2013 Delineations | cps_msa_xwalk.xlsx | https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/historical-delineation-files.html |


## Computational requirements
### Software Requirements

- The replication package contains one or more programs to install all dependencies and set up the necessary directory structure.

- Stata (code was last run with version 17 on 9/17/25)
  - reghdfe
  - ftools
  - estout 
  - erepost
  - spmap 
  - maptile
  - carryforward
  - ereplace
  - coefplot
  - retrodesign
  - the program `config.do` will install all dependencies locally, and should be run once.

### Controlled Randomness

- [X] Random seed is set at line 11 of /analyze/retro_design_analysis.do.
- [ ] No Pseudo random generator is used in the analysis described here.

### Memory, Runtime, Storage Requirements

#### Summary

- Approximate time needed to reproduce the analyses on a standard desktop machine: 10 hours.
  - The script /analyze/stat_difference takes 7 hours itself but can be run separately.
- Approximate storage space needed: 50 GB

#### Details

The code was last run on a 4-core Intel-based laptop with Windows 10 Pro.  


## Description of programs/code
Programs are partioned into build and analysis scripts. Those in /build assemble the analysis datasets and those in /analyze perform all analysis in the paper.

- /build
  - `dh_replication_btb_policy.do`: creates intermediate dta files containing the Doleac and Hansen (2020) coding of BTB laws using data from their replication archive as described above.
  - `build_btb_annual_bw.co`: creates intermediate dta files containing our coding of BTB laws at an annual frequency.
  - `build_btb_monthly_bw.co`: creates intermediate dta files containing our coding of BTB laws at a monthly frequency.
  - `build_acs_data.do`: builds ACS analysis table from IPUMS extract.
  - `build_cps_data.do`: builds ACS analysis table from NBER extracts.

- /analyze
  - `analysis_btb_acs_reproduceDH.do`: reproduces Doleac and Hansen (2020) ACS estimates.
  - `analysis_btb_acs_correctDH.do`: produces corrected ACS estimates.
  - `analysis_btb_acs_additional.do`: produces additional ACS estimates as described below.
  - `summary_stats_acs.do`: produces summary stats for ACS sample.
  - `analysis_btb_cps_reproduceDH.do`: reproduces Doleac and Hansen (2020) CPS estimates.
  - `analysis_btb_cps_correctDH.do`: produces corrected CPS estimates.
  - `analysis_btb_cps_additional.do`: produces additional CPS estimates as described below.
  - `analysis_btb_cps_annual.do`: produces estimated based on annualized CPS sample.
  - `retro_design_analysis.do`: produces estimates for retrospective design analysis.
  - `analysis_btb_cps_acs_matching.do`: produces estimates for MSAs sampled in same year in both CPS and ACS.
  - `stat_difference.do`: performs tests of equality of coefficients across specifications. All p-values are recorded in log file.
  - `cps_acs_employmentfigure.do`: produces Figure A7.
  - `county_maps_creation.do`: produces Figure A1 (map).

### License for Code

The code is licensed under a MIT license. See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators
- Edit `master.do` line 11 to adjust the base path
- Download the data files referenced above. 
    - Place CPS files in /build/RawData.
    - Place ACS extract in /build/build_data.
- Run `master.do` to run all steps in sequence.
- If running programs individually, note that order is important.


## List of tables and programs

The provided code reproduces:

- [ ] All numbers provided in text in the paper
- [ ] All tables and figures in the paper
- [X] Selected tables and figures in the paper, as explained and justified below.


| Figure/Table #    | Program                  | Line Number | Output file                      | Note                            |
|-----------------------|--------------------------|-------------|----------------------------------|------------------------|
| Figure 1          | analysis_btb_cps_correctDH.do | 319, 325  |figure1a.pdf, figure1b.pdf |Panel A, B|
| Figure 1          | analysis_btb_acs_correctDH.do | 85, 91  |figure1c.pdf, figure1d.pdf    |Panel C, D|
| Figure 2          | retro_design_analysis.do      | 57, 61, 68, 105, 109, 116, 153, 157, 165 | fig2a1.pdf, fig2a2.pdf, fig2a3.pdf, fig2b1.pdf, fig2b2.pdf, fig2b3.pdf, fig2c1.pdf, fig2c2.pdf, fig2c3.pdf  ||
| Table 1           | analysis_btb_cps_correctDH.do | 477            | table1.tex                 ||
| Table 2           | analysis_btb_acs_correctDH.do | 351          | table2.tex                      ||
| Table 3           | analysis_btb_cps_annual.do| 78, 281 | table3columns1245.tex, table3columns36.tex ||
| Appendix Figure 1 | county_maps_creation.do | 56     | figureA1.pdf                ||
| Appendix Figure 2 | analysis_btb_cps_correctDH.do | 366, 380, 394     | figureA2a.pdf, figureA2b.pdf, figureA2c.pdf  ||
| Appendix Figure 3 | analysis_btb_acs_correctDH.do | 133, 147, 161 | figureA3a.pdf, figureA3b.pdf, figureA3c.pdf  ||
| Appendix Figure 4 | analysis_btb_acs_correctDH.do | 178, 192, 207 | figureA4a.pdf, figureA4b.pdf, figureA4c.pdf  ||
| Appendix Figure 5 | analysis_btb_acs_correctDH.do | 227, 241, 255 | figureA5a.pdf, figureA5b.pdf, figureA5c.pdf  ||
| Appendix Figure 6 | analysis_btb_cps_acs_matching.do | 178, 192, 206 | figureA6a.pdf, figureA6b.pdf, figureA6c.pdf  ||
| Appendix Figure 7 | cps_acs_employmentfigure.do | 132, 140, 148, 156, 164 | figureA7a.pdf, figureA7b.pdf, figureA7c.pdf, figureA7d.pdf, figureA7e.pdf  ||
| Appendix Table 1  | summary_stats_acs.do      | 42            | tableA1.tex                      ||
| Appendix Table 2  | analysis_btb_cps_reproduceDH.do | 155     | tableA2.tex                      ||
| Appendix Table 3  | analysis_btb_acs_reproduceDH.do | 134     | tableA3.tex                      ||
| Appendix Table 4  | See note below |      |   burton_wasser_btb_tableA4.csv                    ||
| Appendix Table 5  | analysis_btb_cps_additional.do | 69     | tableA5.tex                      ||
| Appendix Table 6  | analysis_btb_acs_additional.do | 96     | tableA6.tex                      ||
| Appendix Table 7  | analysis_btb_cps_additional.do | 110     | tableA7columns12.tex                      |Columns 1, 2 |
| Appendix Table 7  | analysis_btb_acs_additional.do | 151     | tableA7columns345.tex                      |Columns 3, 4, 5|
| Appendix Table 8  | analysis_btb_cps_acs_matching.do | 140     | tableA8.tex                ||


- Note: Appendix Table A4 was constructed using Table 1 of Doleac and Hansen (2020), Avery and Lu (2020), local government websites, law firm websites, and news articles. We provide a csv file (burton_wasser_btb_tableA4.csv) with its contents in /build/analysis_data. 

- There are many tests of equality of coefficients across specifications. All of these are performed in /analyze/stat_difference.do and the p-values are in the log file.


## References

Avery, Beth and Han Lu (2020), “Ban the Box – Fair Chance State and Local Guide.” *National Employment
Law Project*.

Burton, Anne M. and David N. Wasser (2025), "Revisiting the Unintended Consequences of Ban the Box." *Journal of Public Economics*. Forthcoming. 

Doleac, Jennifer L. and Benjamin Hansen (2020), "The Unintended Consequences of "Ban the Box": Statistical Discrimination and Employment Outcomes When Criminal Histories Are Hidden." *Journal of Labor
Economics*, 38, 321–374. https://doi.org/10.1086/705880 

Ruggles, Steven and Sarah Flood, Matthew Sobek, Daniel Backman, Grace Cooper, Julia A. Rivera Drew, Stephanie Richards, Renae Rodgers, Jonathan Schroeder, and Kari C.W. Williams. 2004-2018. "IPUMS USA: Version 16.0 American Community Survey." Minneapolis, MN: IPUMS, 2025. https://doi.org/10.18128/D010.V16.0

U.S. Census Bureau and U.S. Bureau of Labor Statistics. (2004-2014). Current Population Survey (CPS) Basic Monthly Data. Distributed by National Bureau of Economic Research. https://doi.org/10.60592/d7gd-cx91. 

---
