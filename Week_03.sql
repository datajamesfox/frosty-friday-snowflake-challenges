-- create external stage
create or replace stage week_3_stage
    url = 's3://frostyfridaychallenges/challenge_3/';

-- investigate files in external stage
list @week_3_stage;

-- investigate keywords.csv
select $1, $2, $3 from @week_3_stage/keywords.csv;

-- create file format

create or replace file format week_3_format
    type = "CSV",
    skip_header = 1;

-- create temp table for keywords
create or replace temporary table week_3_keywords
    (keyword varchar,
    added_by varchar,
    nonsense varchar);

-- load data into temp table
copy into week_3_keywords from @week_3_stage/keywords.csv
    file_format = week_3_format;

-- check loaded table
select * from week_3_keywords;

-- create temp table to load stage file metadata
create or replace temporary table week_3_files
    (filename varchar,
    number_of_rows int);
    
-- load meta data from stage - filename and number of rows
copy into week_3_files from (
    select metadata$filename, metadata$file_row_number from @week_3_stage
    );

-- final output for challenge
-- from week_3_files group the filename and obtain max number of rows minus 1 (to exclude header)
-- join week_3_keywords using contains to only keep filenames which contain keyword
create or replace table week_3_output as (
select filename, max(number_of_rows)-1 as number_of_rows
    from week_3_files
        join week_3_keywords
            on contains(filename, week_3_keywords.keyword)
    group by filename);

-- investigate output
select * from week_3_output;