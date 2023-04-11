-- Create file format
create or replace file format week_11_format
    type = csv
    skip_header = 1;

-- Create the stage that points at the data.
create or replace stage week_11_frosty_stage
    url = 's3://frostyfridaychallenges/challenge_11/'
    file_format = week_11_format;

-- Create the table as a CTAS (Create Table as Select) statement.
create or replace table week_11_jf as
select m.$1 as milking_datetime,
        m.$2 as cow_number,
        m.$3 as fat_percentage,
        m.$4 as farm_code,
        m.$5 as centrifuge_start_time,
        m.$6 as centrifuge_end_time,
        m.$7 as centrifuge_kwph,
        m.$8 as centrifuge_electricity_used,
        m.$9 as centrifuge_processing_time,
        m.$10 as task_used
from @week_11_frosty_stage (file_format => week_11_format, pattern => '.*milk_data.*[.]csv') m;
    
select * from week_11_jf;

-- TASK 1: Remove all the centrifuge dates and centrifuge kwph and replace them with NULLs WHERE fat = 3. 
-- Add note to task_used.
create or replace task whole_milk_updates
    schedule = '1400 minutes'
    warehouse = FF_XSMALL_WH
as
    update week_11_jf
        set centrifuge_start_time = null,
        centrifuge_end_time = null,
        centrifuge_kwph = null,
        task_used = SYSTEM$CURRENT_USER_TASK_NAME() || ' at ' || CURRENT_TIMESTAMP()
    where fat_percentage = 3;


-- TASK 2: Calculate centrifuge processing time (difference between start and end time) WHERE fat != 3. 
-- Add note to task_used.
create or replace task skim_milk_updates
    warehouse = FF_XSMALL_WH
    after whole_milk_updates
as
    update week_11_jf
        set centrifuge_processing_time = datediff('minute', centrifuge_start_time, centrifuge_end_time),
        centrifuge_electricity_used = round(datediff('minute', centrifuge_start_time, centrifuge_end_time)/60 * centrifuge_kwph, 2),
        task_used =  SYSTEM$CURRENT_USER_TASK_NAME() || ' at ' || CURRENT_TIMESTAMP()
    where fat_percentage != 3;

-- Show Tasks
show tasks;

-- Manually execute the task.
alter task skim_milk_updates resume;
execute task whole_milk_updates;

-- Check Task execution
select *
  from table(information_schema.task_history())
  order by scheduled_time desc;

-- Check that the data looks as it should.
select * from week_11_jf;

-- Check that the numbers are correct.
select task_used, count(*) as row_count from week_11_jf group by task_used;
  
-- Delete Tasks
drop task whole_milk_updates;
drop task skim_milk_updates;
show tasks;