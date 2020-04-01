
*LIFE SATISFACTION RISK MEASURE FOR ANTHEM;

*RE-CATEGORIZE MEMBERS WITH 'UNKNOWN' FOR YEAR-IN-PROGRAM, TO 'YEAR 5'


*QUESTION BEING USED
In general, how satisfied are you with your life (include personal and professional aspects)?


*PULL LIFE SATISFACTION RISK RECORDS FROM REALAGE AND THE WBA;
*USING LIFE LADDER QUESTION FOR THIS ANALYSIS;


*12,265 RECORDS;
proc sql;
create table LIFE_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 19933
order by guid, from_date 
;
quit;


*THIS PRODUCES COUNT, AND ALSO FORMATS DATE CORRECTLY, AND PRODUCES A 'YEAR' VARIABLE;
*WBA; *155,823 RECORDS;
proc sql;
create table LIFE_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844296980
;
quit;

*******************************************************************************************;
*******************************************************************************************;


*GET DISTINCT FACT_VALUES AND RESPONSE_TEXTS FROM THE 2 DIFFERENT TABLES;
*RECODE NEEDED VARIABLE NAMES AND RESPONSES, SO THAT TABLES CAN BE MERGED TOGETHER;

proc freq data=LIFE_RealAge;
table fact_value;
title 'Realage Responses for LIFE SATISFACTION';
quit;

proc freq data=LIFE_WBA;
table response_text;
title 'WBA Responses for LIFE SATISFACTION';
quit;

/* RealAge: fact_values 

 0Worst                       
 1                            
 10Best                      
 2                           
 3                           
 4                           
 5                          
 6                          
 7                         
 8                          
 9                         
 dontKnow                     

Frequency Missing = 42



WBA: Response Texts
0 - Worst 
1 
10 
10 - Best 
11 
12 
2 
3  
4  
5 
6  
7  
8 
9  
Don't know  

*/ 


Data LIFE_RealAge_recode1;
set LIFE_RealAge;
if fact_value = '0Worst' then fact_value = '0 - Worst';
if fact_value = '10Best' then fact_value = '10 - Best';
if fact_value = 'dontKnow' then fact_value = 'DontKnow';
run;

*GET RID OF THE APOSTRAPHE IN THE RESPONSE;
Data LIFE_WBA_recode1;
set LIFE_WBA;
if response_text = '10' then response_text = '10 - Best';
if response_text = '0' then response_text = '0 - Worst';
if response_text = '11' then response_text = '0 - Worst';
if response_text = '12' then response_text = 'DontKnow';
if response_text = "Don't know" then response_text = 'DontKnow';
run;


proc freq data=LIFE_RealAge_recode1;
table fact_value;
run;

proc freq data=LIFE_WBA_recode1;
table response_text;
run;



Data LIFE_RealAge_recode2 (rename = (fact_id=asmnt_question_id fact_value=response_text from_date=response_date2)) ;
set LIFE_RealAge_recode1;
run;

*2020 IS NOW THE LAST YEAR SEEN;
proc freq data=LIFE_RealAge_recode2;
table year;
run;

*RECORDS IN THE REALAGE TABLE WITH YEAR GREATER THAN 2019 ARE DELETED;
*TABLE GOES FROM 12,265 TO 10,549;
Data LIFE_RealAge_recode3;
set LIFE_RealAge_recode2;

if year le 2019;
run;




*MERGE REALGE AND WBA LIFE SATISFACTION DATASETS  - 166,372 RECORDS;

Data LIFE_merged;
set LIFE_WBA_recode1 LIFE_RealAge_recode3; 
run;

proc freq data=LIFE_merged;
table response_text;
run;


*166,372 RECORDS;
Data LIFE_merged;
set LIFE_merged;


*DO NOT USE ANY RECORDS WITH NO RESPONSE TO THE LIFE SATISFACTION QUESTION;
if response_text in ('', 'DontKnow') then delete;
run;


*****************************************************************;
*****************************************************************;

*PRODUCE A NUMERIC RESPONSE VARIABLE, USING THE INITIAL CHARACTER VALUES;


Data LIFE_merged2;
set LIFE_merged;


