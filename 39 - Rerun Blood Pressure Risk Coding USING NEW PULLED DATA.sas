*BLOOD PRESSURE RISK MEASURE FOR ANTHEM;
*RERUN IN FEB 2020;


proc freq data=ANTHEM_labs_2020_NEW;
table testname;
run;

*82,920 RECORDS PULLED - SYSTOLIC OR DIASTOLIC BP;
*RERUN USING NEW PULL - 83,892 RECORDS;

proc sql;
create table Anthem_BP_records as
select distinct GUID, CustomerId, MemberUniqueId, TestName, TestResultValue, UnitOfMeasure,
       input(DateOfService, anydtdte24.) as DOS format=mmddyy10.,
	   year(calculated DOS) as year
from ANTHEM_labs_2020_NEW
where TestName = 'Blood Pressure - Diastolic (Lower)'
      or TestName = 'Blood Pressure - Systolic (Upper)'
order by calculated DOS
;
quit;


proc freq data=Anthem_BP_records;
table year;
run;

*82,950 RECORDS;
Data Anthem_BP_records;
set Anthem_BP_records;

if year = 2020 then delete;
run;

****************************************************************;

****************************************************************;
*GET FIRST AND LAST SYSTOLIC BP READINGS;

*41,473 RECS;
Data systolic1;
set Anthem_BP_records;

if TestName = 'Blood Pressure - Systolic (Upper)';

proc sort data=systolic1;
by GUID DOS;
run;

*21,957 RECORDS;
Data systolic_first;
set systolic1;
by guid;
if first.guid;
run;

*21,957 RECORDS;
Data systolic_last;
set systolic1;
by guid;
if last.guid;
run;

*12,807 RECORDS;
proc sql;
create table SYSTOLIC_first_last as
select 	a.guid, 
		a.TestName,
		a.DOS as Date_First,
		a.Year as Year_First,
		input(a.TestResultValue, 5.) as Sys_First,
		0 as Risk_First,
		b.DOS as Date_Last,
		b.Year as Year_Last,
		input(b.TestResultValue, 5.) as Sys_Last,
		0 as Risk_Last
from systolic_first a inner join systolic_last b
on a.guid = b.guid
where a.DOS <> b.DOS;
quit;


*****************************************************************;
*GET FIRST AND LAST DIASTOLIC BP READINGS;

Data diastolic1;
set Anthem_BP_records;

if TestName = 'Blood Pressure - Diastolic (Lower)';

proc sort data=diastolic1;
by GUID DOS;
run;

*21,958 RECORDS;
Data diastolic_first;
set diastolic1;
by guid;
if first.guid;
run;

*21,958 RECORDS;
Data diastolic_last;
set diastolic1;
by guid;
if last.guid;
run;

*12,807 RECORDS;
proc sql;
create table DIASTOLIC_first_last as
select 	a.guid, a.guid*1 as Guid_num,
		a.TestName,
		a.DOS as Date_First,
		a.Year as Year_First,
		input(a.TestResultValue, 5.)as Dias_First,
		0 as Risk_First,
		b.DOS as Date_Last,
		b.Year as Year_Last,
		input(b.TestResultValue, 5.) as Dias_Last,
		0 as Risk_Last
from diastolic_first a inner join diastolic_last b
on a.guid = b.guid
where a.DOS <> b.DOS;
quit;

*****************************************************************;
*BRING SYSTOLIC AND DIASTOLIC READINGS TOGETHER;

*12,731 RECORDS;
proc sql;
create table bp_summary1 as
select a.Guid, a.date_first, a.Year_first, a.Sys_first, b.Dias_first, a.Risk_First,
               a.date_last, a.Year_last, a.Sys_last, b.Dias_last, a.Risk_Last  
from SYSTOLIC_first_last a, DIASTOLIC_first_last b
where a.Guid = b.Guid
and a.Date_First = b.Date_First
and a.Date_Last = b.Date_Last
and a.year_first <> a.year_last
;
quit;

*12,731 DISTINCT MEMBERS;
proc sql;
select count(distinct guid) as member_count
from bp_summary1
;
quit;

*RECORDS ARE FROM 2015 TO 2019;
proc freq data=bp_summary1;
table Year_first Year_last;
run;

*****************************************************************;

