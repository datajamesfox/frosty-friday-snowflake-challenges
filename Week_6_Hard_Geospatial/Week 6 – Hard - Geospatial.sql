-- create file format
create or replace file format week_6_csv
    type = csv,
    skip_header = 1
    field_optionally_enclosed_by = '"';

-- create stage for files
create or replace stage week_6_stage
    file_format = week_6_csv;

-- In SnowlflakeSQL CLI:
 -- connect to account: snowsql -a <accountname>.<server> -u <email> --authenticator externalbrowser
 -- use <database>
 -- use <schema>
 -- use <warehouse>
 -- put file://<filepath>\<file name> @week_6_stage
 
list @week_6_stage;
 
select $1, $2, $3, $4, $5, $6 from @week_6_stage/nations_and_regions.csv.gz;
select $1, $2, $3, $4, $5 from @week_6_stage/nations_and_regions.csv.gz;

-- create raw data nation region table
create or replace temporary table week_6_nations_regions_raw
    (nation_or_region varchar,
     nation_region_type varchar,
     sequence_no int,
     longitude float,
     latitude float,
     part int
    );

-- create raw data constituency table
create or replace temporary table week_6_constituency_raw
    (nation_or_region varchar,
     sequence_no int,
     longitude float,
     latitude float,
     part int
    );

-- load data from stage to tables
copy into week_6_nations_regions_raw 
    from @week_6_stage/nations_and_regions.csv.gz;

copy into week_6_constituency_raw 
    from @week_6_stage/westminster_constituency_points.csv.gz;

-- confirm table load
select * from week_6_nations_regions_raw;
select * from week_6_constituency_raw;

-- Create collected polygons for each nation_or_region in the nation table 
-- 1. Aggregate long/lat coords into array. Concatenate POLYGON(()) string array to enable to_geography data conversion
-- 2. Use st_collect to collect polygons from each part for each nation
create or replace temporary table week_6_nation_polygon as (
with
    nation_polygon_parts as (
        select
            nation_or_region,
            part,    
            to_geography(
                'POLYGON((' ||
                    listagg(concat(longitude, ' ', latitude), ', ') within group (order by sequence_no)
                       || '))') as nation_parts      
        from week_6_nations_regions_raw
        group by nation_or_region, part),
    
    nation_polygon_whole as (
        select 
            nation_or_region,
            st_collect(nation_parts) as nat_poly
        from nation_polygon_parts
        group by nation_or_region)
    
select * from nation_polygon_whole);

-- As previous step but for constituency table
create or replace temporary table week_6_cons_polygon as (
with
    cons_polygon_parts as (
        select
            nation_or_region,
            part,    
            to_geography(
                'POLYGON((' ||
                    listagg(concat(longitude, ' ', latitude), ', ') within group (order by sequence_no)
                       || '))') as cons_parts      
        from week_6_constituency_raw
        group by nation_or_region, part),
    
    cons_polygon_whole as (
        select 
            nation_or_region,
            st_collect(cons_parts) as con_poly
        from cons_polygon_parts
        group by nation_or_region)
    
select * from cons_polygon_whole);

-- confirm tables are as expected
select * from week_6_nation_polygon;
select * from week_6_cons_polygon;

-- final output
-- cross join nat_poly and con_poly, then use st_intersects to provide TRUE/FALSE if the polygons intersect
-- ensure to filter out false values
select 
    n.nation_or_region,
    count(st_intersects(n.nat_poly, c.con_poly)) as intersecting_constituencies
from week_6_nation_polygon n
    cross join week_6_cons_polygon  c
where st_intersects(n.nat_poly, c.con_poly) = TRUE
group by n.nation_or_region
order by intersecting_constituencies desc;