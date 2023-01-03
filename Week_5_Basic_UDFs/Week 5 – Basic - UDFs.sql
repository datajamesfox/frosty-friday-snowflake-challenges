-- create table
create or replace table week_5_jf
    (x number);

-- insert data
insert into week_5_jf (x) values
    (1), 
    (2),
    (3),
    (4);

--confirm table as expected
select * from week_5_jf;


-- create python UDF
create or replace function timesthree_jf(x number)
    returns number
    language python
    runtime_version = '3.8'
    handler = 'timesthree_jf'
as
$$
def timesthree_jf(x):
    return x*3
$$;

-- execute python UDF
select timesthree_jf(x) from week_5_jf;