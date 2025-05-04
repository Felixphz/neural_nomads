
WITH source_data AS (
    SELECT
        RAW_DATA  -- <-- VERIFICA ESTE NOMBRE DE COLUMNA JSON
    FROM {{ source('silver_yaml', 'EVENTOS_RAW') }} -- <-- VERIFICA NOMBRE FUENTE Y TABLA
    WHERE RAW_DATA IS NOT NULL
),

-- Paso 1: Parsear el JSON a tipo VARIANT
parsed_variant AS (
    SELECT
        try_parse_json(RAW_DATA) AS json_data -- Parsea a VARIANT
    FROM source_data
),

-- Paso 2: Extraer y castear desde el VARIANT
extracted_data AS (
    SELECT
        -- Aplica ':' y '::' sobre la columna json_data (VARIANT)
        json_data:id::INTEGER             AS id,         -- Corregido
        json_data:type::STRING            AS type,       -- Corregido
        json_data:actor:id::STRING        AS actor_id,   -- Corregido (o usa ::INTEGER si es numérico)
        json_data:repo:id::STRING         AS repo_id,    -- Corregido (o usa ::INTEGER si es numérico)
        json_data:payload::STRING         AS payload,    -- Corregido (ajusta si necesitas extraer de aquí)
        json_data:created_at::TIMESTAMP_NTZ AS created_at -- Corregido
        -- Asegúrate que NO queden comas después de la última columna ^^^
    FROM parsed_variant
    WHERE json_data IS NOT NULL -- Buena práctica: filtra JSONs inválidos que resultaron en NULL
)

-- Selección final
SELECT * FROM extracted_data