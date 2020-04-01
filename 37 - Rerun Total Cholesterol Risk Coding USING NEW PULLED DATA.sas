

proc freq data=anthem_labs;
table testname;
run;


*TOTAL CHOLESTEROL RISK MEASURE FOR ANTHEM;
*RERUN IN MARCH 2020 USING NEW LAB FILE THAT PAWEL PULLED ON 3/3/2020;



*RERUN - 49,109 RECORDS PULLED;

proc sql;
create table ANTHEM_TOTAL_CHOL_records as
select distinct GUID, CustomerId, MemberUniqueId, TestName, TestResultValue, UnitOfMeasure,
       input(DateOfService, anydtdte24.) as DOS format=mmddyy10.,
	   year(calculated DOS) as year
from ANTHEM_labs_2020_NEW
where TestName in ('Cholesterol - Total','Total Cholesterol')
order by calculated DOS
;
quit;

proc freq data=ANTHEM_TOTAL_CHOL_records;
table year;
run;

*49,109 to 41,295 RECORDS;
Data ANTHEM_TOTAL_CHOL_records;
set ANTHEM_TOTAL_CHOL_records;

if year gt 2019 then delete;
run;

****************************************************************;
*GET FIRST AND LAST SYSTOLIC TOTAL CHOLESTEROL READINGS;

proc sort data=ANTHEM_TOTAL_CHOL_records;
by GUID DOS;
run;

*21,904 RECORDS;
Data totalchol_first;
set ANTHEM_TOTAL_CHOL_records;
by guid;
if first.guid;
run;

*21,904 RECORDS;
Data totalchol_last;
set ANTHEM_TOTAL_CHOL_records;
by guid;
if last.guid;
run;

*12,763 RECORDS;
proc sql;
create table TOTALCHOL_first_last as
select 	a.guid, 
		a.TestName,
		a.DOS as Date_First,
		a.Year as Year_First,
		input(a.TestResultValue, 5.) as totalchol_First,
		0 as Risk_First,
		b.DOS as Date_Last,
		b.Year as Year_Last,
		input(b.TestResultValue, 5.) as totalchol_Last,
		0 as Risk_Last
from totalchol_first a inner join totalchol_last b
on a.guid = b.guid
where a.DOS <> b.DOS;
quit;


*DELETE RECORD IF YEAR_FIRST = YEAR_LAST;
*12,763 RECORDS TO 12,691 RECORDS;
Data TOTALCHOL_first_last;
set TOTALCHOL_first_last;

if Year_First = Year_Last then delete;
run;



*****************************************************************;

*12,691 DISTINCT MEMBERS;
proc sql;
select count(distinct guid) as member_count
from TOTALCHOL_first_last
;
quit;

*RECORDS ARE FROM 2015 TO 2019;
proc freq data=TOTALCHOL_first_last;
table Year_first Year_last;
run;

*****************************************************************;

*BRING IN DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

*TABLE WITH *12,689 RECORDS;
Proc sql;
create table TOTALCHOL_First_Last_Final as
select distinct a.Guid, b.DOB, 'Cholesterol' as item,
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
  else 'unknown'
  end as year_in_pgm,    
  case
  when totalchol_Last lt totalchol_First then 'decreased'
  when totalchol_Last gt totalchol_First then 'increased' 
  when totalchol_Last = totalchol_First then 'no change'
  else 'unknown'
  end as change_in_totchol, a.*
from TOTALCHOL_first_last a inner join Anthem_elig_combined_2020_unique b
on a.Guid = b.Guid;
quit;

proc freq data=TOTALCHOL_First_Last_Final;
table year_in_pgm;
run;
*****************************************************************;

*SET RISK FLAGS, BASED ON FIRST AND LAST SYSTOLIC/DIASTOLIC READINGS;

Data TOTALCHOL_working_risk1; 
set TOTALCHOL_First_Last_Final;

*THIS PRODUCES NEW VALUE VARIABLES, BECAUSE HAVE TO SET VERY HIGH VALUES TO A MAXIMUM DEFINED VALUE;
totalchol_First2 = totalchol_First;
totalchol_Last2 = totalchol_Last;


*THIS SETS THE RISK FLAGS IN EACH TIME PERIOD, BASED ON THE REFERENCE RULE BEING USED;
if totalchol_First > 239 then Risk_First = 1;

if totalchol_Last > 239 then Risk_Last = 1;


*THIS SETS THE VERY HIGH TOTCHOL VALUES TO MAXIMUM DEFINED VALUE, AS NOTED IN IN THE METHODOLOGY DOCUMENT;
if totalchol_First2 gt 330 then totalchol_First2 = 330;
if totalchol_Last2 gt 330 then totalchol_Last2 = 330;

run;



proc freq data=TOTALCHOL_working_risk1;
table Risk_First Risk_Last;
title 'Comparison of Total Cholesterol Risk Flags from First and Last Reading';
run;


*****************************************************************;

