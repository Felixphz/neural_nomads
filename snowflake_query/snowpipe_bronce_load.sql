USE DATABASE HACKADATA;
USE SCHEMA BRONCE;

-- (Recomendado una sola vez si no existen)
CREATE OR REPLACE FILE FORMAT json_gzip_format
  TYPE = 'JSON'
  COMPRESSION = 'GZIP';

CREATE OR REPLACE STAGE raw_stage
  URL = 'azure://hackadata.blob.core.windows.net/raw'
  CREDENTIALS = (
    AZURE_SAS_TOKEN = 'sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-05-16T08:59:13Z&st=2025-05-04T00:59:13Z&spr=https&sig=sjVWr%2BB6acBKMAthhgvV2o0LK7YaemZtuBRE4NwWnLc%3D'
  )
  FILE_FORMAT = json_gzip_format;

-- Carga de nuevos archivos gzip con JSON
COPY INTO HACKADATA.BRONCE.EVENTOS_RAW (RAW_DATA, FILE_NAME, FILE_TIME)
FROM (
  SELECT
    PARSE_JSON($1) AS RAW_DATA,
    METADATA$FILENAME AS FILE_NAME,
    METADATA$FILE_LAST_MODIFIED AS FILE_TIME
  FROM @raw_stage (PATTERN => '.*\.json\.gz$')
)
ON_ERROR = 'CONTINUE';