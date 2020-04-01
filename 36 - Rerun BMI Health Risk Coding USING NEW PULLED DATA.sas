
*DEVELOP BMI RISK MEASURE FOR ANTHEM;
*RERUN IN MARCH 2020 USING NEW PULLED LAB DATA, THAT MAY BE MORE COMPLETE;


*ID THE NAMES TO USE, TO PULL OUT HEIGHT AND WEIGHT RECORDS;
proc freq data=ANTHEM3.ANTHEM_labs_2020_NEW;
table testname;
run;

**************************************************************************************************************;

*82,876 RECORDS PULLED - BODY HEIGHT AND BODY WEIGHT;
*RERUN - 83,849 RECORDS PULLED;
proc sql;
create table ANTHEM_HT_WT_records as
select distinct GUID, CustomerId, MemberUniqueId, TestName, TestResultValue,
       input(TestResultValue, 5.) as TestResultValue2, UnitOfMeasure,
       input(DateOfService, anydtdte24.) as DOS format=mmddyy10.,
	   year(calculated DOS) as year
from Anthem_labs_2020_new
where TestName = 'Body Height'
or TestName = 'Body Weight'
order by calculated DOS
;
quit;

*83,849 to 82,906 RECORDS;
Data ANTHEM_HT_WT_records;
set ANTHEM_HT_WT_records;

if year gt 2019 then delete;
run;


Data ANTHEM_HT_WT_records2 (keep=GUID DOS TestName TestResultValue2 year);
set ANTHEM_HT_WT_records;
run;

*THROW OUT DUPLICATES, RECORD COUNT, 82,906 TO 82,841;
proc sort nodupkey data=ANTHEM_HT_WT_records2 out=ANTHEM_HT_WT_records2_dedup;
by GUID DOS TestName year;
run;


*TRANSPOSE TABLE TO GET DATA INTO PROPER FORMAT;
proc transpose data=ANTHEM_HT_WT_records2_dedup out=ANTHEM_HTWT_dedup_trans;
by GUID DOS year;
id TestName;
var TestResultValue2;
run;



*PRODUCE BMI VALUE USING EQUATION;
Data ANTHEM_BMI_1;
set ANTHEM_HTWT_dedup_trans (drop = _name_);

BMI = (Body_Weight/(Body_Height*Body_Height))*703;

BMI2 = round(BMI,.1);

format BMI BMI2 4.1;
run;

****************************************************************************************;

*XXX RECORDS PULLED - HEIGHT AND WEIGHT;
proc sql;
create table ANTHEM_HT_WT_records_again as
select distinct GUID, CustomerId, MemberUniqueId, TestName, TestResultValue,
       input(TestResultValue, 5.) as TestResultValue2, UnitOfMeasure,
       input(DateOfService, anydtdte24.) as DOS format=mmddyy10.,
	   year(calculated DOS) as year
from Anthem_labs_2020_new
where TestName = 'Height'
or TestName = 'Weight'
order by calculated DOS
;
quit;

*14,765 to 6 RECORDS;
Data ANTHEM_HT_WT_records_again;
set ANTHEM_HT_WT_records_again;

if year gt 2019 then delete;
run;


Data ANTHEM_HT_WT_records_again2 (keep=GUID DOS TestName TestResultValue2 year);
set ANTHEM_HT_WT_records_again;
run;

*THROW OUT DUPLICATES, RECORD COUNT, 82,904 TO 82,839;
proc sort nodupkey data=ANTHEM_HT_WT_records_again2 out=ANTHEM_HT_WT_records_again2_d;
by GUID DOS TestName year;
run;


*TRANSPOSE TABLE TO GET DATA INTO PROPER FORMAT;
proc transpose data=ANTHEM_HT_WT_records_again2_d out=ANTHEM_HT_WT_records_again2_d_t;
by GUID DOS year;
id TestName;
var TestResultValue2;
run;



*PRODUCE BMI VALUE USING EQUATION;
Data ANTHEM_BMI_11 (rename =(Height=Body_Height Weight=Body_Weight));
set ANTHEM_HT_WT_records_again2_d_t (drop = _name_);

BMI = (Weight/(Height*Height))*703;

BMI2 = round(BMI,.1);

