## Descripción
Este repositorio documenta la arquitectura y el flujo de datos implementados en los últimos dos días para ingesta, almacenamiento, procesamiento y visualización de datos de GitHub Archive (GH Archive). La solución hace uso de servicios serverless en Azure, almacenamiento en Azure Blob, Snowflake como data warehouse siguiendo la arquitectura Medallion, un modelo de recomendación ALS y visualización en Power BI.

---

## Arquitectura General

```plaintext
+----------------------+      +--------------------+      +----------------------+      +--------------------+
|  Azure Function App  | ---> |   Azure Blob       | ---> |    Snowflake         | ---> |   Power BI / ALS    |
|  (Serverless)        |      |   Storage          |      | (Medallion Architecture)    | (consume GOLD)      |
+----------------------+      +--------------------+      +----------------------+      +--------------------+
        |                      (JSON.GZ Files)               |                        ^                        
        |                                                        \                       |                        
        v                                                         \                      |                        
 GH Archive API                                                  Capa GOLD              |                        
 (data raw)                                                                                 |                        
                                                                                       Modelo ALS                  
                                                                                                            
```

---

## Componentes

### 1. Azure Functions (Serverless)

- **Propósito**: Automatizar la ingesta diaria de datos de la API de GitHub Archive.
- **Tecnologías**: Azure Functions (JavaScript/Python), Timer Trigger.
- **Flujo**:
  1. Se dispara según cron diario.
  2. Consulta la API de GH Archive para el bloque horario correspondiente.
  3. Comprueba y filtra eventos relevantes.
  4. Serializa respuesta en JSON.
  5. Comprime en `.json.gz`.
  6. Sube el archivo al contenedor de Azure Blob Storage.

### 2. Azure Blob Storage

- **Propósito**: Almacenar los archivos comprimidos de eventos (`.json.gz`).
- **Configuración**:
  - Contenedor: `gharchive-events`
  - Políticas de acceso: SAS tokens para ingesta y lectura.
- **Estructura de blobs**:
  - Fecha/hora base: `yyyy/MM/dd/HH.json.gz`

### 3. Snowflake (Data Warehouse)

- **Propósito**: Centralizar y estructurar los datos para análisis y modelo de recomendación.
- **Conexión**: Azure Blob Storage integrados vía External Stage.
- **Arquitectura Medallion**:
  - **Bronze**: Tablas raw que referencian directamente los archivos (`COPY INTO Bronzeraw FROM @gharchive_stage`).
  - **Silver**: Transformaciones intermedias (limpieza, normalización, particionado).
  - **Gold**: Tablas finales con métricas listas para consumo.
- **Procedimientos**:
  - `CREATE STAGE gharchive_stage URL='azure://...';`
  - `COPY INTO BronzeRaw ... FILE_FORMAT=(TYPE=JSON compressed=true);`
  - SQL para silver y gold en pipelines de tareas Snowflake.

### 4. Modelo ALS (Alternating Least Squares)

- **Propósito**: Generar recomendaciones de repositorios o usuarios basadas en interacciones.
- **Entrenamiento**: Se conecta a la capa GOLD de Snowflake.
- **Herramientas**: PySpark MLlib.
- **Flujo**:
  1. Consulta de tabla gold: `SELECT user_id, repo_id, event_count FROM Gold.EventsMetrics;`
  2. Construcción de DataFrame en Spark.
  3. Entrenamiento ALS con parámetros (`rank`, `regParam`, `maxIter`).
  4. Generación de predicciones y guardado en Snowflake o Blob.

### 5. Power BI

- **Propósito**: Dashboard interactivo para visualizar métricas de eventos y recomendaciones.
- **Conexión**: DirectQuery o import de tablas desde Snowflake (capa GOLD).
- **Elementos clave**:
  - Gráficos de tendencias de eventos.
  - Top repositorios y usuarios.
  - Integración de resultados del modelo ALS.

---

## Despliegue y Configuración

1. **Azure Functions**:
   - Configurar Application Settings (`BLOB_CONNECTION_STRING`).
   - Publicar con `func azure functionapp publish`.

2. **Azure Blob**:
   - Crear Storage Account.
   - Crear contenedor `raw`.

3. **Snowflake**:
   - Crear Warehouse y Database.
   - Definir External Stage apuntando a Azure Blob.
   -  Ejecutar Snowpipe para carga automatica de Bronze

4. **DBT**
    - Configurar la integración con SnowFlake
    - Ejecutar los Pipelines para Silver y Gold

5. **Modelo ALS**:
   - Instalar entorno PySpark.
   - Configurar credenciales para Snowflake (conector JDBC).
   - Ejecutar script de entrenamiento periódico.

6. **Power BI**:
   - Configurar Dataset con conexión a Snowflake.
   - Diseñar reportes y dashboards.
   - Publicar en Power BI Service y programar actualizaciones.


---


## Contacto

Para dudas o modificaciones, contactar al equipo de Data Engineering.
