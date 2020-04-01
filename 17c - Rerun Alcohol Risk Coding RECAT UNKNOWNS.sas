
*ANTHEM LEGACY OUTCOMES - 2019 YEAR; 
*RERUN IN FEB 2020;



*THIS PRODUCES TABLE W REALAGE ALCOHOL QUEST AND ALSO FORMATS DATE CORRECTLY, AND PRODUCES A 'YEAR' VARIABLE;
*12,113 RECORDS;
proc sql;
create table alcohol_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 20000 
order by guid, from_date 
;
quit;


*155,822 RECORDS IN FIRST PULL;
*AFTER WORKING WITH CODE, I GET TO WORK PROPERLY 155,822 RECORDS PULLED AGAIN;
proc sql;
create table alcohol_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297730
;
quit;


*NO RECORDS SEEN AFTER THE 2019 YEAR;
proc freq data=alcohol_WBA;
table year;
run;


*****************************************************************;

*GET DISTINCT FACT_VALUES AND RESPONSE_TEXTS FROM THE 2 DIFFERENT TABLES;
*RECODE NEEDED VARIABLE NAMES AND RESPONSES, SO THAT TABLES CAN BE MERGED TOGETHER;

proc freq data=alcohol_RealAge;
table fact_value;
run;

proc freq data=alcohol_WBA;
table response_text;
run;

*RealAge: fact_values
1, 10, 11, 12, 13, 14, 15plus, 2, 3, 4, 5, 6, 7, 8, 9, none;

*WBA: response_texts
0, 1, 10, 11, 12, 13, 14, 15 or more, 2, 3, 4, 5, 6, 7, 8, 9;

*Apply wba response categories and variable names to RealAge
1. None -> 0
2. 15plus - > 15 or more
3. fact_id -> asmnt_question_id
4. fact_value -> response_text 
5. valid_from_date -> response_date2;


Data alcohol_RealAge_recode1;
set alcohol_RealAge;
if fact_value = 'none' then fact_value = '0';
if fact_value = '15plus' then fact_value = '15 or more';
run;


Data alcohol_RealAge_recode2 (rename =(fact_id=asmnt_question_id fact_value=response_text from_date=response_date2)) ;
set alcohol_RealAge_recode1;
run;

*2020 IS NOW THE LAST YEAR SEEN;
proc freq data=alcohol_RealAge_recode2;
table year;
run;


*RECORDS IN THE REALAGE TABLE WITH YEAR GREATER THAN 2019 ARE DELETED;
*TABLE GOES FROM 12,113 TO 10,423;
Data alcohol_RealAge_recode3;
set alcohol_RealAge_recode2;

if year le 2019;
run;


*****************************************************************;

*CHECKING THE YEARS AGAIN ON BOTH FILES;
proc freq data=alcohol_RealAge_recode3;
table year; run;

proc freq data=Alcohol_WBA;
table year; run;


*MERGE REALGE AND WBA ALCOHOL DATASETS;
Data alcohol;
set  Alcohol_WBA alcohol_RealAge_recode3;
run;


proc freq data=alcohol;
table response_text;
run;

*****************************************************************;

*OBTAIN FIRST AND LAST VALUES FROM THIS MERGED TABLE, 
THEN SORT BY GUID AND RESPONSE_DATE2;

proc sort data=alcohol;
by guid response_date2;
run;


*Alcohol First value;
*N=93,751 RECORDS;
Data alcohol_first;
set alcohol;
by guid;
if first.guid;
run;

*Alcohol Last value;
*N=93,751 RECORDS;
Data alcohol_last;
set alcohol;
by guid;
if last.guid;
run;

*JOIN BOTH FIRST AND LAST ALCOHOL RECORD FILES;
*36,770 RECORDS IN TABLE;
proc sql;
create table Alcohol_first_last as
select 	a.guid, 
		'Alcohol' as item,
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
from alcohol_first a inner join alcohol_last b
on a.guid = b.guid
where a.response_date2 <> b.response_date2;
quit;


*DELETE RECORD IN YEAR_FIRST = YEAR_LAST;
*36,770 RECORDS TO 35,868 RECORDS;
Data Alcohol_first_last;
set Alcohol_first_last;

if Year_First = Year_Last then delete;
run;


*****************************************************************;

*BRING DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

Data Alcohol_first_last2;
set Alcohol_first_last;
Guid_num = Guid*1;
run;


*32,863 RECORDS IN TABLE;
Proc sql;
create table Alcohol_First_Last_Final as
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
from alcohol_first_last2 a INNER JOIN Anthem_elig_combined_2020_unique b
on a.Guid_num = b.Guid;
quit;


proc freq data = Alcohol_First_Last_Final;
table gender Gender2 year_first year_last year_in_pgm;
run;


*****************************************************************;