format BMI BMI2 4.1;
run;


****************************************************************************************;

*THIS PULLS OUT THE RECORDS WHERE BMI IS ALREADY CALCULATED AND AVAILABLE IN TABLE;
*30,003 RECORDS PULLED;
proc sql;
create table ANTHEM_BMI_2 as
select GUID, 
       input(DateOfService, anydtdte24.) as DOS format=mmddyy10.,
	   year(calculated DOS) as year,
       . as Body_Height,
	   . as Body_Weight,
	   input(TestResultValue, 4.1) as BMI,
	   input(TestResultValue, 4.1)  as BMI2
from ANTHEM_labs_2020_NEW
where TestName in ('BMI (Body Mass Index)','Body Mass Index (BMI)')
having year lt 2020
order by GUID, calculated DOS
;
quit;




*SET THE 2 TABLES TOGETHER;
Data ANTHEM_BMI_All;
set ANTHEM_BMI_1 Anthem_bmi_11 ANTHEM_BMI_2;

*SORT THE RECORDS, AND THROW OUT DUPLICATES;
proc sort nodupkey;
by guid DOS;
run;


***************************************************************;
*GET FIRST AND LAST BMI READINGS;

proc sort data=ANTHEM_BMI_All;
by GUID DOS;
run;

*21,966 RECORDS;
Data BMI_first;
set ANTHEM_BMI_All;
by guid;
if first.guid;
run;

*21,966 RECORDS;
Data BMI_last;
set ANTHEM_BMI_All;
by guid;
if last.guid;
run;

*12,833 RECORDS;
proc sql;
create table BMI_first_last as
select 	a.guid,
		a.DOS as Date_First,
		a.Year as Year_First,
		a.BMI2 as BMI_First,
		0 as Risk_First,
		b.DOS as Date_Last,
		b.Year as Year_Last,
		b.BMI2 as BMI_Last,
		0 as Risk_Last
from BMI_first a inner join BMI_last b
on a.guid = b.guid
where a.DOS <> b.DOS;
quit;


*DELETE RECORD IF YEAR_FIRST = YEAR_LAST;
*12,833 RECORDS TO 12,758 RECORDS;
Data BMI_first_last;
set BMI_first_last;

if Year_First = Year_Last then delete;
run;


*****************************************************************;

*12,758 DISTINCT MEMBERS;
proc sql;
select count(distinct guid) as member_count
from BMI_first_last
;
quit;

*RECORDS ARE FROM 2015 TO 2019;
proc freq data=BMI_first_last;
table Year_first Year_last;
run;

*****************************************************************;

*BRING IN DOB AND GENDER INTO TABLE FROM ELIGIBILITY TABLE;

*TABLE WITH *12,758 12,756 RECORDS;
Proc sql;
create table BMI_First_Last_Final as
select distinct a.Guid, b.DOB, 'BMI' as item,
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
  when BMI_Last lt BMI_First then 'decreased'
  when BMI_Last gt BMI_First then 'increased' 
  when BMI_Last = BMI_First then 'no change'
  else 'unknown'
  end as change_in_BMI, a.*
from BMI_first_last a inner join Anthem_elig_combined_2020_unique b
on a.Guid = b.Guid;
quit;


proc freq data=BMI_First_Last_Final;
table year_in_pgm;
run;

*****************************************************************;


*SET RISK FLAGS, BASED ON FIRST AND LAST SYSTOLIC/DIASTOLIC READINGS;

Data BMI_working_risk1; 
set BMI_First_Last_Final;

*THIS PRODUCES NEW VALUE VARIABLES, BECAUSE HAVE TO SET VERY HIGH VALUES TO A MAXIMUM DEFINED VALUE;
BMI_First2 = BMI_First;
BMI_Last2 = BMI_Last;

*THIS SETS THE RISK FLAGS IN EACH TIME PERIOD, BASED ON THE REFERENCE RULE BEING USED;
if Gender2 = 'Female' then DO;
if BMI_First > 27.2 then Risk_First = 1;
if BMI_Last > 27.2 then Risk_Last = 1;
END;

if Gender2 = 'Male' then DO;
if BMI_First > 27.7 then Risk_First = 1;
if BMI_Last > 27.7 then Risk_Last = 1;
END;


