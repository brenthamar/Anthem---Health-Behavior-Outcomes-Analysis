*PULL REALAGE DATA FOR STRESS FOR ANTHEM;


*REALAGE-MARITAL; *13,469 RECORDS;
proc sql;
create table MARITAL_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 18500
order by guid, from_date 
;
quit;


*REALAGE-PERSONAL LOSS; *13,766 RECORDS;
proc sql;
create table PER_LOSS_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 10060
order by guid, from_date 
;
quit;

/*
THIS LIFE QUESTION NOT USED FOR STRESS RISK
*REALAGE-LIFE SATISFACTION 1; *xx,xxx RECORDS;
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
*/

*REALAGE-LIFE SATISFACTION 2 - TO USE; 
*13,393 RECORDS;
proc sql;
create table LIFE2_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 20510
order by guid, from_date 
;
quit;

*REALAGE-PERCEPTI0N HEALTH; *13,682 RECORDS;
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


*REALAGE-SLEEP; *13,789 RECORDS;
proc sql;
create table SLEEP_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 10099
order by guid, from_date 
;
quit;


*REALAGE-SOCIAL; *13,357 RECORDS;
proc sql;
create table SOCIAL_RealAge as
select customer, guid, fact_id, fact_value,
       valid_from_date, valid_to_date, 
       input(valid_from_date, anydtdte24.) as from_date format=mmddyy10.,
	   year(calculated from_date) as year
from Anthem_realage_2020
where fact_id = 20511
order by guid, from_date 
;
quit;

*******************************************************************;


*BRING ALL REALAGE QUESTIONS INTO ONE TABLE;	

proc sql;
create index guid on Marital_realage(Guid);
create index guid on Per_loss_realage(guid);
create index guid on Life2_realage(guid);
create index guid on Percept_realage(guid);
create index guid on Sleep_realage(guid);
create index guid on Social_realage(guid);

quit;


*30,983 RECORDS;
proc sql;
create table stress_RA_quest as 
select distinct a.Guid, a.from_date, a.year,
       a.fact_value as Marital_Status,
       b.fact_value as Personal_Loss,
	   c.fact_value as Life_Sat,
	   d.fact_value as Percept_Health,
	   e.fact_value as Sleep_Hrs,
	   f.fact_value as Social
from Marital_realage a, Per_loss_realage b, Life2_realage c, 
     Percept_realage d, Sleep_realage e, Social_realage f
where a.Guid = b.Guid
and a.Guid = c.Guid
and a.Guid = d.Guid
and a.Guid = e.Guid
and a.Guid = f.Guid
and a.from_date = b.from_date
and a.from_date = c.from_date
and a.from_date = d.from_date
and a.from_date = e.from_date
and a.from_date = f.from_date
;
quit;

*11,779 DISTINCT MEMBERS;
proc sql;
select count(distinct guid) as distinct_members
from stress_RA_quest
;
quit;


proc sql;
create table aa_check as
select guid, count(*) as rec_count
from stress_RA_quest
group by guid
order by rec_count desc
;
quit;

****************************************************************************;

*LOOK AT VALUES FOR THE REALAGE QUESTIONS;

proc freq data=stress_RA_quest;
table Marital_Status Personal_Loss Life_Sat Percept_Health Sleep_Hrs Social;
title 'Realage Responses for Questions Used in STRESS RISK';
quit;

****************************************************************************;


*RECODE QUESTIONS TO NUMERIC SCORES, TO BE USED IN PRODUCING THE COMPOSITE INDEX;
Data stress_RA_quest2;
set stress_RA_quest;


Marital_Status2 = .;
Personal_Loss2 = .;
Life_Sat2 = .;
Percept_Health2 = .;
Sleep_Hrs2 = .;
Social2 = .;

if Marital_Status = 'divorced' then Marital_Status2 = 4;
else if Marital_Status = 'widowed' then Marital_Status2 = 5;
else if Marital_Status = 'married' then Marital_Status2 = 1;
else if Marital_Status = 'neverMarried' then Marital_Status2 = 2;
else Marital_Status2 = .;

if Personal_Loss = '0' then Personal_Loss2 = 3;
else if Personal_Loss = '1' then Personal_Loss2 = 6;
else if Personal_Loss = '2plus' then Personal_Loss2 = 9;
else Personal_Loss2 = .;

if Life_Sat = 'notSatisfied' then Life_Sat2 = 9;
else if Life_Sat = 'partly' then Life_Sat2 = 3;
else if Life_Sat = 'mostly' then Life_Sat2 = 2;
else if Life_Sat = 'completely' then Life_Sat2 = 1;
else Life_Sat2 = .;

if Percept_Health = 'poor' then Percept_Health2 = 5;
else if Percept_Health = 'fair' then Percept_Health2 = 3;
else if Percept_Health = 'good' then Percept_Health2 = 2;
else if Percept_Health = 'veryGood' then Percept_Health2 = 1;
else if Percept_Health = 'excellent' then Percept_Health2 = 1;
else Percept_Health2 = .;


if Sleep_Hrs = '4' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '5' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '6' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '7' then Sleep_Hrs2 = 2;
else if Sleep_Hrs = '8' then Sleep_Hrs2 = 2;
else if Sleep_Hrs = '9' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '9plus' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = 'lessThan4' then Sleep_Hrs2 = 4;
else Sleep_Hrs2 = .;

if Social = 'weakerAverage' then Social2 = 8;
else if Social = 'average' then Social2 = 5;
else if Social = 'notSure' then Social2 = 5;
else if Social = 'aboveAverage' then Social2 = 2;
else Social2 = .;

run;

proc freq data=stress_RA_quest2;
table Marital_Status2 Personal_Loss2 Life_Sat2 Percept_Health2 Sleep_Hrs2 Social2;
run;

****************************************************************************;

*COMPOSITE SCORE FOR STRESS USING THE DEFINED 6 QUESTIONS;

Data stress_RA_quest3;
set stress_RA_quest2;

stress_composite_score = Marital_Status2 + Personal_Loss2 + Life_Sat2 + Percept_Health2 + Sleep_Hrs2 + Social2;

if Marital_Status2 =. or Personal_Loss2 =. or Life_Sat2 =. or Percept_Health2 =. 
or Sleep_Hrs2 =. or Social2 =. then stress_composite_score =.;
run;

****************************************************************************;


*THIS CONFIRMS THAT THERE ARE REALAGE RECORDS IN 2020 YEAR, THESE HAVE TO BE DELETED OUT;
proc freq data=stress_RA_quest3;
table year;
run;

*17,663 RECORDS NOW LEFT IN THE TABLE;
Data stress_RA_quest4;
set stress_RA_quest3;

if year le 2019;
run;


*FINAL TABLE HERE HAS 17,663 ROWS
*CHECK ON TO MAKE SURE THAT THE FEW MEMBERS WHO SHOWED MORE THAN 1 FILE DOES NOT HOLD OVER WHEN RA & WBA ARE JOINED;
proc sql;
create table x1 as
select distinct 'RA ' as Record_Type, guid, from_date as date, year, 
       Marital_Status, Personal_Loss, Life_Sat, Percept_Health, Sleep_Hrs, Social,
       Marital_Status2, Personal_Loss2, Life_Sat2, Percept_Health2, Sleep_Hrs2, Social2,
	   stress_composite_score
from stress_RA_quest4
;
quit;
