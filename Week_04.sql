-- create json file format

create or replace file format week_4_format
    type = json;

-- create stage for json

create or replace stage week_4_stage
    file_format = week_4_format;
    
-- In SnowlflakeSQL CLI:
 -- connect to account: snowsql -a <accountname>.<server> -u <email> --authenticator externalbrowser
 -- use <database>
 -- use <schema>
 -- use <warehouse>
 -- put file://<filepath>\<filename> @week_4_stage

-- create temp table for raw json
create or replace temporary table week_4_json
    (json_data variant);

-- load raw json into temp table
copy into week_4_json from @week_4_stage;

-- investigate json
select * from week_4_json;

-- challenge output 
-- use lateral flatten to extract values from the nested arrays
-- use row_number() function, alongside over order by birth (birth removed  "-" and cast as int)
-- use the last flatten index to create INTER_HOUSE_ID

select 
    row_number() over (order by cast(replace(t2.value:Birth, '-', '') as int)) as ID,
    t2.index+1::int as INTER_HOUSE_ID,
    t0.value:Era::string as ERA,
    t1.value:House::string as HOUSE,
    t2.value:Name::string as NAME,
    t2.value:Nickname[0]::string as NICKNAME_1,
    t2.value:Nickname[1]::string as NICKNAME_2,
    t2.value:Nickname[3]::string as NICKNAME_3,
    t2.value:Birth::string as BIRTH,    
    t2.value:"Place of Birth"::string as PLACE_OF_BIRTH,    
    t2.value:"Start of Reign"::string as START_OF_REIGN,
    t2.value:"Consort\/Queen Consort"[0]::string as CONSORT_QUEEN_CONSORT_1,
    t2.value:"Consort\/Queen Consort"[1]::string as CONSORT_QUEEN_CONSORT_2,
    t2.value:"Consort\/Queen Consort"[2]::string as CONSORT_QUEEN_CONSORT_3,    
    t2.value:"End of Reign"::string as END_OF_REIGN,   
    t2.value:Duration::string AS DURATION,    
    t2.value:Death::string AS DEATH,
    split_part(t2.value:"Age at Time of Death", ' ', 1)::int as AGE_AT_TIME_OF_DEATH_YEARS,  
    t2.value:"Place of Death"::string as PLACE_OF_DEATH,
    t2.value:"Burial Place"::string as BURIAL_PLACE  
from week_4_json,
    lateral flatten( input => json_data) as t0,
    lateral flatten( input => t0.value:Houses) as t1,
    lateral flatten( input => t1.value:Monarchs) as t2;