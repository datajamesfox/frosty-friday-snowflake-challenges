-- SETUP
create or replace file format json_ff
    type = json
    strip_outer_array = TRUE;
    
create or replace stage week_16_frosty_stage
    url = 's3://frostyfridaychallenges/challenge_16/'
    file_format = json_ff;

create or replace table week16 as
select t.$1:word::text word, t.$1:url::text url, t.$1:definition::variant definition  
from @week_16_frosty_stage (file_format => 'json_ff', pattern=>'.*week16.*') t;

-- OUTPUT
select
    count(word),
    count(distinct word) 
from(
    select 
        word,
        url,
        meaning.value:partOfSpeech::varchar,
        meaning.value:synonyms::varchar general_synonyms,
        meaning.value:antonyms::varchar general_antonyms,
        define.value:definition::varchar defintion,
        define.value:example::varchar example_if_applicable,
        define.value:synonyms::varchar definitional_synonyms,
        define.value:antonyms::varchar definitional_antonyms
    from week16 t0,
        lateral flatten(t0.definition[0]:meanings, outer => true) meaning,
        lateral flatten(meaning.value:definitions, outer => true) define
    );