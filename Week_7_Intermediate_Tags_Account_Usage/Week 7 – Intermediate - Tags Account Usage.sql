-- Identify which objects have Level Super Secret A+++++++ Tag
with object_tags as (
    select 
        TAG_NAME,
        TAG_VALUE,
        OBJECT_ID
    from SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
    where TAG_VALUE = 'Level Super Secret A+++++++'),

-- Parse object and query IDs from access history
query_objects as (
    select 
        QUERY_ID,
        parse_json(BASE_OBJECTS_ACCESSED[0]):objectId as OBJECT_ID
    from SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY),

-- Obtain role names for each query id
query_roles as (
    select
        QUERY_ID,
        ROLE_NAME
    from "SNOWFLAKE"."ACCOUNT_USAGE"."QUERY_HISTORY"),

-- Join and aggregate tables to create final output
output_table as (
    select 
        object_tags.TAG_NAME,
        object_tags.TAG_VALUE,
        min(query_objects.QUERY_ID),
        SNOWFLAKE.ACCOUNT_USAGE.TABLES.TABLE_NAME,
        query_roles.ROLE_NAME
    from object_tags
        join query_objects 
            on object_tags.object_id = query_objects.object_id
        join query_roles
                on query_objects.query_id = query_roles.query_id
        join SNOWFLAKE.ACCOUNT_USAGE.TABLES
                on query_objects.object_id = SNOWFLAKE.ACCOUNT_USAGE.TABLES.TABLE_ID
    group by 
        object_tags.TAG_NAME, 
        object_tags.TAG_VALUE, 
        SNOWFLAKE.ACCOUNT_USAGE.TABLES.TABLE_NAME, 
        query_roles.ROLE_NAME)

select * from output_table;