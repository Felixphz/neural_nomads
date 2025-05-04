
with source_data as (
 SELECT
        RAW_DATA  -- <-- VERIFICA ESTE NOMBRE DE COLUMNA JSON
    FROM {{ source('silver_yaml', 'EVENTOS_RAW') }} -- <-- VERIFICA NOMBRE FUENTE Y TABLA
    WHERE RAW_DATA IS NOT NULL -- Es buena idea filtrar filas donde el JSON podría ser nulo

),

parsed_json as (

    select
            try_parse_json(raw_data):actor:id::integer as id,
            try_parse_json(raw_data):actor:login::string as login,
            try_parse_json(raw_data):actor:display_login::string as display_login,
            try_parse_json(raw_data):actor:url::string as url,
            try_parse_json(raw_data):actor:avatar_url::string as avatar_url

    from source_data
    -- Puedes añadir un filtro adicional aquí si sabes que algunos JSONs no son válidos
    -- WHERE IS_VALID_JSON(actor) -- (Función específica de la base de datos, si existe)

)

select * from parsed_json
-- Puedes añadir más transformaciones o filtros aquí si es necesario
-- Por ejemplo, si quieres actores únicos:
-- select distinct * from parsed_json where actor_id is not null