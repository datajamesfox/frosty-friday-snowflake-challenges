-- Create the table
create or replace table WEEK10_TABLE_JF
(
    date_time datetime,
    trans_amount double
);

-- Create the stage
create or replace stage week_10_frosty_stage_JF
    url = 's3://frostyfridaychallenges/challenge_10/'
    file_format = CSV;
    
-- Create the stored procedure
create or replace procedure dynamic_warehouse_data_load(stage_name varchar, table_name varchar)
    returns varchar
    language sql 
    execute as caller
as
$$
declare
    rows_loaded int default 0;
    row_load_iterator default 0;

begin

    -- Useful documentation https://docs.snowflake.com/en/developer-guide/snowflake-scripting/resultsets.html
    
    -- To get the size of each file we need to list the stage, then select the cols from the query
    execute immediate 'list @' || stage_name;
    
    -- When selecting the cols from the query we create a variable and storie the query as a resultset
    let stage_files resultset:= (select $1 as file, $2 as size from table(result_scan(LAST_QUERY_ID())));
    
    -- We declare a cursor on the resultset to get access to the data
    let stage_cursor cursor for stage_files;
   
    -- Use for statement to iterate through the rows of the cursor  
    for i in stage_cursor do
        
        -- Use conditional statement to use warehouse and copy 
        if (i.size > 10000) then
            execute immediate 'use warehouse FF_SMALL_WH';
        else 
            execute immediate 'use warehouse FF_XSMALL_WH';            
        end if;
        
        -- Execute the copy into command
        execute immediate 'copy into ' || table_name || ' from @' || stage_name || '/' || split_part(i.file, '/', -1);
        
        -- Declare a cursor as the table from the copy query
        let load_cursor cursor for (select "rows_loaded" from table(result_scan(LAST_QUERY_ID())));
        
        -- Open cursor of copy query, assign rows_loaded to row_load_iterator, cumulatively summarise rows_loaded each iteration
        open load_cursor;
        fetch load_cursor into row_load_iterator;
        rows_loaded:= rows_loaded + row_load_iterator;
        
    end for;  
   
    return rows_loaded || ' rows were added';
    
end;
$$
;

-- Call the stored procedure.
call dynamic_warehouse_data_load('WEEK_10_FROSTY_STAGE_JF', 'WEEK10_TABLE_JF');