if response_text = '0 - Worst' then response_text_num = 0;
else if response_text = '1' then response_text_num = 1;
else if response_text = '2' then response_text_num = 2;
else if response_text = '3' then response_text_num = 3;
else if response_text = '4' then response_text_num = 4;
else if response_text = '5' then response_text_num = 5;
else if response_text = '6' then response_text_num = 6;
else if response_text = '7' then response_text_num = 7;
else if response_text = '8' then response_text_num = 8;
else if response_text = '9' then response_text_num = 9;
else if response_text = '10 - Best' then response_text_num = 10;
run;



proc freq data=LIFE_merged2;
table response_text response_text_num;
run;


*OBTAIN FIRST AND LAST VALUES FROM THIS MERGED TABLE, 
THEN SORT BY GUID AND RESPONSE_DATE2;

proc sort data=LIFE_merged2;
by guid response_date2;
run;


*LIFE SATISFACTION First value;
*N=92,131 RECORDS;
Data LIFE_first;
set LIFE_merged2;
by guid;
if first.guid;
run;

*LIFE SATISFACTION Last value;
*N=92,131 RECORDS;
Data LIFE_last;
set LIFE_merged2;
by guid;
if last.guid;
run;

*JOIN BOTH FIRST AND LAST ALCOHOL RECORD FILES;
*35,978 RECORDS IN TABLE;
proc sql;
create table LIFE_first_last as
select 	a.guid, 
		'Life Satisfaction' as item,
		a.asmnt_question_id as Question_fact_id_First,
		a.response_date2 as Date_First,
		a.Year as Year_First,
		a.response_text as Value_First,
		a.response_text_num as Value_First_num,
		0 as Risk_First,
		b.asmnt_question_id as Question_fact_id_Last,
		b.response_date2 as Date_Last,
		b.Year as Year_Last,
		b.response_text as Value_Last,
		b.response_text_num as Value_Last_num,
		0 as Risk_Last
from LIFE_first a inner join LIFE_last b
on a.guid = b.guid
where a.response_date2 <> b.response_date2;
quit;


*DELETE RECORD IN YEAR_FIRST = YEAR_LAST;
*35,978 RECORDS TO 35,053 RECORDS;
Data LIFE_first_last;
set LIFE_first_last;

if Year_First = Year_Last then delete;
run;

*****************************************************************;
*****************************************************************;

*BRING DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

Data LIFE_first_last2;
set LIFE_first_last;
Guid_num = Guid*1;
run;

*TABLE WITH 32,092 RECORDS PRODUCED;
*RE-CATEGORIZE MEMBERS WITH 'UNKNOWN' FOR YEAR-IN-PROGRAM, TO 'YEAR 5';
Proc sql;
create table LIFE_First_Last_Final as
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
from LIFE_first_last2 a inner join Anthem_elig_combined_2020_unique b
on a.Guid_num = b.Guid;
quit;


proc freq data = LIFE_First_Last_Final;
table gender Gender2 year_in_pgm year_in_pgm;
run;


*****************************************************************;


*SET RISK DEPENDING ON QUESTION RESPONSE;
proc freq data=LIFE_First_Last_Final;
table Value_First_num Value_Last_num Risk_First Risk_Last;
run;


Data LIFE_working_risk1_DQ;
set LIFE_First_Last_Final;


if Value_First_num ge 7 then Risk_First = 0;
else if Value_First_num lt 7 then Risk_First = 1;


if Value_Last_num ge 7 then Risk_Last = 0;
else if Value_Last_num lt 7 then Risk_Last = 1;


satisfaction_level_change = Value_Last_num - Value_First_num;

run;


proc freq data=LIFE_working_risk1_DQ;
table Value_First_num Value_Last_num Risk_First Risk_Last;
run;


*****************************************************************;

*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE ALCOHOL RISK BY REDUCING NUMBER OF DRINKS;
Data LIFE_working_risk2_DQ(keep=guid gender2 Value_First Value_Last Value_First_num Value_Last_num Risk_First Risk_Last LIFE_Value_per_Risk Impact1 Risk_Last_Updated year_first year_last
                                year_first year_last satisfaction_level_change AgeGroup year_in_pgm item);  
set LIFE_working_risk1_DQ;

LIFE_Value_per_Risk = 135.0;

Impact1 = 0;



*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE LIFE SATISFACTION RISK; 
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP LIFE SATISFACTION RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;


