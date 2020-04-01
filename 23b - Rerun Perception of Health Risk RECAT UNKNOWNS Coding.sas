*PERCEPTION OF HEALTH RISK MEASURE CODING FOR ANTHEM;
*RERUN IN FEB 2020;


*PULL 'PERCEPTI0N OF HEALTH' RISK RECORDS FROM REALAGE AND THE WBA;

*RealAge; *11,879 RECORDS;
*RERUN - 13,682 RECORDS;
proc sql;
create table PERCEPT_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 20508
order by guid, from_date 
;
quit;


*THIS PRODUCES COUNT, AND ALSO FORMATS DATE CORRECTLY, AND PRODUCES A 'YEAR' VARIABLE;
*WBA; *155,822 RECORDS;
proc sql;
create table PERCEPT_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297340
;
quit;

*******************************************************************************************;

*GET DISTINCT FACT_VALUES AND RESPONSE_TEXTS FROM THE 2 DIFFERENT TABLES;
*RECODE NEEDED VARIABLE NAMES AND RESPONSES, SO THAT TABLES CAN BE MERGED TOGETHER;


proc freq data=PERCEPT_RealAge;
table fact_value;
title 'Realage Responses for PERCEPTION OF HEALTH';
quit;

proc freq data=PERCEPT_WBA;
table response_text;
title 'WBA Responses for PERCEPTION OF HEALTH';
quit;

/* RealAge: fact_values 

excellent  
fair  
good   
poor  
veryGood 

 
WBA: Response Texts
Excellent 
Fair 
Good 
Poor 
Very Good 

*/


Data PERCEPT_RealAge_recode1;
set PERCEPT_RealAge;
if fact_value = 'excellent' then fact_value = 'Excellent';
if fact_value = 'veryGood' then fact_value = 'Very Good';
if fact_value = 'good ' then fact_value = 'Good';
if fact_value = 'fair' then fact_value = 'Fair';
if fact_value = 'poor' then fact_value = 'Poor';
run;


proc freq data=PERCEPT_RealAge_recode1;
table fact_value;
run;

proc freq data=PERCEPT_WBA;
table response_text;
run;


Data PERCEPT_RealAge_recode2 (rename = (fact_id=asmnt_question_id fact_value=response_text from_date=response_date2)) ;
set PERCEPT_RealAge_recode1;
run;

*2020 RECORDS ARE IN THIS TABLE - HAVE TO DELETE OUT;
proc freq data=PERCEPT_RealAge_recode2;
table year;
run;
 


*RECORDS IN THE REALAGE TABLE WITH YEAR GREATER THAN 2019 ARE DELETED;
*TABLE GOES FROM 13,682 TO 11,863;
Data PERCEPT_RealAge_recode3;
set PERCEPT_RealAge_recode2;

if year le 2019;
run;


*****************************************************************;

*MERGE REALGE AND WBA PERCEPTION DATA SETS;
Data PERCEPT_merged;
set  PERCEPT_WBA PERCEPT_RealAge_recode2;
run;

*169,504 RECORDS;
proc freq data=PERCEPT_merged;
table response_text;
run;


*****************************************************************;


*OBTAIN FIRST AND LAST VALUES FROM THIS MERGED TABLE, 
THEN SORT BY GUID AND RESPONSE_DATE2;

proc sort data=PERCEPT_merged;
by guid response_date2;
run;


*PERCEPT First value;
*N=95,917 RECORDS;
Data PERCEPT_first;
set PERCEPT_merged;
by guid;
if first.guid;
run;

*PERCEPT Last value;
*N=95,917 RECORDS;
Data PERCEPT_last;
set PERCEPT_merged;
by guid;
if last.guid;
run;

*JOIN BOTH FIRST AND PERCEPT RECORD FILES;
*37,247 RECORDS IN TABLE;
proc sql;
create table PERCEPT_first_last as
select 	a.guid, 
		'Perceived Health Status' as item,
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
from PERCEPT_first a inner join PERCEPT_last b
on a.guid = b.guid
where a.response_date2 <> b.response_date2;
quit;


*DELETE RECORD IN YEAR_FIRST = YEAR_LAST;
*37,247 RECORDS TO 36,355 RECORDS;
Data PERCEPT_first_last;
set PERCEPT_first_last;

if Year_First = Year_Last then delete;
run;

*****************************************************************;
*****************************************************************;


*BRING DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

Data PERCEPT_first_last2;
set PERCEPT_first_last;
Guid_num = Guid*1;
run;

*TABLE WITH 33,350 RECORDS PRODUCED;
Proc sql;
create table PERCEPT_First_Last_Final as
select distinct a.Guid, a.Guid_num, b.DOB, 
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
from PERCEPT_first_last2 a inner join Anthem_elig_combined_2020_unique b
on a.Guid_num = b.Guid;
quit;


proc freq data = PERCEPT_First_Last_Final;
table gender Gender2 year_in_pgm;
run;


*****************************************************************;


*SET RISK DEPENDING ON QUESTION RESPONSE;

proc freq data=PERCEPT_First_Last_Final;
table value_first value_last Risk_First Risk_Last;
run;


