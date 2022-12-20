-- create file format
create or replace file format w2_parquet
    type = 'parquet';

-- create stage
create or replace stage week_2_stage
    file_format = w2_parquet;
    
-- In SnowlflakeSQL CLI:
 -- connect to account: snowsql -a <accountname>.<server> -u <email> --authenticator externalbrowser
 -- use <database>
 -- use <schema>
 -- use <warehouse>
 -- put file://<filepath>\employees.parquet @week_2_stage

-- investigate the staged file data
select $1 from @week_2_stage;

-- create table
create or replace table week_2_table
    (city varchar,
     country varchar,
     country_code varchar,
     dept varchar,
     education varchar,
     email varchar,
     employee_id int,
     first_name varchar,
     job_title varchar,
     last_name varchar,
     payroll_iban varchar,
     postcode varchar,
     street_name varchar,
     street_num int,
     time_zone varchar,
     title varchar
    );

-- copy staged file into table
copy into week_2_table from @week_2_stage
    file_format = w2_parquet
    match_by_column_name = case_insensitive;
    
-- select table
select * from week_2_table;

-- create view to only see changed to DEPT and JOB_TITLE
create or replace view week_2_view
    as (select employee_id, dept, job_title from week_2_table);
    
-- select view
select * from week_2_view;

-- create stream that will only show us changes to the DEPT and JOB_TITLE columns. 
create or replace stream week_2_stream on view week_2_view;

-- execute following commands
UPDATE week_2_table SET COUNTRY = 'Japan' WHERE EMPLOYEE_ID = 8;
UPDATE week_2_table SET LAST_NAME = 'Forester' WHERE EMPLOYEE_ID = 22;
UPDATE week_2_table SET DEPT = 'Marketing' WHERE EMPLOYEE_ID = 25;
UPDATE week_2_table SET TITLE = 'Ms' WHERE EMPLOYEE_ID = 32;
UPDATE week_2_table SET JOB_TITLE = 'Senior Financial Analyst' WHERE EMPLOYEE_ID = 68;

-- select stream
select * from week_2_stream;