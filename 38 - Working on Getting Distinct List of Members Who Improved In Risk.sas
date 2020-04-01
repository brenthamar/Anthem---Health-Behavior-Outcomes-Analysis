

*GET A TABLE OF DISTINCT MEMBERS WHO SHOW IMPROVEMENT IN AT LEAST 1 OF THE 12 DIFFERENT BEHAVIOR OUTCOMES;

proc sql;
create table a_alc_risk_improved as
select distinct guid
from Alc_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select distinct guid
from Alc_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
;
quit;



proc sql;
create table a_bp_risk_improved as
select put(guid, 15.) as guid
from Bp_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
;
quit;


proc sql;
create table a_alc_bp as
select input(guid, 15.) as guid
from Alc_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select input(guid, 15.) as guid
from Alc_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION 
select guid
from Bp_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
;
quit;


*WHEN USING DIFFERENT STRESS DEFIN FROM SHBP - 15,464 TOTAL DISTINCT MEMBERS WHEN USING ALL 12 BEHAVIOR OUTCOMES;

*UPDATE TABLE HAS 13,427 DISTINCT MEMBERS - THESE MEMBERS SHOWED RISK IMPROVEMENT IN AT LEAST 1 OF THE 12 DIFFERENT BEHAVIOR OUTCOMES;
proc sql;
create table a_all_12_outcomes_update as
select input(guid, 15.) as guid
from Alc_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select input(guid, 15.) as guid
from Alc_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION 
select guid
from Bp_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select guid
from Bmi_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select guid
from Bmi_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION
select guid
from Hdl_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Illness_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Life_working_risk3_dq_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select input(guid, 15.) as guid
from Life_working_risk3_dq_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Meds_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Percept_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select input(guid, 15.) as guid
from Percept_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION 
select input(guid, 15.) as guid
from Activity_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0  
UNION
select input(guid, 15.) as guid
from Stress_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select input(guid, 15.) as guid
from Stress_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Smoke_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select Guid
from Totalchol_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select Guid
from Totalchol_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
;
quit;


proc sql;
select count(distinct guid)
from a_all_12_outcomes_update
;
quit;


**********************************************************************************************************;
**********************************************************************************************************;

*I HAVE CHANGED BP RISK DEFINITION AND NOW HAVE RE-RUN QUERY TO GET DISTINCT LIST OF MEMBERS SHOWING 
IMPROVMENT IN AT LEAST 1 OF THE 12 DIFFERENT HEALTH BEHAVIOR MEASURES;

*UPDATE TABLE HAS *13,916 DISTINCT MEMBERS;
proc sql;
create table a_all_12_outcomes_up_bp_change as
select input(guid, 15.) as guid
from Alc_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select input(guid, 15.) as guid
from Alc_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION 
select guid
from Bp_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select guid
from Bmi_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select guid
from Bmi_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION
select guid
from Hdl_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Illness_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Life_working_risk3_dq_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select input(guid, 15.) as guid
from Life_working_risk3_dq_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Meds_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Percept_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select input(guid, 15.) as guid
from Percept_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION 
select input(guid, 15.) as guid
from Activity_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0  
UNION
select input(guid, 15.) as guid
from Stress_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION 
select input(guid, 15.) as guid
from Stress_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
UNION
select input(guid, 15.) as guid
from Smoke_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select Guid
from Totalchol_working_risk3_update
where risk_first = 1
and risk_last = 0
AND elig_months_2019 gt 0
UNION
select Guid
from Totalchol_working_risk3_update
where impact1 > 0
and risk_first = 1
and risk_last = 1
AND elig_months_2019 gt 0 
;
quit;

*13,916 DISTINCT MEMBERS -- USING THE NEW BP RISK DEFINITION;
proc sql;
select count(distinct guid)
from a_all_12_outcomes_up_bp_change
;
quit;

