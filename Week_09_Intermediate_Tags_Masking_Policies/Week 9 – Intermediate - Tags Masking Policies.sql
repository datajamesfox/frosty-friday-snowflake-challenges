-- (OPTIONAL) Ensure role grants correctly setup prior to challenge
use role securityadmin;
show grants on database frosty_friday;
show grants on schema frosty_friday.challenges;
show grants on table frosty_friday.challenges.data_to_be_masked;
revoke all privileges on database frosty_friday from role <rolename>;
revoke all privileges on schema challenges from role <rolename>;
revoke all privileges on table data_to_be_masked from role <rolename>;
grant ownership on database frosty_friday to role <rolename>;
grant ownership on schema challenges to role <rolename>;
grant ownership on table data_to_be_masked to role <rolename>;

--CREATE DATA
use role sysadmin;
CREATE OR REPLACE TABLE data_to_be_masked(first_name varchar, last_name varchar,hero_name varchar);
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Eveleen', 'Danzelman','The Quiet Antman');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Harlie', 'Filipowicz','The Yellow Vulture');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Mozes', 'McWhin','The Broken Shaman');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Horatio', 'Hamshere','The Quiet Charmer');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Julianna', 'Pellington','Professor Ancient Spectacle');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Grenville', 'Southouse','Fire Wonder');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Analise', 'Beards','Purple Fighter');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Darnell', 'Bims','Mister Majestic Mothman');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Micky', 'Shillan','Switcher');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Ware', 'Ledstone','Optimo');

-- Ensure table is correct
select * from data_to_be_masked;

--CREATE ROLE
use role securityadmin;
CREATE ROLE foo1;
CREATE ROLE foo2;
GRANT ROLE foo1 TO USER jamesfox;
GRANT ROLE foo2 TO USER jamesfox;
grant usage on database frosty_friday to role foo1;
grant usage on schema challenges to role foo1;
grant select on all tables in database frosty_friday to role foo1;
grant usage, operate on warehouse compute_wh to role foo1;

grant usage on database frosty_friday to role foo2;
grant usage on schema challenges to role foo2;
grant select on all tables in database frosty_friday to role foo2;
grant usage, operate on warehouse compute_wh to role foo2;


-- Create tag admin role
use role securityadmin;
create role tag_admin;
use role accountadmin;
grant role tag_admin to user jamesfox;

-- Create masking admin role
use role securityadmin;
create role masking_admin;
use role accountadmin;
grant role masking_admin to user jamesfox;

-- Grant tag_admin required privilages
use role securityadmin;
grant usage, operate on warehouse compute_wh to role tag_admin;
grant usage on database frosty_friday to role tag_admin;
grant usage on schema challenges to role tag_admin;
grant create tag on schema challenges to role tag_admin;
grant apply tag on account to role tag_admin;

-- Grant masking_admin required privilages
use role securityadmin;
grant usage, operate on warehouse compute_wh to role masking_admin;
grant usage on database frosty_friday to role masking_admin;
grant usage on schema challenges to role masking_admin;
grant create masking policy on schema frosty_friday.challenges to role masking_admin;
grant apply masking policy on account to role masking_admin;

-- Using tag_admin create and apply tag to first_name and last_name
use role tag_admin;
use database frosty_friday;
use schema challenges;
create tag masking_sensitivity;
alter table data_to_be_masked modify column first_name set tag masking_sensitivity = '1';
alter table data_to_be_masked modify column last_name set tag masking_sensitivity = '2';

-- Confirm tags are applied correctly
use role tag_admin;
show tags in schema challenges;
select system$get_tag('masking_sensitivity', 'data_to_be_masked.first_name', 'column');
select system$get_tag('masking_sensitivity', 'data_to_be_masked.last_name', 'column');
select system$get_tag('masking_sensitivity', 'data_to_be_masked.hero_name', 'column');

-- Apply tags to foo1 and foo2 and confirm changes
use role tag_admin;
alter role foo1 set tag masking_sensitivity = '1';
alter role foo2 set tag masking_sensitivity = '2';
select system$get_tag('masking_sensitivity', 'foo1', 'role');
select system$get_tag('masking_sensitivity', 'foo2', 'role');

-- Create masking policy
use role masking_admin;
create or replace masking policy hero_masks as 
(val string) returns string ->
    case
        when to_number(system$get_tag_on_current_column('masking_sensitivity')) <= to_number(system$get_tag('MASKING_SENSITIVITY', current_role(), 'role'))  then val
        else '******'
    end;
 
 -- Apply masking policy to table
alter tag masking_sensitivity set masking policy hero_masks;
alter tag masking_sensitivity unset masking policy hero_masks;

-- Test Output
use role accountadmin;
use warehouse compute_wh;
select * from data_to_be_masked;

use role foo1;
use warehouse compute_wh;
select * from data_to_be_masked;

use role foo2;
use warehouse compute_wh;
select *from data_to_be_masked;