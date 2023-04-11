/*
Frosty Friday
Week 20 - Hard - Stored Prodcedure
Challenge: Create a stored procedure that not only creates a clone of a schema, but replicates all the grants on that schema. This should be able to accept a custom ‘AT’ or ‘BEFORE’ statement written by the user.
Author: James Fox
*/

-- Relevant docs: https://docs.snowflake.com/en/user-guide/object-clone.html#access-control-privileges-for-cloned-objects
-- A cloned object does not retain any granted privileges on the source object, but does for child objects.
-- COPY GRANTS only works on objects that are tables

-- Setup use
use database frosty_friday;
use schema challenges;
use warehouse compute_wh;

-- Create roles
use role useradmin;
create or replace role frosty_role_one;
create or replace role frosty_role_two;
create or replace role frosty_role_three;

-- Create schema and table objects
use role sysadmin;
create or replace schema cold_lonely_schema;
create or replace table cold_lonely_schema.table_one (key int, value varchar);

-- Grant privilages
use role securityadmin;
grant all on schema frosty_friday.cold_lonely_schema to sysadmin;
grant all on table frosty_friday.cold_lonely_schema.table_one to sysadmin;
grant all on schema frosty_friday.cold_lonely_schema to frosty_role_one;
grant all on schema frosty_friday.cold_lonely_schema to frosty_role_two;
grant all on schema frosty_friday.cold_lonely_schema to frosty_role_three;
grant all on table frosty_friday.cold_lonely_schema.table_one to frosty_role_one;
grant all on table frosty_friday.cold_lonely_schema.table_one to frosty_role_two;
grant all on table frosty_friday.cold_lonely_schema.table_one to frosty_role_three;

show grants on schema cold_lonely_schema;
show grants on schema cold_lonely_schema;

-- Create Stored Procedure
use role sysadmin;
use database frosty_friday;
use schema challenges;
create or replace procedure schema_clone_with_copy_grants(
        database_name string, 
        schema_name string,
        target_database string,
        cloned_schema_name  string,
        at_or_before_statement  string)
    returns varchar not null
    language sql
    execute as caller
as
$$

begin
    
    execute immediate 'use role sysadmin';
    execute immediate 'use warehouse compute_wh';
    execute immediate 'use database ' || database_name;
    execute immediate 'use schema ' || schema_name;
    
    CASE when at_or_before_statement is null then 
        execute immediate 
            'create or replace schema ' || target_database || '.' || cloned_schema_name || ' clone ' || database_name || '.' || schema_name;
    ELSE 
        execute immediate
            'create or replace schema ' || target_database || '.' || cloned_schema_name || ' clone ' || database_name || '.' || schema_name || ' ' || at_or_before_statement;
    END;
    
    execute immediate 'show grants on schema ' || database_name || '.' || schema_name;

    let grant_rs resultset:= (
        select 
            $1 created_on, 
            $2 privilage,
            $3 granted_on,
            $4 name,
            $5 granted_to,
            $6 grantee_name,
            $7 grant_option,
            $8 granted_by
        from table(result_scan(LAST_QUERY_ID())));
    
    let grant_cursor cursor for grant_rs;
    
    for i in grant_cursor do
        execute immediate 'grant ' || i.privilage || ' on ' || i.granted_on || ' ' || cloned_schema_name || ' to role ' || i.grantee_name;
    end for; 
    
    return target_database || '.' || cloned_schema_name || ' succesfully cloned from ' || database_name || '.' || schema_name;
    
end;
$$
;

-- Call Stored Procedure
call schema_clone_with_copy_grants('frosty_friday', 
                               'cold_lonely_schema',
                               'frosty_friday',
                               'cold_lonely_clone', 
                               NULL);


-- Call Stored Procedure with offset
use schema challenges;
call schema_clone_with_copy_grants('frosty_friday', 
                               'cold_lonely_schema',
                               'frosty_friday',
                               'cold_lonely_clone_offset', 
                               'at(offset => -10)');

-- Query History
select *
from table(information_schema.query_history_by_session())
order by start_time desc;