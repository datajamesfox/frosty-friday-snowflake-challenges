-- SETUP

create or replace table home_sales (
sale_date date,
price number(11, 2)
);

insert into home_sales (sale_date, price) values
('2013-08-01'::date, 290000.00),
('2014-02-01'::date, 320000.00),
('2015-04-01'::date, 399999.99),
('2016-04-01'::date, 400000.00),
('2017-04-01'::date, 470000.00),
('2018-04-01'::date, 510000.00);


-- OUTPUT

create or replace function bucket_frosty(price number(11,2), bucket array)
    returns float
    language python
    runtime_version = 3.8
    handler = 'bucketer'
as
$$
def bucketer(price, bucket):
    for i in range(len(bucket)):
            if price <= bucket[i]:
                return i+1
            elif price >= max(bucket):
                return len(bucket)    
$$;

select 
    sale_date,
    price,
    bucket_frosty(price, [1, 310000, 400000, 500000]) as bucket_set_1,
    bucket_frosty(price, [210000, 350000]) as bucket_set_2,
    bucket_frosty(price, [250000, 290001, 320000, 360000, 410000, 470000]) as bucket_set_3
from home_sales;