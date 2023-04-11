use role sysadmin;
use database frosty_friday;
use schema challenges;
use warehouse compute_wh;

-- Create sequence and table 
create or replace sequence seq_plus_one
   start = 1
   increment = 1
   ;

create or replace table week26_table (
    row_id int default seq_plus_one.nextval,
    timestamp datetime
    );

-- Create email error integration
create notification integration week26email
    type=email
    enabled=true
    allowed_recipients=('<email@domain>');

-- Create timestamp insert task
create or replace task week26task
    schedule = '5 minute'
    warehouse = compute_wh
as
    insert into week26_table (timestamp) values
        (current_timestamp());
    
-- Create email task
use role accountadmin;
create or replace task week26email
    warehouse = compute_wh
    after week26task
as
    CALL SYSTEM$SEND_EMAIL(
        'week26email',
        '<email@domain>',
        'Frosty Friday week 26 task',
        'Task has successfully finished on ' || current_account() || ' which is deployed on ' || current_region() || ' region at ' || current_timestamp()
    );
 
-- Grant useage on email 
grant usage on integration week26email to role sysadmin;

-- Check tasks and resume email
use role sysadmin;
show tasks;
alter task WEEK26EMAIL resume; 

-- Execute initial task
execute task week26task;

-- Confirm successful run
select *
  from table(information_schema.task_history())
  order by scheduled_time desc;
  
select * from week26_table;

-- Suspend tasks
alter task WEEK26TASK suspend; 
alter task WEEK26EMAIL suspend; 
show tasks;

-- Drop tasks
drop task WEEK26TASK; 
drop task WEEK26EMAIL;
show tasks;