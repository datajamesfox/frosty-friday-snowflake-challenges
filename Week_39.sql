-- Setup code
create or replace table customer_deets (
    id int,
    name string,
    email string
);

insert into customer_deets values
    (1, 'Jeff Jeffy', 'jeff.jeffy121@gmail.com'),
    (2, 'Kyle Knight', 'kyleisdabest@hotmail.com'),
    (3, 'Spring Hall', 'hall.yay@gmail.com'),
    (4, 'Dr Holly Ray', 'drdr@yahoo.com');

-- Create masking policy
create or replace masking policy email_mask as (email string) 
returns string ->
    CASE 
        WHEN contains(current_role(), 'SYSADMIN') then email
        ELSE REGEXP_REPLACE(email, '(.*)@', '****@')
    END;

-- Apply masking policy
alter table customer_deets modify column email set masking policy email_mask;
