
*MEDICATION FOR RELAXATION RISK MEASURE FOR ANTHEM;
*RERUN IN FEB 2020;

*RE-CATEGORIZE MEMBERS WITH 'UNKNOWN' FOR YEAR-IN-PROGRAM, TO 'YEAR 5'


*PULL MED USE RISK RECORDS FROM REALAGE AND THE WBA;

*RealAge; *11,824 RECORDS;
*RERUN - 13,585 RECORDS;

proc sql;
create table Meds_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 19988
order by guid, from_date 
;
quit;


*THIS PRODUCES COUNT, AND ALSO FORMATS DATE CORRECTLY, AND PRODUCES A 'YEAR' VARIABLE;
*WBA; *155,823 RECORDS;
proc sql;
create table Meds_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297240
;
quit;


*******************************************************************************************;

*GET DISTINCT FACT_VALUES AND RESPONSE_TEXTS FROM THE 2 DIFFERENT TABLES;
*RECODE NEEDED VARIABLE NAMES AND RESPONSES, SO THAT TABLES CAN BE MERGED TOGETHER;

proc freq data=Meds_RealAge;
table fact_value;
title 'Realage Responses for MEDS FOR RELAX';
quit;

proc freq data=Meds_WBA;
table response_text;
title 'WBA Responses for MEDS FOR RELAX';
quit;

/* RealAge: fact_values 

almostDaily 
never 
rarely 
sometimes 

WBA: Response Texts
Almost every day 
Rarely or never 
Sometimes 

*/

Data MEDS_RealAge_recode1;
set Meds_RealAge;
if fact_value = 'never' then fact_value = 'Rarely or never';
if fact_value = 'rarely ' then fact_value = 'Rarely or never';
if fact_value = 'sometimes' then fact_value = 'Sometimes';
if fact_value = 'almostDaily' then fact_value = 'Almost every day';
run;


Data MEDS_RealAge_recode2 (rename =  (fact_id=asmnt_question_id fact_value=response_text from_date=response_date2)) ;
set MEDS_RealAge_recode1;
run;

*2020 RECORDS ARE IN THIS TABLE - HAVE TO DELETE OUT;
proc freq data=MEDS_RealAge_recode2;
table year;
run;
 

*RECORDS IN THE REALAGE TABLE WITH YEAR GREATER THAN 2019 ARE DELETED;
*TABLE GOES FROM 13,585 TO 11,805;
Data MEDS_RealAge_recode3;
set MEDS_RealAge_recode2;

if year le 2019;
run;

*****************************************************************;

*MERGE REALGE AND WBA MEDICATION RELAX DATASETS;
Data MEDS_merged;
set  Meds_WBA MEDS_RealAge_recode3;
run;

proc freq data=MEDS_merged;
table response_text;
run;
*****************************************************************;



*OBTAIN FIRST AND LAST VALUES FROM THIS MERGED TABLE, 
THEN SORT BY GUID AND RESPONSE_DATE2;

proc sort data=MEDS_merged;
by guid response_date2;
run;


*MEDS First value;
*N=94,840 RECORDS;
Data MEDS_first;
set MEDS_merged;
by guid;
if first.guid;
run;

*MEDS Last value;
*N=94,840 RECORDS;
Data MEDS_last;
set MEDS_merged;
by guid;
if last.guid;
run;

*JOIN BOTH FIRST AND LAST ILLNESS RECORD FILES;
*36,872 RECORDS IN TABLE;
proc sql;
create table MEDS_first_last as
select 	a.guid, 
		'Medication for Relaxation' as item,
		a.asmnt_question_id as Question_fact_id_First,
		a.response_date2 as Date_First,
		a.Year as Year_First,
		a.response_text as Value_First,
		0 as Risk_First,
		b.asmnt_question_id as Question_fact_id_Last,
		b.response_date2 as Date_Last,
		b.Year as Year_Last,
		b.response_text as Value_Last,
		0 as Risk_Last
from MEDS_first a inner join MEDS_last b
on a.guid = b.guid
where a.response_date2 <> b.response_date2;
quit;


*DELETE RECORD IN YEAR_FIRST = YEAR_LAST;
*36,872 RECORDS TO 36,013 RECORDS;
Data MEDS_first_last;
set MEDS_first_last;

if Year_First = Year_Last then delete;
run;

*****************************************************************;

*BRING DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

Data MEDS_first_last2;
set MEDS_first_last;
Guid_num = Guid*1;
run;

*TABLE WITH 33,008 RECORDS PRODUCED;
*RE-CATEGORIZE MEMBERS WITH 'UNKNOWN' FOR YEAR-IN-PROGRAM, TO 'YEAR 5';

