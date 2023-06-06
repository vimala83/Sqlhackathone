--1. Display any 10 random DM patients.

select * from "Patients" 
where "Group_ID" in(select "Group_ID" from "Group" where "Group"='DM')
order by random() limit 10

--2.please go through the below screenshot and creat the exact output

select CONCAT("Firstname", ' ', "Lastname") AS "full_name" from "Patients" 
where "Lastname" like 'Ma%';
	
--3.Write a query to get a list of patients whose RPE start is at moderate intensity.

Select p."Patient_ID",p."Firstname",p."Lastname"
from "Patients" p
join "Walking_Test" wt on p."WalkTest_ID"=wt."WalkTest_ID"
where wt."Gait_RPE_Start " Between 4 and 6

--4 Write a query by using common table expressions and case statements to display birthyear ranges.

with cts as
(
   select
      "Patient_ID",
      "Firstname",
      "Lastname",
      "Age",
      EXTRACT(YEAR FROM CURRENT_DATE) - "Age" AS "birth_year" 
   from
      "Patients"
)
select
   "Patient_ID",
   "Firstname",
   "Lastname",
   CASE
      When
         birth_year IS NOT NULL 
      THEN
         CONCAT(FLOOR(birth_year / 10)*10, '-', FLOOR(birth_year / 10)*10 + 9) 
      ELSE
         'unknown'
   END
   AS "Birth_Year_Range"
From
   cts;
	
--5) Display DM patient names with highest day MAP and night MAP (without using limit).

CREATE INDEX idx_patients ON public."Patients" ("Patient_ID", "Group_ID");
CREATE INDEX idx_blood_pressure ON public."Blood_Pressure" ("Patient_ID");
CREATE INDEX idx_group ON public."Group" ("Group");
WITH dm_patients AS (
  SELECT
    P."Firstname",
    P."Lastname",
    ((2 * BP."24Hr_Day_DBP") + BP."24Hr_Day_SBP") / 3 AS day_map,
    ((2 * BP."24Hr_Night_DBP") + BP."24Hr_Night_SBP") / 3 AS night_map,
    ROW_NUMBER() OVER (ORDER BY ((2 * BP."24Hr_Day_DBP") + BP."24Hr_Day_SBP") / 3 DESC) AS rn
  FROM public."Patients" P
  JOIN public."Blood_Pressure" BP ON BP."Patient_ID" = P."Patient_ID"
  JOIN public."Group" G ON G."Group_ID" = P."Group_ID"
  WHERE G."Group" LIKE '%DM%'
)
SELECT "Firstname", "Lastname", day_map, night_map
FROM dm_patients
WHERE rn = 1;

--6.Create view on table Lab Test by selecting some columns and filter data using Where condition.

create or replace view bc_test_result as
select "Lab_ID","Patient_ID","WBC","Platelets" from "Lab_Test" 
where "WBC" between 3 and 6

select * from bc_test_result

--7.Display a list of Patient IDs and their Group whose diabetes duration is greater than 10 years.

select "Patient_ID","Group" from "Patients" join "Group" on "Patients"."Group_ID"= "Group"."Group_ID"
where "Diabetes_Duration" > 10


--8. Write a query to list male patient ids 
--and their names 
--who are above 40 years of age and less than 60 years 
--and have Day BloodPressureSystolic above 120 and Day BloodPressureDiastolic above 80.

select p."Patient_ID","Firstname","Lastname","Age",g."Gender",bp."24Hr_Day_SBP",bp."24Hr_Day_DBP" from "Patients" as p
     			 join "Gender" as g on p."Gender_ID"=g."Gender_ID" 
				 join "Blood_Pressure" as bp on bp."BP_ID"=p."BP_ID"
				 where g."Gender"='Male'
				 and p."Age" between 40 and 60
				 and bp."24Hr_Day_SBP" > 120 and bp."24Hr_Day_DBP" >80
				 
	
--9 Use a function to calculate the percentage of patients according to the lab visited per month

CREATE OR REPLACE FUNCTION calculate_lab_visit_percentage()
RETURNS TABLE (month_name text, year integer, percentage numeric)
AS $$
DECLARE
  total_visits bigint;
BEGIN
  SELECT EXTRACT(YEAR FROM current_date) AS year, COUNT(DISTINCT "Patient_ID") AS total_visits
  INTO year, total_visits
  FROM public."Patients"
  GROUP BY year;
  FOR month_num IN 1..12
  LOOP
    SELECT TO_CHAR(DATE_TRUNC('MONTH', current_date) + (month_num - 1) * INTERVAL '1 MONTH', 'Month') AS month_name, year,
           (COUNT(DISTINCT "Patient_ID") * 100) / total_visits
    INTO month_name, year, percentage
    FROM public."Patients"
    WHERE EXTRACT(MONTH FROM "Visit_Date") = month_num
    GROUP BY month_name, year
    ORDER BY EXTRACT(MONTH FROM DATE_TRUNC('MONTH', current_date) + (month_num - 1) * INTERVAL '1 MONTH');
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

