
*THESE TABLES SHOW NUMERATOR AND DENOM COUNT NEEDED FOR PG IMPROVMENT MEASURE;

*FOR DENOMINATOR - FOR PG MEASURE;

*6,127 MEMBERS - MEMBERS COACHED -  REPRESENTED IN 1 OR MORE OF THE BEHAVIOR OUTCOMES;
proc sql;
create table anthem_results_mbrs_coached as
select *
from Anthem_results_member_list_final
where guid in (select distinct guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE)
;
quit;


*21,210 MEMBERS - MEMBERS NOT COACHED -  REPRESENTED IN 1 OR MORE OF THE BEHAVIOR OUTCOMES;
proc sql;
create table anthem_results_mbrs_no_coached as
select *
from anthem_results_member_list_final
where guid not in (select distinct guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE)
;
quit;


*******************************************************************************************;

*FOR NUMERATOR - FOR PG MEASURE;    
*USING THE MODIFIED BLOOD PRESSURE RISK DEFINTION (SYS>130 OR DIAS>85) IN DETERMINING COUNTS OF MEBMERS WHO SHOWED IMPROVEMENT;

*3,666 MEMBERS THAT SHOWED IMPROVEMENT IN AT LEAST 1 OF 12 BEHAVIOR OUTCOMES - AND WERE COACHED (HAVE 2 OR MORE CALLS IN 2019);
proc sql;
create table mbrs_improve_and_coached as
select *
from a_all_12_outcomes_up_bp_change
where guid in (select distinct guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE)
;
quit;

*10,250 MEMBERS THAT SHOWED IMPROVEMENT IN AT LEAST 1 OF 12 BEHAVIOR OUTCOMES - AND WERE NOT COACHED (DONT HAVE 2 OR MORE CALLS IN 2019);
proc sql;
create table mbrs_improve_and_not_coached as
select *
from a_all_12_outcomes_up_bp_change
where guid not in (select distinct guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE)
;
quit;


************************************************************************************************************************************;

*FOR NUMERATOR - FOR PG MEASURE;    
*USING THE ORIGINAL PPT SLIDE BLOOD PRESSURE RISK DEFINTION (SYS>139 OR DIAS>89) IN DETERMINING COUNTS OF MEBMERS WHO SHOWED IMPROVEMENT;


*3,444;
proc sql;
create table mbrs_improve_and_coached_ORIG as
select *
from A_all_12_outcomes_update
where guid in (select distinct guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE)
;
quit;

*9,983 MEMBERS THAT SHOWED IMPROVEMENT IN AT LEAST 1 OF 12 BEHAVIOR OUTCOMES - AND WERE NOT COACHED (DONT HAVE 2 OR MORE CALLS IN 2019);
proc sql;
create table mbrs_improve_not_coached_ORIG as
select *
from A_all_12_outcomes_update
where guid not in (select distinct guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE)
;
quit;
