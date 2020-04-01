
*GETTING A COUNT OF DISTINCT MEMBERS, (WITH AT LEAST 1 MONTH ELIG IN 2019 YEAR), WHO ARE
REPRESENTED IN AT LEAST 1 OF THE 12 DIFFERENT RISK MEASURES IN THIS ANTHEM LEGACY OUTCOMES ANALYSIS;

proc sql;
select count(distinct guid) from anthem2.Totalchol_working_risk3_update where elig_months_2019 ge 1; quit;

**************************************************************************************************************;

*DISTINCT MEMBERS FROM THESE RISKS INITIALLY COMBINED, SINCE THE 'GUID' IS IN CHARACTER FORMAT;

*22,549 DISTINCT MEMBERS HERE;
proc sql;
create table anthem_member_count_temp1 as
select distinct guid from anthem2.Alc_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Activity_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Illness_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Stress_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Meds_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Life_working_risk3_dq_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Smoke_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Percept_working_risk3_update where elig_months_2019 ge 1
;
quit;


*I AM JUST CREATING THE SAME 'GUID' IDENTIFICAITON VARIABLE IN DIFFERENT FORMAT 
AND MAKING SURE LEADING/TRAILING BLANKS ARE CUT OUT;
Data anthem_member_count_temp1;
set anthem_member_count_temp1;

guid_num = input(Guid, 15.);
guid_char2 = compress(Guid);
run;


**************************************************************************************************************;


*THESE ARE THE BIOMETRIC RISKS, THE GUID IS IN NUMERIC FORMAT, SO I PUT THESE TOGETHER FIRST, THEN
I WILL CREATE A 'CHARACTER VARIBLE THAT CAN BE USED TO COMBINE WITH THE PERVIOUS 8 RISKS';

*12,146 DISTINCT MEMBERS HERE;
proc sql;
create table anthem_member_count_temp2 as
select distinct guid from anthem2.Bp_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Bmi_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Hdl_working_risk3_update where elig_months_2019 ge 1
UNION 
select distinct guid from anthem2.Totalchol_working_risk3_update where elig_months_2019 ge 1
;
quit;


Data anthem_member_count_temp2;
set anthem_member_count_temp2;

guid_char = (put(guid, 10.));
guid_char2 = compress(put(guid, 10.));
run;

*******************************************************************************************************************

*COMBINING THE 2 FILES TO GET A DISTINCT LIST OF MEMBERS IN ALL 12 RISKS IN THE ANALYSIS;

*THIS SHOWS 27,337 DISTINCT MEMBERS IN A FINAL LIST - HAVING RESULTS IN AT LEAST ONE OF THE RISK MEASURES;
proc sql;
create table anthem_results_member_list_final as
select distinct guid_num as guid from anthem_member_count_temp1
UNION
select distinct guid from anthem_member_count_temp2
order by guid
;
quit;

*27,337 DISTINCT MEMBERS;
proc sql;
select count(distinct guid) as distinct_members
from anthem_results_member_list_final
;
quit;
*******************************************************************************************************************;

*THIS SHOWS THE SAME 27,337 DISTINCT MEMBERS IN A FINAL LIST (AS SHOWN ABOVE);
*JUST USING THE 'CHARACTER' VARIABLE OF GUID TO COMBINE LISTS;

proc sql;
create table anthem_member_list_final_check as
select distinct guid_char2 from anthem_member_count_temp1
UNION
select distinct guid_char2 from anthem_member_count_temp2
order by guid_char2
;
quit;



*******************************************************************************************************************;
*******************************************************************************************************************;
*******************************************************************************************************************;