*BRING IN DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

*TABLE WITH *12,729 RECORDS;
Proc sql;
create table BP_First_Last_Final as
select distinct a.Guid, b.DOB, 'Blood Pressure' as item,
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
  end as year_in_pgm, a.*
from bp_summary1 a inner join Anthem_elig_combined_2020_unique b
on a.Guid = b.Guid;
quit;

proc freq data=BP_First_Last_Final;
table year_in_pgm;
run;

*****************************************************************;
*SET RISK FLAGS, BASED ON FIRST AND LAST SYSTOLIC/DIASTOLIC READINGS;

Data BP_working_risk1; 
set BP_First_Last_Final;

if sys_first > 139 then Risk_First = 1;
if dias_first > 89 then Risk_First = 1;


if sys_last > 139 then Risk_Last = 1;
if dias_last > 89 then Risk_Last = 1;
run;



proc freq data=BP_working_risk1;
table Risk_First Risk_Last;
title 'Comparison of BP Risk Flags from First and Last Reading';
run;


*****************************************************************;


*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO ELIMINATE BP RISK;

Data BP_working_risk2; /*(keep=guid gender2 drinks_T1 drinks_T2 risk_first risk_last Alcohol_Value_per_Risk Impact1 Risk_Last_Updated);*/ 
set BP_working_risk1;

BP_Value_per_Risk = 221.0;

Impact1 = 0;

*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE ACTIVITY RISK;
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP ACTIVITY RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;

format BP_Value_per_Risk DOLLAR10.2;
format Impact1 6.3;

run;

****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table BP_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from BP_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;


*****************************************************************;

*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN BP RISK;

Data BP_working_risk3_ORIG_DEFIN;
set BP_working_risk2_b;


BP_Impact_Savings = Impact1*BP_Value_per_Risk;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
BP_Impact_Savings2 = Impact1*SIMM_value_risk;

format BP_Impact_Savings BP_Impact_Savings2 DOLLAR10.2;
run;


*****************************************************************;

*FINANCIAL RESULTS ASSOCIATED WITH CHANGE IN BP RISK;

proc freq data=BP_working_risk3;
table BP_Impact_Savings BP_Impact_Savings2;
title 'ANTHEM - Frequency of BP Impact'; 
run;

proc means sum data=BP_working_risk3_ORIG_DEFIN;
var BP_Impact_Savings BP_Impact_Savings2;
title ' Final Result for ANTHEM BP Analysis';
run;


*****************************************************************************************************************
*****************************************************************************************************************


**************************************************************;

*BLOOD PERSSURE - LIMITING TO MEMBERS WITH ELIG IN 2019;

Data BP_working_risk3_ORIG_DEFIN_upda;
set BP_working_risk3_ORIG_DEFIN;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on BP_working_risk3_ORIG_DEFIN_upda(Guid);
create index Guid on Angie_anthem_2019_mm_new2(Guid);
quit;


*12,074 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update BP_working_risk3_ORIG_DEFIN_upda a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid)
; 
quit;

*BLOOD PRESSURE - ORIGINAL RESULT;
proc sql;
title 'Final Result for ANTHEM BLOOD PERSSURE Analysis';
select sum(BP_Impact_Savings2) as BP_savings format=dollar15.2
from BP_working_risk3_ORIG_DEFIN_upda
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'Final Result for ANTHEM BLOOD PERSSURE Analysis';
select sum(BP_Impact_Savings2) as BP_savings format=dollar15.2
from BP_working_risk3_ORIG_DEFIN_upda
where elig_months_2019 ge 1
;
quit;


*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from BP_working_risk3_ORIG_DEFIN_upda where elig_months_2019 ge 1; quit;


*COUNT OF MEMBERS IN RESULTS -- NOT USING THE 'UNKNOWNS' FOR YEAR-IN-PGM;
proc sql; select count(distinct guid) as members 
from BP_working_risk3_ORIG_DEFIN_upda where elig_months_2019 ge 1 and year_in_pgm ne ('unknown');
quit;


*****************************************************************************************;


*RISK COUNTS;

*BLOOD PRESSURE - NO INCREMENTAL;

*T1 PERIOD RISK SHOWN;
proc freq data=Bp_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Bp_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
quit;

*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Bp_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Bp_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;

