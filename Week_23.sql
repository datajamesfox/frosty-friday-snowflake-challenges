-- Create file format
create or replace file format w23_csv
    type = 'csv'
    skip_header = 1
    field_optionally_enclosed_by = '"'; 

-- Create stage
create or replace stage week_23_stage
    file_format = w23_csv; 
    
-- Create table
create or replace table week_23 (
    id varchar,
    first_name varchar,
    last_name varchar,
    email varchar,
    gender varchar,
    ip_address varchar);

-- In SnowlflakeSQL CLI:
 -- connect to account: snowsql -a <accountname>.<server> -u <email> --authenticator externalbrowser
    -- (--authenticator param is added due to SSO)
 -- use <database>
 -- use <schema>
 -- use <warehouse>
 -- put file://<filepath>\data_batch_*1.csv' @week_23_stage;

-- List stage
list @week_23_stage;

-- Copy into table 
copy into week_23 from @week_23_stage
    on_error = skip_file;

-- Output
select * from week_23
    order by to_number(id);