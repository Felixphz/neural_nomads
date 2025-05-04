{{ config(
    materialized='table')
}}

WITH source_table AS (

    -- Selecciona las columnas necesarias de la tabla de origen
    -- (Asegúrate que esta referencia es correcta, ya sea source o ref)
    SELECT
        ACTOR_ID,
        CREATED_AT,
        ID,
        -- No seleccionamos PAYLOAD aquí si viene del paso anterior
        REPO_ID,
        TYPE
    FROM {{ source('gold_yaml', 'EVENTS') }} -- Opción A (si usas source)
)

-- Selección final, añadiendo la columna 'peso'
SELECT
    ACTOR_ID,
    CREATED_AT,
    ID,
    REPO_ID,
    TYPE,

    -- Lógica para calcular la columna 'peso' basada en 'TYPE'
    CASE TYPE
        WHEN 'CreateEvent' THEN 2
        WHEN 'IssueCommentEvent' THEN 1
        WHEN 'PushEvent' THEN 3
        WHEN 'WatchEvent' THEN 2
        WHEN 'IssuesEvent' THEN 1
        WHEN 'PublicEvent' THEN 2
        WHEN 'PullRequestReviewCommentEvent' THEN 3
        WHEN 'PullRequestEvent' THEN 3
        WHEN 'DeleteEvent' THEN 1
        WHEN 'PullRequestReviewEvent' THEN 3
        WHEN 'ForkEvent' THEN 4
        WHEN 'ReleaseEvent' THEN 3
        WHEN 'GollumEvent' THEN 1
        WHEN 'MemberEvent' THEN 2
        WHEN 'CommitCommentEvent' THEN 3
        ELSE NULL -- O puedes poner 0 u otro valor por defecto si un tipo no coincide
    END AS peso

FROM source_table