
*PHYSICAL ACTIVITY METRIC FOR ANTHEM;
*RERUN IN FEB 2020;



*REALAGE ORIGINAL RUN - 10,421 RECORDS;
*REALAGE RERUN HERE - 12,154 RECORDS;
*THIS PRODUCES COUNT, AND ALSO FORMATS DATE CORRECTLY, AND PRODUCES A 'YEAR' VARIABLE;
proc sql;
create table ACTIVITY_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 20514 
order by guid, from_date 
;
quit;


*THIS PRODUCES COUNT, AND ALSO FORMATS DATE CORRECTLY, AND PRODUCES A 'YEAR' VARIABLE;
*WBA ORIGINAL RUN - 155,823 RECORDS;
*WBA RERUN - 155,823 RECORDS;
proc sql;
create table ACTIVITY_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297710
;
quit;


*GET DISTINCT FACT_VALUES AND RESPONSE_TEXTS FROM THE 2 DIFFERENT TABLES;
*RECODE NEEDED VARIABLE NAMES AND RESPONSES, SO THAT TABLES CAN BE MERGED TOGETHER;

proc freq data=ACTIVITY_RealAge;
table fact_value;
title 'Realage Responses for Physical Activity';
quit;

proc freq data=ACTIVITY_WBA;
table response_text;
title 'WBA Responses for Physical Activity';
quit;

/* RealAge: fact_values 

lessThan1
mod1to4
mod5Plus
none
vigor1to2                    
vigor3Plus

freq missing  = 33

WBA: Response Texts

I do not exercise regular
Moderate: 1-4 times per w
Moderate: 5 or more times
On average, less than 1 t 
Vigorous: 1-2 times per w 
Vigorous: 3 or more times  

*/ 


*DO NEEDED RECODING SO THERE ARE NO PROBLEMS COMBINING AND USING THE RESPONSE_TEXT;

Data ACTIVITY_RealAge_recode1;
set Activity_RealAge;

format fact_value_new $40.;
informat fact_value_new $40.;


if fact_value = 'none' then fact_value_new = 'I do not exercise regular';
if fact_value = 'lessThan1' then fact_value_new = 'On average, less than 1 t';
if fact_value = 'mod1to4' then fact_value_new = 'Moderate: 1-4 times per w';
if fact_value = 'mod5Plus' then fact_value_new = 'Moderate: 5 or more times';
if fact_value = 'vigor1to2' then fact_value_new = 'Vigorous: 1-2 times per w';
if fact_value = 'vigor3Plus' then fact_value_new = 'Vigorous: 3 or more times';

format fact_value_new $40.;
run;


proc freq data=ACTIVITY_RealAge_recode1;
table fact_value_new;
title 'Freq of RealAge after Recoding the Responses';
run;

*******************************************************;


*DONT NEED IN THIS RERUN;
/*
*NEED A CHANGE ON WBA, HAVE TO GET THE COMMA OUT OF RESPONSE;
Data ACTIVITY_WBA_recode1;
set ACTIVITY_WBA;

if response_text = 'On average, less than 1 time per' then response_text = 'On average less than 1 time per';
run;

proc freq data=ACTIVITY_WBA;
table response_text;
title 'Freq of WBA after Recoding the Responses';
run;
*/


Data ACTIVITY_RealAge_recode2 (rename = (fact_id=asmnt_question_id fact_value_new=response_text from_date=response_date2)) ;
set ACTIVITY_RealAge_recode1;
run;

*2020 IS NOW THE LAST YEAR SEEN;
proc freq data=ACTIVITY_RealAge_recode2;
table year response_text;
run;


*RECORDS IN THE REALAGE TABLE WITH YEAR GREATER THAN 2019 ARE DELETED;
*TABLE GOES FROM 12,154 TO 10,446;
Data ACTIVITY_RealAge_recode3;
set ACTIVITY_RealAge_recode2;

if year le 2019;
run;



*****************************************************************;


proc freq data=ACTIVITY_WBA;
table response_text;
title 'Freq of WBA after Recoding the Responses';
run;


*MERGE REALGE AND WBA PHYSICAL ACTIVITY DATASETS;
Data Physical_Activity;
set  ACTIVITY_WBA ACTIVITY_RealAge_recode3;
run;

proc freq data=Physical_Activity;
table year response_text;
run;
*****************************************************************;

*OBTAIN FIRST AND LAST VALUES FROM THIS MERGED TABLE, 
THEN SORT BY GUID AND RESPONSE_DATE2;

proc sort data=Physical_Activity;
by guid response_date2;
run;


*Physical_Activity First value;
*N=93,712 RECORDS;
Data Activity_first;
set Physical_Activity;
by guid;
if first.guid;
run;

*Physical_Activity Last value;
*N=93,712 RECORDS;
Data Activity_last;
set Physical_Activity;
by guid;
if last.guid;
run;

*JOIN BOTH FIRST AND LAST ALCOHOL RECORD FILES;
*36,807 RECORDS IN TABLE;
proc sql;
create table ACTIVITY_first_last as
select 	a.guid, 
		'Physical Activity' as item,
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
from Activity_first a inner join Activity_last b
on a.guid = b.guid
where a.response_date2 <> b.response_date2;
quit;



*DELETE RECORD IN YEAR_FIRST = YEAR_LAST;
*36,807 RECORDS TO 35,874 RECORDS;
Data ACTIVITY_first_last;
set ACTIVITY_first_last;

if Year_First = Year_Last then delete;
run;

*****************************************************************;


*BRING DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