Data PERCEPT_working_risk1;
set PERCEPT_First_Last_Final;

if Value_First = 'Fair' then Risk_First = 1;
else if Value_First = 'Poor' then Risk_First = 1;
else Risk_First = 0;

if Value_Last = 'Fair' then Risk_Last = 1;
else if Value_Last = 'Poor' then Risk_Last = 1;
else Risk_Last = 0;

run;


proc freq data=PERCEPT_working_risk1;
table value_first value_last Risk_First Risk_Last;
run;

*****************************************************************;

*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE ALCOHOL RISK BY REDUCING NUMBER OF DRINKS;
Data PERCEPT_working_risk2; /*(keep=guid gender2 drinks_T1 drinks_T2 risk_first risk_last Alcohol_Value_per_Risk Impact1 Risk_Last_Updated);*/ 
set PERCEPT_working_risk1;

PERCEPT_Value_per_Risk = 134.0;

Impact1 = 0;

*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE 'PERCEPTION OF HEALTH' RISK;
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP 'PERCEPTION OF HEALTH' RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH RISK AT T1 & T2, AND INCREASE THEIR PERCEPTION OF HEALTH' RISK
FROM T1 TO T2;
If Risk_First = 1 and Risk_Last = 1 and Value_First = 'Fair' and Value_Last = 'Poor' then Impact1 = -1.0;

*WHAT DO WE DO ABOUT THIS SCENARIO - WHERE RISK IS STILL THERE , BUT MEMBER'S RESPONSE INDICATES IMPROVEMENT,
THERE ARE 2 'RISK' RESPONSES (FAIR AND POOR), IF THE MEMBER IMPROVES FROM 'POOR' TO 'FAIR' I AM GIVING THEM 50% OF 
THE 'VALUE PER RISK';
If Risk_First = 1 and Risk_Last = 1 and Value_First = 'Poor' and Value_Last = 'Fair' then Impact1 = 1.0;


format PERCEPT_Value_per_Risk DOLLAR10.2;
format Impact1 6.3;

run;

*****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table PERCEPT_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from PERCEPT_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;

*****************************************************************;

*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN ALCOHOL RISK;

*RECORD COUNT STAYS AT 33,350 -- THERE ARE NO NULL VALUES IN THE VALUE FIRST OR LAST CELLS;
Data PERCEPT_working_risk3;
set PERCEPT_working_risk2_b;

if value_first = '' then delete;
if value_last = '' then delete;

PERCEPT_Impact_Savings = Impact1*PERCEPT_Value_per_Risk;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
PERCEPT_Impact_Savings2 = Impact1*SIMM_value_risk;

format PERCEPT_Impact_Savings PERCEPT_Impact_Savings2 DOLLAR10.2;
run;

*************************************************************;


*FINANCIAL RESULTS ASSOCIATED WITH PERCEPTION OF HEALTH RISK;

proc freq data=PERCEPT_working_risk3;
table PERCEPT_Impact_Savings;
title 'ANTHEM - Frequency of PERCEPTION OF HEALTH RISK Impact'; 
run;

proc means sum data=PERCEPT_working_risk3;
var PERCEPT_Impact_Savings PERCEPT_Impact_Savings2;
title ' Final Result for ANTHEM PERCEPTION OF HEALTH RISK Analysis';
run;

**************************************************************;


*PERCEPTION OF HEALTH - LIMITING TO MEMBERS WITH ELIG IN 2019;

Data Percept_working_risk3_update;
set Percept_working_risk3;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on Percept_working_risk3_update(Guid);
create index Guid_char on Angie_anthem_2019_mm_new2(Guid_char);
quit;


*22,538 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update Percept_working_risk3_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid_char)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid_char)
; 
quit;

*PERCEPTION_HEALTH - ORIGINAL RESULT;
proc sql;
title 'Final Result for ANTHEM PERCEPTION_HEALTH Analysis';
select sum(PERCEPT_Impact_Savings2) as PERCEPT_savings format=dollar15.2
from Percept_working_risk3_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'Final Result for ANTHEM PERCEPTION_HEALTH Analysis';
select sum(PERCEPT_Impact_Savings2) as PERCEPT_savings format=dollar15.2
from Percept_working_risk3_update
where elig_months_2019 ge 1
;
quit;


*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from Percept_working_risk3_update where elig_months_2019 ge 1; quit;


*****************************************************************************************;

*RISK COUNTS;

*PERCEPTION OF HEALTH - HAS INCREMENTAL;

*T1 PERIOD RISK SHOWN;
proc freq data=Percept_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Percept_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
quit;


*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Percept_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Percept_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;



*RISK AT T1 AND T2, RISK HAS IMPROVED;
proc sql;
select count(distinct Guid)
from Percept_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0
and year_in_pgm ne ('unknown');  
;
quit;


*RISK AT T1 AND T2, RISK HAS WORSENED;
proc sql;
select count(distinct Guid)
from Percept_working_risk3_update
where impact1 lt 0
and impact1 ne .
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0
and year_in_pgm ne ('unknown');  
;
quit;