*THIS SETS THE VERY HIGH BMI VALUES TO MAXIMUM DEFINED VALUE, AS NOTED IN IN THE METHODOLOGY DOCUMENT;
if BMI_First2 gt 45 then BMI_First2 = 45;
if BMI_Last2 gt 45 then BMI_Last2 = 45;

run;


proc freq data=BMI_working_risk1;
table Risk_First Risk_Last;
title 'Comparison of BMI Risk Flags from First and Last Reading';
run;


*****************************************************************;


*THIS STEP DEVELOPS A NEEDED MULTIPLICATON TERM TO USE FOR MEMBERS WHO REDUCE OR ELIMINATE BMI RISK REDUCING NUMBER OF DRINKS;
Data BMI_working_risk2(keep=guid gender2 BMI_First BMI_Last BMI_First2 BMI_Last2 Risk_First Risk_Last BMI_Value_per_Risk Impact1 Risk_Last_Updated
                            agegroup year_first year_last year_in_pgm item change_in_BMI BMI_First2 BMI_Last2);
set BMI_working_risk1;

BMI_Value_per_Risk = 203.0;

Impact1 = 0;



*THIS CODE LINE ACCOUNTS FOR MEMBERS WHO ELIMINATE BMI RISK; 
If Risk_First = 1 and Risk_Last = 0 then Impact1 = 1.0;

*THIS LINE BELOW TAKES CARE OF MEMBERS WITH NO RISK INITIALLY, AND THEN DEVELOP BMI RISK;
If Risk_First = 0 and Risk_Last = 1 then Impact1 = -1.0;


*THIS IS CODE THAT WORKS TO CALCULATE THE INCREMENTAL RISK THAT WE WILL USE ATTRIBUTE SAVINGS OR FURTHER EXPENSE
TO THOSE MEMBERS WHO STAY AT RISK AT T1 AND T2;

*FOR FEMALES;
*DECREASED RISK - BMI GONE DOWN;
if Gender2 = 'Female' and Risk_First = 1 and Risk_Last = 1 and change_in_BMI = 'decreased' then DO;
Impact1 = (BMI_First2 - BMI_Last2) / (BMI_First2 - 27.2);
Risk_Last_Updated = (1 - Impact1);
END;

*INCREASED RISK - BMI GONE UP;
if Gender2 = 'Female' and Risk_First = 1 and Risk_Last = 1 and change_in_BMI = 'increased' then DO;
Impact1 = (BMI_First2 - BMI_Last2) / (45.0 - BMI_First2);
Risk_Last_Updated = (1 - Impact1);
END;


*FOR MALES;
*DECREASED RISK - BMI GONE DOWN;
if Gender2 = 'Male' and Risk_First = 1 and Risk_Last = 1 and change_in_BMI = 'decreased' then DO;
Impact1 = (BMI_First2 - BMI_Last2) / (BMI_First2 - 27.7);
Risk_Last_Updated = (1 - Impact1);
END;

*INCREASED RISK - BMI GONE UP;
if Gender2 = 'Male' and Risk_First = 1 and Risk_Last = 1 and change_in_BMI = 'increased' then DO;
Impact1 = (BMI_First2 - BMI_Last2) / (45.0 - BMI_First2);
Risk_Last_Updated = (1 - Impact1);
END;


format BMI_Value_per_Risk DOLLAR10.2;
format Impact1 Risk_Last_Updated 6.3;

run;


****************************************************************;

*THIS ADDED STEP CONNECTS TO PAWEL'S SIMM RISK VALUE COST TABLE, AND ADDS THE RESPECTIVE VALUE OF SIMM RISK
INTO MY SUMMARY TABLE, BASED ON THE YEAR OF MEMBER AND THEIR AGEGROUP;

proc sql;
create table BMI_working_risk2_b as 
select a.*, b.cost as SIMM_value_risk
from BMI_working_risk2 a left join Shbp_sim_costs_trans_final b
on a.item = b.measured_risks
and a.year_in_pgm = b.Year
and a.agegroup = b.agegroup
;
quit;



*****************************************************************;

