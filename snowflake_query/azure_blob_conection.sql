-- 1. Selecciona la base y el esquema
USE DATABASE HACKADATA;
USE SCHEMA BRONCE;

-- 2. Crea el formato de archivo JSON GZIP
CREATE OR REPLACE FILE FORMAT JSON_GZIP_FORMAT
  TYPE = 'JSON'
  COMPRESSION = 'GZIP';

-- 3. Crea el stage hacia Azure Blob
CREATE OR REPLACE STAGE raw_stage
  URL = 'azure://hackadata.blob.core.windows.net/raw'
  CREDENTIALS = (
    AZURE_SAS_TOKEN = 'sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-05-16T08:59:13Z&st=2025-05-04T00:59:13Z&spr=https&sig=sjVWr%2BB6acBKMAthhgvV2o0LK7YaemZtuBRE4NwWnLc%3D'
  )
  FILE_FORMAT = JSON_GZIP_FORMAT;

-- 4. Copia los datos desde el stage a la tabla
COPY INTO HACKADATA.BRONCE.EVENTOS_RAW (raw_data, file_name, file_time)
FROM (
  SELECT
    PARSE_JSON($1) AS raw_data,
    METADATA$FILENAME AS file_name,
    METADATA$FILE_LAST_MODIFIED AS file_time
  FROM @raw_stage (
    FILE_FORMAT => JSON_GZIP_FORMAT,
    PATTERN => '.*\.json\.gz$'
  )
)
ON_ERROR = 'CONTINUE';

-- 5. Lista los archivos para verificar
LIST @raw_stage;