*CODING BELOW ACCOUNTS FOR MEMBERS WHO ARE AT RISK AT T1 AND T2, BUT THEIR RISK LEVEL CHANGES;

*DECREASE IN RISK;
if Risk_First = 1 and Risk_Last = 1 and satisfaction_level_change gt 0 then DO;
Impact1 = (Value_Last_num - Value_First_num) / (7 - Value_First_num);
Risk_Last_Updated = (1 - Impact1);
END;

*INCREASE IN RISK, OR NO CHANGE IN RISK;
if Risk_First = 1 and Risk_Last = 1 and satisfaction_level_change le 0 then DO;
Impact1 = (Value_Last_num - Value_First_num) / (Value_First_num - 0);  
Risk_Last_Updated = (1 - Impact1);
END;

format LIFE_Value_per_Risk DOLLAR10.2;
format Impact1 Risk_Last_Updated 6.3;

run;

*****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table LIFE_working_risk2_DQ_b as 
select a.*, b.cost as SIMM_value_risk
from LIFE_working_risk2_DQ a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;


proc freq data=LIFE_working_risk2_DQ_b;
table impact1;
run;
*****************************************************************;


*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN ALCOHOL RISK;
Data LIFE_working_risk3_DQ;
set LIFE_working_risk2_DQ_b;


*if Impact1 gt 0 then DO;
LIFE_Impact_Savings = Impact1*LIFE_Value_per_Risk;
*END;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
LIFE_Impact_Savings2 = Impact1*SIMM_value_risk;

format LIFE_Impact_Savings LIFE_Impact_Savings2 DOLLAR10.2;
run;

*************************************************************;

*FINANCIAL RESULTS ASSOCIATED WITH CHANGE IN LIFE SATISFACTION;

proc freq data=LIFE_working_risk3_DQ;
table LIFE_Impact_Savings;
title 'SHBP - Frequency of Alcohol Impact'; 
run;

proc means sum data=LIFE_working_risk3_DQ;
var LIFE_Impact_Savings LIFE_Impact_Savings2;
title 'Final Result for SHBP LIFE SATISFACTION Analysis';
run;


**************************************************************;


*LIFE SATISFACTION - LIMITING TO MEMBERS WITH ELIG IN 2019;

Data Life_working_risk3_dq_update;
set Life_working_risk3_dq;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on Life_working_risk3_dq_update(Guid);
create index Guid_char on Angie_anthem_2019_mm_new2(Guid_char);
quit;


*21,631 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update Life_working_risk3_dq_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid_char)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid_char)
; 
quit;

*LIFE_SATISFACTION - ORIGINAL RESULT;
proc sql;
title 'Final Result for ANTHEM LIFE_SATISFACTION Analysis';
select sum(LIFE_Impact_Savings2) as LIFE_SAT_savings format=dollar15.2
from Life_working_risk3_dq_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'Final Result for ANTHEM LIFE_SATISFACTION Analysis';
select sum(LIFE_Impact_Savings2) as LIFE_SAT_savings format=dollar15.2
from Life_working_risk3_dq_update
where elig_months_2019 ge 1
;
quit;


proc sql;
title 'Final Result for ANTHEM LIFE_SATISFACTION Analysis';
select year_in_pgm, sum(LIFE_Impact_Savings2) as LIFE_SAT_savings format=dollar15.2
from Life_working_risk3_dq_update
where elig_months_2019 ge 1
group by year_in_pgm
;
quit;

*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from Life_working_risk3_dq_update where elig_months_2019 ge 1; quit;

*****************************************************************************************;

*RISK COUNTS;

*LIFE SATISFACTION - HAS INCREMENTAL;

*T1 PERIOD RISK SHOWN;
proc freq data=Life_working_risk3_dq_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Life_working_risk3_dq_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
quit;



*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Life_working_risk3_dq_update
where risk_first = 0
and risk_last = 1
and elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
quit;



*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Life_working_risk3_dq_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
run;


*RISK AT T1 AND T2, RISK HAS IMPROVED;
proc sql;
select count(distinct Guid)
from Life_working_risk3_dq_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
;
quit;


*RISK AT T1 AND T2, RISK HAS WORSENED;
proc sql;
select count(distinct Guid)
from Life_working_risk3_dq_update
where impact1 lt 0
and impact1 ne .
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown'); 
;
quit;
