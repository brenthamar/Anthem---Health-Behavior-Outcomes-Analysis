


*IMPORT THE NEW SUCCESSFUL CALL DATA FILE THAT ANGIE PRODUCED,
FOR USE IN GROUPING MEMBERS BY 2019 CALL STATUS, AND USING IN PRODUCING OUTCOME RESULTS FOR EACH GROUP;

*TABLE SHOWS THE MEMBER GUID OF THE ANTHEM MEMBERS WITH 2 OR MORE SUCCESSFUL CALLS IN 2019;

PROC IMPORT OUT= WORK.ANTHEM_SUCC_2CALLS_2019_ANGIE 
            DATAFILE= "C:\Users\brent.hamar\OneDrive - Sharecare, Inc\RA
DS_Group\Anthem Legacy Outcomes\Analysis\Angie F 20200313 Anthem Guids 2
019 SCALL - 2 or more calls.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


*ADD A NEW VARIABLE NAMED 'GUID' THAT IS FORMATTED FOR USE IN FOLLOWING QUERIES;
Data ANTHEM_SUCC_2CALLS_2019_ANGIE;
set ANTHEM_SUCC_2CALLS_2019_ANGIE;

Guid_char = CUPSMEMBERID;
Guid_num = (input(CUPSMEMBERID, 25.));

format Guid_char 25.;
run;


*8,760 DISTINCT GUID (MEMBERS) WITH A SUCCESSFUL CALL IN 2019;
proc sql;
select count(distinct Guid_char) as member_count
from ANTHEM_SUCC_2CALLS_2019_Angie
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;

*ALCOHOL;
Data Alc_working_risk3_update2;
set Alc_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on Alc_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,200 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update Alc_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=Alc_working_risk3_update2;
table succ_2_call_2019;
run;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM Alcohol Risk Change Savings Result';
select sum(Alc_Impact_Savings2) as alcohol_savings format=dollar15.2
from Alc_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM Alcohol Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(Alc_Impact_Savings2) as alcohol_savings format=dollar15.2
from Alc_working_risk3_update2
group by succ_2_call_2019
;
quit;


**************************************************************************************************************;
**************************************************************************************************************;

*PHYSICAL ACTIVITY;
Data Activity_working_risk3_update2;
set Activity_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on Activity_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,203 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update Activity_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=Activity_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM Physical Activity Risk Change Savings Result';
select sum(Activity_Impact_Savings2) as activity_savings format=dollar15.2
from Activity_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM Physical Activity Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(Activity_Impact_Savings2) as activity_savings format=dollar15.2
from Activity_working_risk3_update2
group by succ_2_call_2019
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;


*ILLNESS DAYS;
Data Illness_working_risk3_update2;
set Illness_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on Illness_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,200 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update Illness_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=Illness_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM ILLNESS DAYS Risk Change Savings Result';
select sum(ILLNESS_Impact_Savings2) as ILLNESS_savings format=dollar15.2
from Illness_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM ILLNESS DAYS Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(ILLNESS_Impact_Savings2) as ILLNESS_savings format=dollar15.2
from Illness_working_risk3_update2
group by succ_2_call_2019
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;


*MEDS_FOR_RELAXATION;

Data MEDS_working_risk3_update2;
set MEDS_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on MEDS_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,205 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update MEDS_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=MEDS_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM MEDS_FOR_RELAXATION Risk Change Savings Result';
select sum(MEDS_Impact_Savings2) as MEDS_savings format=dollar15.2
from MEDS_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM MEDS_FOR_RELAXATION Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(MEDS_Impact_Savings2) as MEDS_savings format=dollar15.2
from MEDS_working_risk3_update2
group by succ_2_call_2019
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;


*LIFE_SATISFACTION;

Data Life_working_risk3_dq_update2;
set Life_working_risk3_dq_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on Life_working_risk3_dq_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,055 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update Life_working_risk3_dq_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=Life_working_risk3_dq_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM LIFE_SATISFACTION Risk Change Savings Result';
select sum(LIFE_Impact_Savings2) as LIFE_SAT_savings format=dollar15.2
from Life_working_risk3_dq_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM LIFE_SATISFACTION Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(LIFE_Impact_Savings2) as LIFE_SAT_savings format=dollar15.2
from Life_working_risk3_dq_update2
group by succ_2_call_2019
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;

*SMOKING;

Data SMOKE_working_risk3_update2;
set SMOKE_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on SMOKE_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,159 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update SMOKE_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=SMOKE_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM SMOKING Risk Change Savings Result';
select sum(SMOKE_Impact_Savings2) as SMOKE_savings format=dollar15.2
from SMOKE_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM SMOKING Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(SMOKE_Impact_Savings2) as SMOKE_savings format=dollar15.2
from SMOKE_working_risk3_update2
group by succ_2_call_2019
;
quit;



**************************************************************************************************************;
**************************************************************************************************************;
*PERCEPTION OF HEALTH;

Data Percept_working_risk3_update2;
set Percept_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on Percept_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,211 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update Percept_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=Percept_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM PERCEPTION_HEALTH Risk Change Savings Result';
select sum(PERCEPT_Impact_Savings2) as PERCEPT_savings format=dollar15.2
from Percept_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM PERCEPTION_HEALTH Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(PERCEPT_Impact_Savings2) as PERCEPT_savings format=dollar15.2
from Percept_working_risk3_update2
group by succ_2_call_2019
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;