*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE ALCOHOL RISK BY REDUCING NUMBER OF DRINKS;
Data TOTALCHOL_working_risk2(keep=guid gender2 totalchol_First totalchol_Last totalchol_First2 totalchol_Last2 Risk_First Risk_Last TOTALCHOL_Value_per_Risk Impact1 Risk_Last_Updated
                                  agegroup year_first year_last year_in_pgm item change_in_totchol); 
set TOTALCHOL_working_risk1;

TOTALCHOL_Value_per_Risk = 189.0;

Impact1 = 0;


/*
*THIS IS CODE THAT WORKS TO CALCULATE THE INCREMENTAL RISK THAT WE WILL USE ATTRIBUTE SAVINGS OR FURTHER EXPENSE
TO THOSE MEMBERS WHO STAY AT RISK AT T1 AND T2;
if Risk_First = 1 and Risk_Last = 1 then DO;
*Impact1 = (totalchol_First - totalchol_Last) / (239 - totalchol_First);
Impact1 = (totalchol_First - totalchol_Last) / (totalchol_First - 239);
Risk_Last_Updated = (1 - Impact1);
END;
*/

*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE LIFE SATISFACTION RISK; 
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP LIFE SATISFACTION RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;


*INCREMENTAL RISK CHANGE - 
CODING BELOW ACCOUNTS FOR MEMBERS WHO ARE AT RISK AT T1 AND T2, BUT THEIR RISK LEVEL CHANGES;

*DECREASE IN RISK;
if Risk_First = 1 and Risk_Last = 1 and change_in_totchol = 'decreased' then DO;
Impact1 = (totalchol_First2 - totalchol_Last2) / (totalchol_First2 - 239);
Risk_Last_Updated = (1 - Impact1);
END;

*INCREASE IN RISK, OR NO CHANGE IN RISK;
if Risk_First = 1 and Risk_Last = 1 and change_in_totchol in ('increased','no change') then DO;
Impact1 = (totalchol_First2 - totalchol_Last2) / (330 - totalchol_First2);
Risk_Last_Updated = (1 - Impact1);
END;



format TOTALCHOL_Value_per_Risk DOLLAR10.2;
format Impact1 Risk_Last_Updated 6.3;

run;

****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table TOTALCHOL_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from TOTALCHOL_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;


*****************************************************************;


*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN TOTAL CHOLESTEROL RISK;
Data TOTALCHOL_working_risk3;
set TOTALCHOL_working_risk2_b;


*if Impact1 gt 0 then DO;
TOTALCHOL_Impact_Savings = Impact1*TOTALCHOL_Value_per_Risk;
*END;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
TOTALCHOL_Impact_Savings2 = Impact1*SIMM_value_risk;


format TOTALCHOL_Impact_Savings TOTALCHOL_Impact_Savings2 DOLLAR10.2;
run;

*************************************************************;

*FINANCIAL RESULTS ASSOCIATED WITH CHANGE IN TOTAL CHOLESTEROL;

proc freq data=TOTALCHOL_working_risk3;
table TOTALCHOL_Impact_Savings TOTALCHOL_Impact_Savings2;
title 'ANTHEM - Frequency of TOTAL CHOL Impact'; 
run;


*-$75,532.72;
proc means sum data=TOTALCHOL_working_risk3;
var TOTALCHOL_Impact_Savings TOTALCHOL_Impact_Savings2;
title 'Final Result for ANTHEM TOTAL CHOLESTEROL Analysis';
run;


**************************************************************;

*TOTAL CHOLESTEROL;

Data TOTALCHOL_working_risk3_update;
set TOTALCHOL_working_risk3;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on TOTALCHOL_working_risk3_update(Guid);
create index Guid on Angie_anthem_2019_mm_new2(Guid);
quit;


*12,035 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update TOTALCHOL_working_risk3_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid)
; 
quit;

*TOTAL CHOLESTEROL - ORIGINAL RESULT -- *-$75,532.72;
title 'Final Result for ANTHEM TOTAL_CHOL Analysis';
proc sql;
select sum(TOTALCHOL_Impact_Savings2) as TOTAL_CHOL_savings format=dollar15.2
from TOTALCHOL_working_risk3_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR - $-75,355.08;
proc sql;
title 'Final Result for ANTHEM TOTAL_CHOL Analysis';
select sum(TOTALCHOL_Impact_Savings2) as TOTAL_CHOL_savings format=dollar15.2
from TOTALCHOL_working_risk3_update
where elig_months_2019 ge 1
;
quit;


*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from TOTALCHOL_working_risk3_update where elig_months_2019 ge 1; quit;



*TOTAL CHOLESTEROL - HAS INCREMENTAL;

*T1 PERIOD RISK SHOWN;
proc freq data=Totalchol_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Totalchol_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
quit;

*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Totalchol_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Totalchol_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;



*RISK AT T1 AND T2, RISK HAS IMPROVED;
proc sql;
select count(distinct Guid)
from Totalchol_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
;
quit;


*RISK AT T1 AND T2, RISK HAS WORSENED;
proc sql;
select count(distinct Guid)
from Totalchol_working_risk3_update
where impact1 lt 0
and impact1 ne .
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
;
quit;
