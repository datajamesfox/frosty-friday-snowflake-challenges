-- Create file format
create or replace file format wk25
    type = json;

-- Create stage
create  or replace stage week_25_stage
    url = 's3://frostyfridaychallenges/challenge_25';
 
-- List stage
list @week_25_stage;

-- Investigate data
select $1 from @week_25_stage;

-- Create table
create  or replace table week_25_table (JSON variant);

-- Copy into table
copy into week_25_table from @week_25_stage
    file_format = wk25;

-- Output
select 
    date_trunc('day', t0.value:timestamp::datetime) as "DATE",
    array_agg(DISTINCT t0.value:icon::varchar) as icon_array,
    avg(t0.value:temperature::number(20,2)) as avg_temperature,
    sum(t0.value:precipitation::number(20,2)) as total_precipitation,
    avg(t0.value:wind_speed::number(20,2)) as avg_wind,
    avg(t0.value:relative_humidity::number(20,2)) as avg_humidity
from week_25_table,
    lateral flatten(input => JSON:weather) t0
group by "DATE"
order by "DATE" desc;