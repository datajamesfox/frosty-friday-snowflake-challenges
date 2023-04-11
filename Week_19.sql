-- Create table for date dimension
create or replace table date_dimension_week_19
    (
     seq int,
     rowno int,
    "DATE" date,
    "YEAR" int,
     MON varchar,
     "MONTH" varchar,
     MONTHDAY int,
     WEEKDAY int,
     WEEKNO int,
     DAYNO int);

-- Create a temporary table to store the datediff between 2020-1-1 and today
-- This is enables use in the generator expression as a constant
create temporary table date_days(days int) as 
(select datediff('day', date('2020-1-1'), current_date()));

--  Create date dimension table and insert
insert into date_dimension_week_19
    (
     seq ,
     rowno ,   
    "DATE",
    "YEAR",
     MON,
     "MONTH",
     MONTHDAY,
     WEEKDAY,
     WEEKNO,
     DAYNO)
select 
    seq4() as seq,
    row_number() over (order by seq) as rowno,
    dateadd('day', seq, date('2020-1-1')) as "DATE",
    year("DATE") as "YEAR",
    monthname("DATE") as MON,
    to_char("DATE", 'MMMM') as "MONTH",
    date_part('mm', "DATE") as MONTHDAY,
    date_part('weekday', "DATE") as WEEKDAY,
    date_part('w', "DATE") as WEEKNO,
    date_part('yearday', "DATE") as DAYNO
from table(generator(rowcount => (select max(days) from date_days))) 
order by seq;

-- Investigate result 
select * from date_dimension_week_19;

-- Create UDF
create or replace function calculate_business_days(startdate varchar, enddate varchar, include boolean)
    returns int
    language sql
as
$$
    select 
        case
            when include = true then COUNT("DATE") + 1
            else COUNT("DATE")
        end
    from date_dimension_week_19
    where 
        "DATE" >= date(startdate) 
            and
        "DATE" < date(enddate)
$$;

-- Initial test
select calculate_business_days('2020-11-2', '2020-11-6' , true) as including, 
calculate_business_days('2020-11-2', '2020-11-6' , false) as excluding;

-- Testing data
create or replace table testing_data (
id INT,
start_date DATE,
end_date DATE
);
insert into testing_data (id, start_date, end_date) values (1, '11/11/2020', '9/3/2022');
insert into testing_data (id, start_date, end_date) values (2, '12/8/2020', '1/19/2022');
insert into testing_data (id, start_date, end_date) values (3, '12/24/2020', '1/15/2022');
insert into testing_data (id, start_date, end_date) values (4, '12/5/2020', '3/3/2022');
insert into testing_data (id, start_date, end_date) values (5, '12/24/2020', '6/20/2022');
insert into testing_data (id, start_date, end_date) values (6, '12/24/2020', '5/19/2022');
insert into testing_data (id, start_date, end_date) values (7, '12/31/2020', '5/6/2022');
insert into testing_data (id, start_date, end_date) values (8, '12/4/2020', '9/16/2022');
insert into testing_data (id, start_date, end_date) values (9, '11/27/2020', '4/14/2022');
insert into testing_data (id, start_date, end_date) values (10, '11/20/2020', '1/18/2022');
insert into testing_data (id, start_date, end_date) values (11, '12/1/2020', '3/31/2022');
insert into testing_data (id, start_date, end_date) values (12, '11/30/2020', '7/5/2022');
insert into testing_data (id, start_date, end_date) values (13, '11/28/2020', '6/19/2022');
insert into testing_data (id, start_date, end_date) values (14, '12/21/2020', '9/7/2022');
insert into testing_data (id, start_date, end_date) values (15, '12/13/2020', '8/15/2022');
insert into testing_data (id, start_date, end_date) values (16, '11/4/2020', '3/22/2022');
insert into testing_data (id, start_date, end_date) values (17, '12/24/2020', '8/29/2022');
insert into testing_data (id, start_date, end_date) values (18, '11/29/2020', '10/13/2022');
insert into testing_data (id, start_date, end_date) values (19, '12/10/2020', '7/31/2022');
insert into testing_data (id, start_date, end_date) values (20, '11/1/2020', '10/23/2021');

-- Output
select calculate_business_days(start_date, end_date , true) as including, 
calculate_business_days(start_date, end_date , false) as excluding
from testing_data;