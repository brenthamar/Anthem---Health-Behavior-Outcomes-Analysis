
*PULL WBA DATA FOR STRESS MEASURE FOR ANTHEM;


*WBA-MARITAL; *155,823 RECORDS;
proc sql;
create table MARITAL_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297230
;
quit;


*WBA-PERSONAL LOSS; *155,823 RECORDS;
proc sql;
create table PERLOSS_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297200
;
quit;


/*
THIS LIFE QUESTION NOT USED FOR STRESS RISK
*WBA-LIFE SATISFACTION 1; *155,823 RECORDS;
proc sql;
create table LIFE_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from ANTHEM.Anthem_wba
where asmnt_question_id = 6844296980
;
quit;
*/


*WBA-LIFE SATISFACTION 2; *155,823 RECORDS;
proc sql;
create table LIFE2_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297000
;
quit;



*WBA-PERCEPTION HEALTH; *155,822 RECORDS;
proc sql;
create table PERCEPT_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297340
;
quit;


*WBA-SLEEP; *155,823 RECORDS;
proc sql;
create table SLEEP_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297210
;
quit;

*WBA-SOCIAL TIES; *155,823 RECORDS;
proc sql;
create table SOCIAL_WBA as
select guid, asmnt_question_id, response_text, response_date,
       input(response_date, anydtdte24.) as response_date2 format=mmddyy10.,
	   year(calculated response_date2) as year
from Anthem_wba_2020
where asmnt_question_id = 6844297220
;
quit;



*******************************************************************;

*BRING ALL WBA QUESTIONS INTO ONE TABLE;	

proc sql;
create index guid on Marital_WBA(Guid);
create index guid on Perloss_WBA(guid);
create index guid on LIFE2_WBA(guid);
create index guid on Percept_WBA(guid);
create index guid on Sleep_WBA(guid);
create index guid on Social_WBA(guid);
create index guid on LIFE2_WBA(guid);
quit;




*168,001 RECORDS;
proc sql;
create table stress_wba_quest as 
select distinct a.Guid, a.response_date2, a.year,
       a.response_text as Marital_Status,
       b.response_text as Personal_Loss,
	   c.response_text as Life_Sat,
	   d.response_text as Percept_Health,
	   e.response_text as Sleep_Hrs,
	   f.response_text as Social
from Marital_WBA a, Perloss_WBA b, Life2_WBA c, 
     Percept_WBA d, Sleep_WBA e, Social_WBA f
where a.Guid = b.Guid
and a.Guid = c.Guid
and a.Guid = d.Guid
and a.Guid = e.Guid
and a.Guid = f.Guid
and a.response_date2 = b.response_date2
and a.response_date2 = c.response_date2
and a.response_date2 = d.response_date2
and a.response_date2 = e.response_date2
and a.response_date2 = f.response_date2
order by Guid, response_date2
;
quit;


*86,844 DISTINCT MEMBERS;
proc sql;
select count(distinct guid) as distinct_members
from stress_wba_quest
;
quit;

****************************************************************************;

*LOOK AT VALUES FOR THE WBA QUESTIONS;

proc freq data=stress_wba_quest;
table Marital_Status Personal_Loss Life_Sat Percept_Health Sleep_Hrs Social;
title 'WBA Responses for Questions Used in STRESS RISK';
quit;


****************************************************************************;


*RECODE QUESTIONS TO NUMERIC SCORES, TO BE USED IN PRODUCING THE COMPOSITE INDEX;
Data stress_wba_quest2;
set stress_wba_quest;


Marital_Status2 = .;
Personal_Loss2 = .;
Life_Sat2 = .;
Percept_Health2 = .;
Sleep_Hrs2 = .;
Social2 = .;

if Marital_Status = 'Divorced' then Marital_Status2 = 4;
else if Marital_Status = 'Domestic partner' then Marital_Status2 = 3;
else if Marital_Status = "Don't know" then Marital_Status2 = 2;
else if Marital_Status = 'Married' then Marital_Status2 = 1;
else if Marital_Status = 'Prefer not to answer' then Marital_Status2 = 2;
else if Marital_Status = 'Separated' then Marital_Status2 = 4;
else if Marital_Status = 'Single/Never been married' then Marital_Status2 = 2;
else if Marital_Status = 'Widowed' then Marital_Status2 = 5;
else Marital_Status2 = .;

if Personal_Loss = 'No' then Personal_Loss2 = 3;
else if Personal_Loss = 'Yes, one serious loss' then Personal_Loss2 = 6;
else if Personal_Loss = 'Yes, two or more serious' then Personal_Loss2 = 9;
else Personal_Loss2 = .;

if Life_Sat = 'Not satisfied' then Life_Sat2 = 9;
else if Life_Sat = 'Partly satisfied' then Life_Sat2 = 3;
else if Life_Sat = 'Mostly satisfied' then Life_Sat2 = 2;
else if Life_Sat = 'Completely satisfied' then Life_Sat2 = 1;
else Life_Sat2 = .;

if Percept_Health = 'Poor' then Percept_Health2 = 5;
else if Percept_Health = 'Fair' then Percept_Health2 = 3;
else if Percept_Health = 'Good' then Percept_Health2 = 2;
else if Percept_Health = 'Very Good' then Percept_Health2 = 1;
else if Percept_Health = 'Excellent' then Percept_Health2 = 1;
else Percept_Health2 = .;


if Sleep_Hrs = 'Less than 5 hours' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '5 hours' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '6 hours' then Sleep_Hrs2 = 4;
else if Sleep_Hrs = '7 hours' then Sleep_Hrs2 = 2;
else if Sleep_Hrs = '8 hours' then Sleep_Hrs2 = 2;
else if Sleep_Hrs = '9 or more' then Sleep_Hrs2 = 4;
else Sleep_Hrs2 = .;

if Social = 'Weaker than average' then Social2 = 8;
else if Social = 'About average' then Social2 = 5;
else if Social = 'Not sure' then Social2 = 5;
else if Social = 'Very strong' then Social2 = 2;
else Social2 = .;
run;


proc freq data=stress_wba_quest2;
table Marital_Status2 Personal_Loss2 Life_Sat2 Percept_Health2 Sleep_Hrs2 Social2;
run;


****************************************************************************;

*COMPOSITE SCORE FOR STRESS USING THE DEFINED 6 QUESTIONS;

Data stress_wba_quest3;
set stress_wba_quest2;

stress_composite_score = Marital_Status2 + Personal_Loss2 + Life_Sat2 + Percept_Health2 + Sleep_Hrs2 + Social2;

if Marital_Status2 =. or Personal_Loss2 =. or Life_Sat2 =. or Percept_Health2 =. 
or Sleep_Hrs2 =. or Social2 =. then stress_composite_score =.;
run;



*FINAL TABLE HERE HAS 168,001 ROWS;
proc sql;
create table x2 as
select distinct 'WBA' as Record_Type, guid, response_date2 as date, year, 
       Marital_Status, Personal_Loss, Life_Sat, Percept_Health, Sleep_Hrs, Social,
       Marital_Status2, Personal_Loss2, Life_Sat2, Percept_Health2, Sleep_Hrs2, Social2,
	   stress_composite_score
from stress_wba_quest3
;
quit;
