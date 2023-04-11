alter session set GEOGRAPHY_OUTPUT_FORMAT='WKT';

// Identify Center Nodes

create or replace temporary table week17db.solution.center_nodes as (
select 
    id, 
    coordinates, 
    addr_city
from openstreetmap_new_york.new_york.v_osm_ny_shop_electronics
where addr_city = 'Brooklyn');

// Identify all other nodes

create or replace temporary table week17db.solution.all_nodes_no_centers as (
select 
    id, 
    coordinates, 
    addr_city
from openstreetmap_new_york.new_york.v_osm_ny_shop_electronics);

// Filter only other nodes that are within 750 of center nodes

create or replace temporary table week17db.solution.distance_calcs as (
select 
    c.id, 
    c.coordinates as center_coords,
    o.id as id_2, 
    o.coordinates as other_coords,
    st_distance(center_coords, other_coords) as dist,
    st_dwithin(center_coords, other_coords, 750) as within_750m
from center_nodes c
cross join all_nodes_no_centers o
where within_750m = TRUE
    and c.id != id_2);

// Identify center nodes with >= 3 other nodes within 750m

create or replace temporary table week17db.solution.groupings as (
select
    id,
    count(*) as cnt
from distance_calcs
group by id
having cnt >= 3);

select 
    c.id,
    coordinates as center_coords,
    c.id as id_2,
    coordinates as other_coords
    from center_nodes c
inner join groupings g on c.id = g.id;

// Join groupings to distances calcs to only keep nodes within 750 m
// Union center_nodes to enable st_collect on other_coords column

create or replace temporary table week17db.solution.geo_coords as (
select 
    id,
    st_collect(other_coords) geo_coords
from 
    (select 
        g.id,
        center_coords,
        id_2,
        other_coords
    from distance_calcs d
    inner join groupings g on d.id = g.id
    union
    select 
        c.id,
        coordinates as center_coords,
        c.id as id_2,
        coordinates as other_coords
        from center_nodes c
    inner join groupings g on c.id = g.id) sq
group by sq.id);

// Aggregate coords and make multipolygon string

select 
        replace('MULTIPOLYGON('||listagg('(('||ST_XMIN(geo_coords)||' '||ST_YMIN(geo_coords)||','
        ||ST_XMIN(geo_coords)||' '||ST_YMAX(geo_coords)||','
        ||ST_XMAX(geo_coords)||' '||ST_YMAX(geo_coords)||','
        ||ST_XMAX(geo_coords)||' '||ST_YMIN(geo_coords)||','
        ||ST_XMIN(geo_coords)||' '||ST_YMIN(geo_coords)||')),')||')', ')),)', ')))') as coords_final
        
from geo_coords;

// Paste coords_final column into https://clydedacruz.github.io/openstreetmap-wkt-playground/