*SET RISK DEPENDING ON GENDER AND THE AMOUNT OF ALCOHOL DRINKS BEING CONSUMED;

proc freq data=Alcohol_first_last_final;
table value_first value_last;
run;

*THIS STEP PRODUCES NUMERIC VARIABLES FOR NUMBER OF DRINKS IN EACH TIME PERIOD, AND RISK FLAG BASED ON GENDER AND NUMBER OF DRINKS;
Data alc_working_risk1;
set Alcohol_First_Last_Final;

if Value_First = '1' then drinks_T1 = 1;
else if Value_First = '2' then drinks_T1 = 2;
else if Value_First = '3' then drinks_T1 = 3;
else if Value_First = '4' then drinks_T1 = 4;
else if Value_First = '5' then drinks_T1 = 5;
else if Value_First = '6' then drinks_T1 = 6;
else if Value_First = '7' then drinks_T1 = 7;
else if Value_First = '8' then drinks_T1 = 8;
else if Value_First = '9' then drinks_T1 = 9;
else if Value_First = '10' then drinks_T1 = 10;
else if Value_First = '11' then drinks_T1 = 11;
else if Value_First = '12' then drinks_T1 = 12;
else if Value_First = '13' then drinks_T1 = 13;
else if Value_First = '14' then drinks_T1 = 14;
else if Value_First = '15 or more' then drinks_T1 = 15;
else if Value_First = '0' then drinks_T1 = 0;
else drinks_T1 = .;

if Value_Last = '1' then drinks_T2 = 1;
else if Value_Last = '2' then drinks_T2 = 2;
else if Value_Last = '3' then drinks_T2 = 3;
else if Value_Last = '4' then drinks_T2 = 4;
else if Value_Last = '5' then drinks_T2 = 5;
else if Value_Last = '6' then drinks_T2 = 6;
else if Value_Last = '7' then drinks_T2 = 7;
else if Value_Last = '8' then drinks_T2 = 8;
else if Value_Last = '9' then drinks_T2 = 9;
else if Value_Last = '10' then drinks_T2 = 10;
else if Value_Last = '11' then drinks_T2 = 11;
else if Value_Last = '12' then drinks_T2 = 12;
else if Value_Last = '13' then drinks_T2 = 13;
else if Value_Last = '14' then drinks_T2 = 14;
else if Value_Last = '15 or more' then drinks_T2 = 15;
else if Value_Last = '0' then drinks_T2 = 0;
else drinks_T2 = .;

if Gender2 = 'Female' 
THEN DO;
if drinks_T1 gt 8 then Risk_First = 1;
if drinks_T2 gt 8 then Risk_Last = 1;
END;

if Gender2 = 'Male' 
THEN DO;
if drinks_T1 gt 13 then Risk_First = 1;
if drinks_T2 gt 13 then Risk_Last = 1;
END;

if drinks_T1 = . then Risk_First = .;
if drinks_T2 = . then Risk_Last = .;

Drink_Change = drinks_T2 - drinks_T1;
run;


proc freq data=alc_working_risk1;
table Risk_First Risk_Last;
run;

*****************************************************************;

*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE ALCOHOL RISK BY REDUCING NUMBER OF DRINKS;


*RECORD COUNT GOES FROM 32,863, TO 32,850;
Data alc_working_risk2 (keep=guid gender2 drinks_T1 drinks_T2 risk_first risk_last Alcohol_Value_per_Risk Impact1 Risk_Last_Updated 
                             year_first year_last Drink_Change AgeGroup year_in_pgm item); 
set alc_working_risk1;


*ONLY RECORDS WITH POPULATED FIRST AND LAST VALUES WILL BE USED IN OBTAINING ASSOCIATED DOLLAR SAVINGS;
if drinks_T1 = . then delete;
if drinks_T2 = . then delete;



Alcohol_Value_per_Risk = 86.0;

*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE ALCOHOL RISK;
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS CODE ACCOUNTS FOR MEMBERS WITH GO FROM 'NO RISK TO 'AT RISK' REGARDING ALCOHOL;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;



*CODING BELOW ACCOUNTS FOR MEMBERS WHO ARE AT RISK AT T1 AND T2, BUT THEIR RISK LEVEL CHANGES;

*I THINK I HAVE A PROBLEM WITH THE EQUATION THAT WE SEE IN THE 'ROI METHODOLOGY' DOCUMENT, I THINK THE DENOMINATOR
SHOULD BE A CONSTANT, AND NOT THIS CALCULATED DENOMINATOR SEEN BELOW;

*FOR FEMALES;
*DECREASE IN RISK;
if Gender2 = 'Female' and Risk_First = 1 and Risk_Last = 1 and Drink_Change lt 0 then DO;
Impact1 = (drinks_T1 - drinks_T2) / (drinks_T1 - 8);
Risk_Last_Updated = (1 - Impact1);
END;

