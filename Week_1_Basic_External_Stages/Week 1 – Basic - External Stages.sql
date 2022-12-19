-- create/use database
-- create/use schema
-- create/use warehouse

-- create external stage
create stage week_1_stage
    url = 's3://frostyfridaychallenges/challenge_1/';

-- check files in external stage
list @week_1_stage;

-- investigate file contents
select $1, $2 from @week_1_stage;

-- create table
create table week_1_table
    (col1 varchar);

-- copy into table
copy into week_1_table from @week_1_stage;

--select table
select * from week_1_table;