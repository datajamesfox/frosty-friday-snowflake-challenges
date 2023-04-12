-- Create secure view using UUID
CREATE OR REPLACE SECURE VIEW secure_cities AS 
    (select 
        UUID_STRING() as id,
        city,
        district
    from week22);

-- Create row access policy that returns based on role and mod of id
create or replace row access policy row_cities as (id int)
returns boolean ->
    is_role_in_session('sysadmin')
    or (is_role_in_session('rep1') and id % 2 = 1)
    or (is_role_in_session('rep2') and id % 2 = 0);

-- Add rap to table underneath the secure view on the id column
alter table week22 add row access policy row_cities on (id);


----- OPTIONAL -----

-- Use masking policy to mask id
CREATE OR REPLACE MASKING POLICY id_mask AS (id int) RETURNS int ->
  CASE
    WHEN CURRENT_ROLE() = ('ACCOUNTADMIN') THEN id
    ELSE random(123)
  END;

ALTER view secure_cities MODIFY COLUMN id SET MASKING POLICY id_mask;