Data ACTIVITY_first_last2;
set ACTIVITY_first_last;
Guid_num = Guid*1;
run;

*TABLE WITH 32,869 RECORDS PRODUCED;
Proc sql;
create table ACTIVITY_First_Last_Final as
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
from ACTIVITY_first_last2 a inner join Anthem_elig_combined_2020_unique b
on a.Guid_num = b.Guid;
quit;


proc freq data = ACTIVITY_First_Last_Final;
table gender Gender2 year_in_pgm year_in_pgm;
run;


*****************************************************************;

*SET RISK DEPENDING ON GENDER AND THE AMOUNT OF ALCOHOL DRINKS BEING CONSUMED;

proc freq data=ACTIVITY_First_Last_Final;
table value_first value_last;
run;

Data ACTIVITY_working_risk1;
set ACTIVITY_First_Last_Final;

if Value_First = 'I do not exercise regular' then Risk_First = 1;
else if Value_First = 'On average, less than 1 t' then Risk_First = 1;
else if Value_First = 'Moderate: 1-4 times per w' then Risk_First = 1;
else if Value_First = 'Moderate: 5 or more times' then Risk_First = 0;
else if Value_First = 'Vigorous: 1-2 times per w' then Risk_First = 1;
else if Value_First = 'Vigorous: 3 or more times' then Risk_First = 0;
else Risk_First = 0;

if Value_Last = 'I do not exercise regular' then Risk_Last = 1;
else if Value_Last = 'On average, less than 1 t' then Risk_Last = 1;
else if Value_Last = 'Moderate: 1-4 times per w' then Risk_Last = 1;
else if Value_Last = 'Moderate: 5 or more times' then Risk_Last = 0;
else if Value_Last = 'Vigorous: 1-2 times per w' then Risk_Last = 1;
else if Value_Last = 'Vigorous: 3 or more times' then Risk_Last = 0;
else Risk_Last = 0;

run;


proc freq data=ACTIVITY_working_risk1;
table value_first value_last Risk_First Risk_Last;
title 'Risk Flags at T1 and T2 for Physical Activity';
run;


*****************************************************************;

*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE ALCOHOL RISK BY REDUCING NUMBER OF DRINKS;
Data ACTIVITY_working_risk2; /*(keep=guid gender2 drinks_T1 drinks_T2 risk_first risk_last Alcohol_Value_per_Risk Impact1 Risk_Last_Updated);*/ 
set ACTIVITY_working_risk1;

Activity_Value_per_Risk = 54.0;

Impact1 = 0;

*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE ACTIVITY RISK;
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP ACTIVITY RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;

format Activity_Value_per_Risk DOLLAR10.2;
format Impact1 6.3;

run;
*****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table ACTIVITY_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from ACTIVITY_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;

*****************************************************************;


*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN ALCOHOL RISK;

*RECORD COUNT GOES FROM 32,869 TO 32,855 WHEN TAKE OUT RECORDS WITH A NULL FIRST OR LAST VALUE;
Data ACTIVITY_working_risk3;
set ACTIVITY_working_risk2_b;

*ONLY RECORDS WITH POPULATED FIRST AND LAST VALUES WILL BE USED IN OBTAINING ASSOCIATED DOLLAR SAVINGS;
if value_first = '' then delete;
if value_last = '' then delete;

Activity_Impact_Savings = Impact1*Activity_Value_per_Risk;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
Activity_Impact_Savings2 = Impact1*SIMM_value_risk;

format Activity_Impact_Savings Activity_Impact_Savings2 DOLLAR10.2;
run;


*************************************************************;

*FINANCIAL RESULTS ASSOCIATED WITH CHANGE IN PHYSICAL ACTIVITY;

proc means sum data=ACTIVITY_working_risk3;
var Activity_Impact_Savings Activity_Impact_Savings2;
title ' Final Result for ANTHEM Physical Activity Analysis';
run;


**************************************************************;

*PHYSICAL ACTIVITY - LIMITING TO MEMBERS WITH ELIG IN 2019;

Data Activity_working_risk3_update;
set Activity_working_risk3;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on Activity_working_risk3_update(Guid);
create index Guid_char on Angie_anthem_2019_mm_new2(Guid_char);
quit;


*22,070 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update Activity_working_risk3_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid_char)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid_char)
; 
quit;


*PHYSICAL ACTIVITY - ORIGINAL RESULT;
proc sql;
title 'ANTHEM Physical Activity Risk Change Savings Result';
select sum(Activity_Impact_Savings2) as activity_savings format=dollar15.2
from Activity_working_risk3_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM Physical Activity Risk Change Savings Result';
select sum(Activity_Impact_Savings2) as activity_savings format=dollar15.2
from Activity_working_risk3_update
where elig_months_2019 ge 1
;
quit;

*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from Activity_working_risk3_update where elig_months_2019 ge 1; quit;


*COUNT OF MEMBERS IN RESULTS -- NOT USING THE 'UNKNOWNS' FOR YEAR-IN-PGM;
proc sql; select count(distinct guid) as members 
from Activity_working_risk3_update where elig_months_2019 ge 1 and year_in_pgm ne ('unknown');
quit;



*****************************************************************************************;

*RISK COUNTS;

*PHYSICAL ACTIVITY - NO INCREMENTAL;

*T1 PERIOD RISK SHOWN;
proc freq data=Activity_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Activity_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
and year_in_pgm ne ('unknown');
quit;


*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Activity_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0 
and year_in_pgm ne ('unknown');
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Activity_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;




