
with source_data as (
    SELECT
        RAW_DATA  -- <-- VERIFICA ESTE NOMBRE DE COLUMNA JSON
    FROM {{ source('silver_yaml', 'EVENTOS_RAW') }} -- <-- VERIFICA NOMBRE FUENTE Y TABLA
    WHERE RAW_DATA IS NOT NULL
),

parsed_json as (
    select
        try_parse_json(RAW_DATA):repo:id::integer as id,
        try_parse_json(RAW_DATA):repo:name::string as name,
        try_parse_json(RAW_DATA):repo:url::string as url
    from source_data
)

select * from parsed_json