*INCREASE IN RISK, OR NO CHANGE IN RISK;
if Gender2 = 'Female' and Risk_First = 1 and Risk_Last = 1 and Drink_Change ge 0 then DO;
Impact1 = (drinks_T1 - drinks_T2) / (15 - drinks_T1);
Risk_Last_Updated = (1 - Impact1);
END;



*FOR MALES;
*DECREASE IN RISK;
if Gender2 = 'Male' and Risk_First = 1 and Risk_Last = 1 and Drink_Change lt 0 then DO;
Impact1 = (drinks_T1 - drinks_T2) / (drinks_T1 - 13);
Risk_Last_Updated = (1 - Impact1);
END;

*INCREASE IN RISK, OR NO CHANGE IN RISK;
if Gender2 = 'Male' and Risk_First = 1 and Risk_Last = 1 and Drink_Change ge 0 then DO;
Impact1 = (drinks_T1 - drinks_T2) / (15 - drinks_T1);
Risk_Last_Updated = (1 - Impact1);
END;



format Alcohol_Value_per_Risk DOLLAR10.2;
format Impact1 Risk_Last_Updated 6.3;

run;


*****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table alc_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from alc_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;


*****************************************************************;


*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN ALCOHOL RISK;
Data alc_working_risk3;
set alc_working_risk2_b;



Alc_Impact_Savings = Impact1*Alcohol_Value_per_Risk;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
Alc_Impact_Savings2 = Impact1*SIMM_value_risk;


format Alc_Impact_Savings Alc_Impact_Savings2 DOLLAR10.2;
run;



*************************************************************;

*FINANCIAL RESULTS ASSOCIATED WITH CHANGE IN USE OF ALCOHOL RISK;

proc freq data=alc_working_risk3;
table Alc_Impact_Savings;
title 'ANTHEM - Frequency of Alcohol Impact'; 
run;

proc means sum data=alc_working_risk3;
var Alc_Impact_Savings Alc_Impact_Savings2 impact1 drinks_T1 drinks_T2;
title 'Final Result for ANTHEM Alcohol Use Analysis';
format Alc_Impact_Savings Alc_Impact_Savings2 DOLLAR10.2;
run;


proc freq data=alc_working_risk3;
table year_first year_last;
title 'Looking at Years of Members in Program';
run;

*********************************************************************************************************;
*LIMITING RESULTS TO MEMBERS WITH ELIG IN 2019 YEAR;

*ALCOHOL;
Data Alc_working_risk3_update;
set Alc_working_risk3;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on Alc_working_risk3_update(Guid);
create index Guid_char on Angie_anthem_2019_mm_new2(Guid_char);
quit;

*22,067 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update Alc_working_risk3_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid_char)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid_char)
; 
quit;


*ALCOHOL - ORIGINAL RESULT;
proc sql;
title 'SHBP Alcohol Risk Change Savings Result';
select sum(Alc_Impact_Savings2) as alcohol_savings format=dollar15.2
from Alc_working_risk3_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'ANTHEM Alcohol Risk Change Savings Result';
select sum(Alc_Impact_Savings2) as alcohol_savings format=dollar15.2
from Alc_working_risk3_update
where elig_months_2019 gt 0
;
quit;

*JUST A CHECK - SAME RESULT AS ABOVE;
proc means sum data=Alc_working_risk3_update;
var Alc_Impact_Savings Alc_Impact_Savings2 impact1 drinks_T1 drinks_T2;
title 'Final Result for ANTHEM Alcohol Use Analysis';
format Alc_Impact_Savings Alc_Impact_Savings2 DOLLAR10.2;
WHERE elig_months_2019 ge 1;
run;


*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from Alc_working_risk3_update where elig_months_2019 ge 1; quit;


*COUNT OF MEMBERS IN RESULTS -- NOT USING THE 'UNKNOWNS' FOR YEAR-IN-PGM;
proc sql; select count(distinct guid) as members 
from Alc_working_risk3_update where elig_months_2019 ge 1 and year_in_pgm ne ('unknown');
quit;


******************************************************************************************************************;

*ALCOHOL RISK CHANGE - HAS INCREMENTAL CHANGE;

*NO UNKNOWNS NOW IN TABLE;
proc freq data=Alc_working_risk3_update;
table year_in_pgm;
run;


*T1 PERIOD RISK SHOWN;
proc freq data=Alc_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;


*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Alc_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
and year_in_pgm ne ('unknown');
quit;

*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Alc_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0
and year_in_pgm ne ('unknown'); 
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Alc_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;



*RISK AT T1 AND T2, RISK HAS IMPROVED;
proc sql;
select count(distinct Guid)
from Alc_working_risk3_update
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
from Alc_working_risk3_update
where impact1 lt 0
and impact1 ne .
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
and year_in_pgm ne ('unknown');
quit;
