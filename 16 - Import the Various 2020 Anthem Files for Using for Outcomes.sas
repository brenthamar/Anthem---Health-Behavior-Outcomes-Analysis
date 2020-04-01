

*3,958,691 RECORDS IMPORTED;
PROC IMPORT OUT= WORK.anthem_eligibility_2020 
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20200124 - Anthem eligibility.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

***************************************************;
*MAKE A TABLE WITH JUST ONE RECORD FROM IMPORTED ELIGIBILITY TABLE, SO CAN USE TO GET DOB AND GENDER;
*OUTPUT TABLE HAS 1,831,638 RECORDS - DISTINCT MEMBERS;

proc sort nodupkey data=work.anthem_eligibility_2020 out=Anthem_eligibility_2020_unique;
by guid;
run;

proc sql;
select count(distinct guid)
from Anthem_eligibility_2020_unique; quit;

**************************************************;

*NOT SURE IF THIS ELIGIBILITY TABLE IS COMPLETE, I AM GOING TO SET THE PRIOR PULL AND THIS NEW PULL TOGETHER,
AND THEN 'NODUPKEY' IT, TO SEE IF THIS PROVIDES A MORE COMPLETE FILE;

Data anthem_eligibility_combined;
set anthem.Anthem_eligibility Anthem_eligibility_2020;
run;

*2,094,694 RECORDS PRODUCED - DISTINCT GUID/MEMBERS;
proc sort nodupkey data=anthem_eligibility_combined out=Anthem_elig_combined_2020_unique;
by guid;
run;

*******************************************************************************************************************;

*8,414,799 RECORDS IMPORTED;
PROC IMPORT OUT= WORK.ANTHEM_id_crosswalk_2020 
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20200124 - Guid to individualID walkthrough.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


*13,567,709 RECORDS; 
PROC IMPORT OUT= WORK.ANTHEM_wba_2020 
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20201224 - Anthem_ WBA_Responses_Guid.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


*4,760,002 RECORDS;
PROC IMPORT OUT= WORK.ANTHEM_realage_2020 
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20200124 - Anthem_RealAge.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


*376,734 RECORDS;
PROC IMPORT OUT= WORK.ANTHEM_labs_2020
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20200128 - Anthem Labs.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


*99,938 RECORDS;
PROC IMPORT OUT= WORK.Anthem_call_data_2020 
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20200128 - AnthemCall Data.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

****************************************************************************************************;


*RESULTS ARE NOT LOOKING GOOD, PULLS MAY BE PART OF THE PROBLEM;

*HERE IS A NEW PULL FOR THE LAB DATA - 3/3/2020;

*461,307 RECORDS PULLED;
PROC IMPORT OUT= WORK.ANTHEM_labs_2020_NEW
            DATAFILE= "O:\2019 RADS\Anthem Legacy Outcomes\1. Pulling Da
ta\2. Data\20200303 - Anthem Labs_new.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;