Proc sql;
create table MEDS_First_Last_Final as
select a.Guid, a.Guid_num, b.DOB, 
       input( b.DOB, anydtdte24.) as DOB2 format=mmddyy10.,       
       floor((a.Date_Last - calculated DOB2)/365.25) as Age format=3.,
       b.gender,
  case
  when b.gender = '02' then 'Male'
  when b.gender = '03' then 'Female'
  else 'Unknown'
  end as Gender2, 
  case 
  when calculated Age between 18 and 34 then 'age 18-34'
  when calculated Age between 35 and 44 then 'age 35-44' 
  when calculated Age between 45 and 54 then 'age 45-54' 
  when calculated Age between 55 and 64 then 'age 55-64' 
  when calculated Age ge 65 then 'age 65+'
  end as AgeGroup,
  case
  when year_last - year_first = 5 then 'Year 5'
  when year_last - year_first = 4 then 'Year 4'
  when year_last - year_first = 3 then 'Year 3'
  when year_last - year_first = 2 then 'Year 2'
  when year_last - year_first = 1 then 'Year 1'
  when year_last - year_first gt 5 then 'Year 5'
  else 'unknown'
  end as year_in_pgm, a.*
from MEDS_first_last2 a inner join Anthem_elig_combined_2020_unique b
on a.Guid_num = b.Guid;
quit;


proc freq data = MEDS_First_Last_Final;
table gender Gender2 year_in_pgm year_in_pgm;
run;


*****************************************************************;
*****************************************************************;

*SET RISK DEPENDING ON QUESTION RESPONSE;

proc freq data=MEDS_First_Last_Final;
table value_first value_last Risk_First Risk_Last;
run;

Data MEDS_working_risk1;
set MEDS_First_Last_Final;

if Value_First = 'Almost every day' then Risk_First = 1;
else if Value_First = 'Sometimes' then Risk_First = 1;
else Risk_First = 0;


if Value_Last = 'Almost every day' then Risk_Last = 1;
else if Value_Last = 'Sometimes' then Risk_Last = 1;
else Risk_Last = 0;

run;


proc freq data=MEDS_working_risk1;
table value_first value_last Risk_First Risk_Last;
run;

*****************************************************************;

*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE ALCOHOL RISK BY REDUCING NUMBER OF DRINKS;
Data MEDS_working_risk2; /*(keep=guid gender2 drinks_T1 drinks_T2 risk_first risk_last Alcohol_Value_per_Risk Impact1 Risk_Last_Updated);*/ 
set MEDS_working_risk1;

MEDS_Value_per_Risk = 256.0;

Impact1 = 0;

*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE ACTIVITY RISK;
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP ACTIVITY RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;

format MEDS_Value_per_Risk DOLLAR10.2;
format Impact1 6.3;

run;
*****************************************************************;


*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table MEDS_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from MEDS_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;

*****************************************************************;

*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN ALCOHOL RISK;

*RECORD COUNT STAYES AT 141,967 -- THERE ARE NO NULL VALUES IN THE VALUE FIRST OR LAST CELLS;
Data MEDS_working_risk3;
set MEDS_working_risk2_b;

if value_first = '' then delete;
if value_last = '' then delete;

MEDS_Impact_Savings = Impact1*MEDS_Value_per_Risk;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
MEDS_Impact_Savings2 = Impact1*SIMM_value_risk;

format MEDS_Impact_Savings MEDS_Impact_Savings2 DOLLAR10.2;
run;

*************************************************************;

*FINANCIAL RESULTS ASSOCIATED WITH CHANGE IN MEDICATION FOR RELAXATION RISK;

proc freq data=MEDS_working_risk3;
table MEDS_Impact_Savings;
title 'ANTHEM - Frequency of MEDS_FOR_RELAXATION Impact'; 
run;

proc means sum data=MEDS_working_risk3;
var MEDS_Impact_Savings MEDS_Impact_Savings2;
title ' Final Result for ANTHEM MEDS_FOR_RELAXATION Analysis';
run;


********************************************************************************************************;


*MEDICATION FOR RELAXATION - LIMITING TO MEMBERS WITH ELIG IN 2019;

Data MEDS_working_risk3_update;
set MEDS_working_risk3;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on MEDS_working_risk3_update(Guid);
create index Guid_char on Angie_anthem_2019_mm_new2(Guid_char);
quit;


*22,211 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update MEDS_working_risk3_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid_char)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid_char)
; 
quit;

*MEDS_FOR_RELAXATION - ORIGINAL RESULT;
proc sql;
title 'Final Result for ANTHEM MEDS_FOR_RELAXATION Analysis';
select sum(MEDS_Impact_Savings2) as MEDS_savings format=dollar15.2
from MEDS_working_risk3_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'Final Result for ANTHEM MEDS_FOR_RELAXATION Analysis';
select sum(MEDS_Impact_Savings2) as MEDS_savings format=dollar15.2
from MEDS_working_risk3_update
where elig_months_2019 ge 1
;
quit;


*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from MEDS_working_risk3_update where elig_months_2019 ge 1; quit;


*****************************************************************************************;

*MEDICATION FOR RELAXATION - NO INCREMENTAL;

*NO UNKNOWNS IN THE TABLE NOW;
Proc freq data=MEDS_working_risk3_update;
table year_in_pgm;
run;

*T1 PERIOD RISK SHOWN;
proc freq data=Meds_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Meds_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
and year_in_pgm ne ('unknown');  
quit;

*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Meds_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0
and year_in_pgm ne ('unknown');  
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Meds_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;