*THIS STEP PRODUCES THE DOLLAR AMOUNT ASSOCIATED WITH THE REDUCTION (OR GAIN) IN TOTAL CHOLESTEROL RISK;
Data BMI_working_risk3;
set BMI_working_risk2_b;


*if Impact1 gt 0 then DO;
BMI_Impact_Savings = Impact1*BMI_Value_per_Risk;
*END;

*THIS IS THE NEW IMPACT SAVINGS, BASED ON THE SIMM COST FROM PAWEL TABLE;
BMI_Impact_Savings2 = Impact1*SIMM_value_risk;



format BMI_Impact_Savings BMI_Impact_Savings2 DOLLAR10.2;
run;

*************************************************************;

*FINANCIAL RESULTS ASSOCATIED WITH CHANGE IN TOTAL CHOLESTEROL;

proc freq data=BMI_working_risk3;
table BMI_Impact_Savings BMI_Impact_Savings2;
title 'ANTHEM - Frequency of BMI Impact'; 
run;

proc means sum data=BMI_working_risk3;
var BMI_Impact_Savings BMI_Impact_Savings2;
title 'Final Result for ANTHEM BMI Analysis';
run;


*************************************************************************************************;

*BMI RISK FINANCIAL RESULTS WHEN LIMITING TO MEMBERS WITH ELIG IN 2019;


*BMI;

Data BMI_working_risk3_update;
set BMI_working_risk3;

elig_months_2019 = 0;
run;


proc sql;
create index Guid on BMI_working_risk3_update(Guid);
create index Guid on Angie_anthem_2019_mm_new2(Guid);
quit;


*12,100 RECORDS WERE UPDATED WITH A COUNT OF 2019 ELIG MONTHS;
proc sql;
update BMI_working_risk3_update a
set elig_months_2019 = (select max(months_eligible)
                        from Angie_anthem_2019_mm_new2 b
						where a.Guid = b.Guid)
where exists (select 'x' 
              from Angie_anthem_2019_mm_new2 b
			  where a.Guid = b.Guid)
; 
quit;

*BMI - ORIGINAL RESULT;
proc sql;
title 'Final Result for ANTHEM BMI Analysis';
select sum(BMI_Impact_Savings2) as BMI_savings format=dollar15.2
from BMI_working_risk3_update
;
quit;


*NEW RESULT - TAKING TO ACCOUNT THAT MEMBER SHOWS ELIG MONTHS IN 2019 YEAR;
proc sql;
title 'Final Result for ANTHEM BMI Analysis';
select sum(BMI_Impact_Savings2) as BMI_savings format=dollar15.2
from BMI_working_risk3_update
where elig_months_2019 ge 1
;
quit;


*COUNT OF MEMBERS IN RESULTS;
proc sql; select count(distinct guid) as members 
from BMI_working_risk3_update where elig_months_2019 ge 1; quit;


*COUNT OF MEMBERS IN RESULTS -- NOT USING THE 'UNKNOWNS' FOR YEAR-IN-PGM;
proc sql; select count(distinct guid) as members 
from BMI_working_risk3_update where elig_months_2019 ge 1 and year_in_pgm ne ('unknown');
quit;


*****************************************************************************************;

*RISK COUNTS FOR BMI OUTCOME;

*BMI - HAS INCREMENTAL;

*T1 PERIOD RISK SHOWN;
proc freq data=Bmi_working_risk3_update;
table risk_first;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;

*RISK IN T1, AND NO RISK T2;
proc sql;
select count(distinct Guid)
from Bmi_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
quit;

*NO RISK IN T1, AND HAVE RISK AT T2;
proc sql;
select count(distinct Guid)
from Bmi_working_risk3_update
where risk_first = 0
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
quit;


*GET STARTING RISK, RISK MITIGATED, AND NEW ADOPTED RISK;
proc freq data=Bmi_working_risk3_update;
table Risk_First*Risk_Last;
WHERE elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
run;

*RISK AT T1 AND T2, RISK HAS IMPROVED;
proc sql;
select count(distinct Guid)
from Bmi_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
;
quit;


*RISK AT T1 AND T2, RISK HAS WORSENED;
proc sql;
select count(distinct Guid)
from Bmi_working_risk3_update
where impact1 lt 0
and impact1 ne .
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 and year_in_pgm ne ('unknown');
;
quit;
