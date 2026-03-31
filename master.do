**********************************************************
******* MASTER FILE - EXECUTION OF ALL DO-FILES***********
**********************************************************

clear all
set more off

* --------------------------------------------------------
* IMPORTANT: BEFORE RUNNING
* --------------------------------------------------------
* For replication, the working directory must be first set 
* to the project folder in Stata, please change username:
*
    cd "/Users/username/Desktop/QIE_PROJECT"
*
* --------------------------------------------------------

* --------------------------------------------------------
* DEFINES PROJECT ROOT
* --------------------------------------------------------
capture macro drop _global ROOT
global ROOT "`c(pwd)'"

display "-------------------------------------------------"
display "Project root set to: $ROOT"
display "-------------------------------------------------"

* ---------------------------------------------------------
* RUNS PIPELINE DO-FILES
* ---------------------------------------------------------
do "$ROOT/DO-Files/DATASET_FULL_BUILDING.do"
do "$ROOT/DO-Files/DATASET_FILTERED_BUILDING.do"
do "$ROOT/DO-Files/TRADITIONAL_GRAVITY.do"
do "$ROOT/DO-Files/TWO_STEP_COMPLETE_LOOP.do"

display "-------------------------------------------------"
display "All files have been run successfully."
display "-------------------------------------------------"