*BLOOD PRESSURE;  *THESE ARE RESULTS WHERE THE NEW BP RISK DEFIN WAS USED (SYS>130, DIAS>85);

Data BP_working_risk3_update2;
set BP_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on BP_working_risk3_update2(Guid);
create index Guid_num on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_num);
quit;


*5,939 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update BP_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=BP_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM BLOOD PERSSURE Risk Change Savings Result';
select sum(BP_Impact_Savings2) as BP_savings format=dollar15.2
from BP_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM BLOOD PERSSURE Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(BP_Impact_Savings2) as BP_savings format=dollar15.2
from BP_working_risk3_update2
group by succ_2_call_2019
;
quit;


**************************************************************************************************************;
**************************************************************************************************************;


*BLOOD PRESSURE;  *THESE ARE RESULTS WHERE THE ORIGINAL BP RISK DEFIN WAS USED (SYS>139, DIAS>89);

Data BP_working_risk3_ORIG_DEFIN_upd2;
set BP_working_risk3_ORIG_DEFIN_upda;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on BP_working_risk3_ORIG_DEFIN_upd2(Guid);
create index Guid_num on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_num);
quit;


*5,939 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update BP_working_risk3_ORIG_DEFIN_upd2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=BP_working_risk3_ORIG_DEFIN_upd2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM BLOOD PERSSURE Risk Change Savings Result';
select sum(BP_Impact_Savings2) as BP_savings format=dollar15.2
from BP_working_risk3_ORIG_DEFIN_upd2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM BLOOD PERSSURE Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(BP_Impact_Savings2) as BP_savings format=dollar15.2
from BP_working_risk3_ORIG_DEFIN_upd2
group by succ_2_call_2019
;
quit;


**************************************************************************************************************;
**************************************************************************************************************;


*TOTAL CHOLESTEROL;

Data TOTALCHOL_working_risk3_update2;
set TOTALCHOL_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on TOTALCHOL_working_risk3_update2(Guid);
create index Guid_num on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_num);
quit;


*5,931 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update TOTALCHOL_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=TOTALCHOL_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM TOTAL CHOLESTEROL Risk Change Savings Result';
select sum(TOTALCHOL_Impact_Savings2) as TOTAL_CHOL_savings format=dollar15.2
from TOTALCHOL_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM TOTAL CHOLESTEROL Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(TOTALCHOL_Impact_Savings2) as TOTAL_CHOL_savings format=dollar15.2
from TOTALCHOL_working_risk3_update2
group by succ_2_call_2019
;
quit;

**************************************************************************************************************;
**************************************************************************************************************;


*HDL CHOLESTEROL;

Data HDL_working_risk3_update2;
set HDL_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on HDL_working_risk3_update2(Guid);
create index Guid_num on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_num);
quit;


*5,831 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update HDL_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=HDL_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM HDL CHOLESTEROL Risk Change Savings Result';
select sum(HDL_Impact_Savings2) as HDL_savings format=dollar15.2
from HDL_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM HDL CHOLESTEROL Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(HDL_Impact_Savings2) as HDL_savings format=dollar15.2
from HDL_working_risk3_update2
group by succ_2_call_2019
;
quit;


**************************************************************************************************************;
**************************************************************************************************************;

*BMI;

Data BMI_working_risk3_update2;
set BMI_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on BMI_working_risk3_update2(Guid);
create index Guid_num on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_num);
quit;


*5,947 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update BMI_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_num from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=BMI_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM BMI Risk Change Savings Result';
select sum(BMI_Impact_Savings2) as BMI_savings format=dollar15.2
from BMI_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM BMI Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(BMI_Impact_Savings2) as BMI_savings format=dollar15.2
from BMI_working_risk3_update2
group by succ_2_call_2019
;
quit;



**************************************************************************************************************;
**************************************************************************************************************;

*STRESS;

Data STRESS_working_risk3_update2;
set STRESS_working_risk3_update;

if elig_months_2019 ge 1;

succ_2_call_2019 = 0;
run;


proc sql;
create index Guid on STRESS_working_risk3_update2(Guid);
create index Guid_char on ANTHEM_SUCC_2CALLS_2019_Angie(Guid_char);
quit;


*4,204 RECORDS WERE UPDATED, WHERE MEMBER SHOWED SUCCESS CALL IN 2019;
proc sql;
update STRESS_working_risk3_update2 a
set succ_2_call_2019 = 1
where a.Guid in (select distinct Guid_char from ANTHEM_SUCC_2CALLS_2019_ANGIE); 
quit;


proc freq data=STRESS_working_risk3_update2;
table succ_2_call_2019;
run;

*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM STRESS Risk Change Savings Result';
select sum(STRESS_Impact_Savings2) as STRESS_savings format=dollar15.2
from STRESS_working_risk3_update2
;
quit;

*MEMBERS WITH NEEDED ELIG AND ALSO HAVE SUCC CALL IN 2019;
proc sql;
title 'ANTHEM STRESS Risk Change Savings Result - Have Successful 2019 Call & Elig in 2019';
select succ_2_call_2019, count(*) as member_count, sum(STRESS_Impact_Savings2) as STRESS_savings format=dollar15.2
from STRESS_working_risk3_update2
group by succ_2_call_2019
;
quit;