select * from calculate_lab_visit_percentage();

--10.Count of patients by first letter of firstname.

select left("Firstname",1) as firstletter, count(1) from "Patients" 
group by firstletter

--41 write a query to get the number of patients whose urine creatinine is in a normal range (Gender wise).

SELECT G."Gender", COUNT(P."Patient_ID") AS "Number of Patients"
FROM public."Patients" P
JOIN public."Gender" G ON G."Gender_ID" = P."Gender_ID"
JOIN public."Link_Reference" LR ON LR."Link_Reference_ID" = P."Link_Reference_ID"
JOIN public."Urine_Test" U ON U."Urine_ID" = LR."Urine_ID"
WHERE
  (G."Gender" = 'Male' AND U."Creatinine" BETWEEN 65.4 AND 119.3) OR
  (G."Gender" = 'Female' AND U."Creatinine" BETWEEN 52.2 AND 91.9)
GROUP BY G."Gender";


--42.Write a query to update id LB002 with the lab name Cultivate Lab

select * from "Lab_Visit"
where "Lab_visit_ID"='LB002'
update "lab_visit"
set "Lab_visit_ID"='LB002'
where "Lab_names"='Cultivate Lab'

select "Lab_names" from "Lab_Visit"
where "Lab_names"='Cultivate Lab' 

43.Create an index on any table and use explain analyze to show differences if any.

select "Patient_ID","Firstname","Lastname","Age" from "Patients"
create index "index_firstname" on "Patients"
(
"Firstname"
)

Explain select * from public."Patients"
where "Firstname"= 'Gabriel'

drop index "index_firstname"

--44.Write a query to split the lab visit date into two different columns lab_visit_date  and lab_visit_time.

select CAST ("Lab_Visit_Date" AS DATE) as lab_visit_date, CAST ("Lab_Visit_Date" AS TIME) as lab_visit_time from "Lab_Visit"

--45 Please go through the below screenshot and create the exact output. 

SELECT SUBSTRING("Patient_ID" FROM 2)::INTEGER AS "pat_id",
       CASE WHEN SUBSTRING("Patient_ID" FROM 2)::INTEGER % 2 = 0 THEN 'true' ELSE 'false' END AS "even",
       CASE WHEN SUBSTRING("Patient_ID" FROM 2)::INTEGER % 2 = 0 THEN 'false' ELSE 'true' END AS "odd"
FROM "Patients";

46 Calculate the Number of Diabetic Male and Female patients who are Anemic

SELECT G."Gender", COUNT(DISTINCT CASE
    WHEN (G."Gender" = 'Male' AND LT."Hgb" < 13.2)
        OR (G."Gender" = 'Female' AND LT."Hgb" < 11.6)
        THEN P."Patient_ID"
    END) AS anemic_count
FROM public."Patients" P
JOIN public."Gender" G ON G."Gender_ID" = P."Gender_ID"
JOIN public."Lab_Test" LT ON LT."Patient_ID" = P."Patient_ID"
WHERE P."Patient_ID" IN (
    SELECT "Patient_ID"
    FROM public."Patients"
    WHERE "Diabetes_Duration" > 0)
GROUP BY G."Gender";

--47. Write a query to display the Patient_ID, last name, and the position of the substring 'an' in the last name column for those patients who have a substring 'an'.

SELECT "Patient_ID", "Lastname",
POSITION ('an' IN "Lastname") AS "Position of 'an' in Last Name" FROM "Patients"
WHERE "Lastname" LIKE '%an%'
	
--48. List of patients from rows 30-40 without using the where condition.

select "Firstname","Lastname" from "Patients" 
limit 10 offset 37

--49. Write a query to find Average age for patients with high blood pressure
select avg("Age") from "Blood_Pressure"
		 join "Patients" as p on p."Patient_ID"="Blood_Pressure"."Patient_ID"
		 where "Blood_Pressure"."24Hr_Day_SBP" > 129 and "Blood_Pressure"."24Hr_Night_SBP" >129
		 and "Blood_Pressure"."24Hr_Day_DBP" >79 and "Blood_Pressure"."24Hr_Night_DBP" >79

--50.Create materialized view with no data, to display no of male and female patients.

CREATE MATERIALIZED VIEW Number_Of_Gender 
AS
select G."Gender",count(G."Gender") "No_Of_Gender" from
"Patients" P 
inner join "Gender" G on G."Gender_ID"=P."Gender_ID" 
group by  G."Gender"
WITH NO DATA;
