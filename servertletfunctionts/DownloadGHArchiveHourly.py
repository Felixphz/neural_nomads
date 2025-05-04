import logging
import datetime
import requests
import os
import azure.functions as func
# Necesitaremos esta librería para interactuar con Blob Storage
from azure.storage.blob import BlobServiceClient 

# Define la Function App (necesario para el modelo de programación v2)
app = func.FunctionApp() 

# El decorador @app.timer_trigger ya define cuándo se ejecuta la función.
# Lo configuraste al crearla (0 30 * * * *)
@app.timer_trigger(schedule="0 30 * * * *", arg_name="myTimer", run_on_startup=False) 
def DownloadGHArchiveHourly(myTimer: func.TimerRequest) -> None: # Quitamos outputBlob de aquí

    utc_timestamp = datetime.datetime.utcnow()
    logging.info(f'Python Timer trigger function execution started at: {utc_timestamp}')

    # Calculamos la hora del archivo que queremos descargar (la hora anterior a la ejecución)
    # Si se ejecuta a las 10:30, queremos el archivo de la hora 9 (YYYY-MM-DD-9)
    target_time = utc_timestamp - datetime.timedelta(hours=1) 
    
    # Formateamos la fecha/hora como YYYY-MM-DD-H (H es 0-23 sin cero inicial)
    # %-H funciona bien en Linux (donde corre la función)
    gh_archive_hour_str = target_time.strftime('%Y-%m-%d-%-H') 

    # Construimos el nombre del archivo y la URL de descarga
    filename = f"{gh_archive_hour_str}.json.gz"
    gh_url = f"https://data.gharchive.org/{filename}"

    logging.info(f'Attempting to download: {gh_url}')

    try:
        # Hacemos la petición para descargar el archivo
        # Aumentamos el timeout por si la descarga es lenta
        response = requests.get(gh_url, stream=True, timeout=300) 
        response.raise_for_status() # Esto lanzará un error si la descarga falla (ej: 404 Not Found)

        file_content = response.content # Leemos el contenido del archivo descargado

        if file_content:
            logging.info(f"Successfully downloaded {filename}. Size: {len(file_content)} bytes.")
            
            # --- Código para subir a Azure Blob Storage ---

            # 1. Obtener la cadena de conexión de la configuración de la aplicación
            #    ¡IMPORTANTE! Necesitaremos configurar esto más tarde.
            #    Usaremos una variable llamada 'GHARCHIVE_BLOB_CONNECTION_STRING'
            connect_str = os.environ.get('GHARCHIVE_BLOB_CONNECTION_STRING') 

            # Como plan B, si no está definida la anterior, intenta usar la conexión por defecto de la Function App
            if not connect_str:
                 logging.warning("GHARCHIVE_BLOB_CONNECTION_STRING not set. Trying AzureWebJobsStorage.")
                 connect_str = os.environ.get('AzureWebJobsStorage')

            if not connect_str:
                logging.error("Azure Storage connection string not found in Application Settings (checked GHARCHIVE_BLOB_CONNECTION_STRING and AzureWebJobsStorage). Cannot upload.")
                return # Salimos si no hay cadena de conexión

            # 2. Definir el nombre del contenedor donde guardaremos los archivos
            #    ¡¡¡ CAMBIO REALIZADO AQUÍ !!!
            container_name = "raw" # <--- Usaremos el contenedor existente 'raw'

            # 3. Crear el cliente de Blob Storage y subir el archivo
            try:
                blob_service_client = BlobServiceClient.from_connection_string(connect_str)
                blob_client = blob_service_client.get_blob_client(container=container_name, blob=filename)

                logging.info(f"Uploading {filename} to container '{container_name}'...") # Mensaje actualizado
                blob_client.upload_blob(file_content, overwrite=True) # overwrite=True por si se re-ejecuta
                logging.info(f"Successfully uploaded {filename} to '{container_name}'.") # Mensaje actualizado
            
            except Exception as upload_ex:
                logging.error(f"Error uploading {filename} to blob storage: {upload_ex}")
                # Podrías querer lanzar el error para que la ejecución falle
                # raise upload_ex

        else:
            # Esto puede pasar si justo en esa hora no hubo eventos en GitHub (muy raro)
            # o si hubo un problema silencioso en la descarga.
            logging.warning(f"Downloaded file {filename} is empty or download failed silently.")

    except requests.exceptions.RequestException as e:
        # Manejo de errores específicos de la descarga (mala URL, timeout, etc.)
        logging.error(f"Error during download request for {gh_url}: {e}")
        # En un escenario real, podrías querer reintentar o notificar.
        # Por ahora solo registramos el error.
    
    except Exception as e:
        # Captura cualquier otro error inesperado durante la ejecución.
        logging.error(f"An unexpected error occurred in the function: {e}")
        # Lanzar el error podría ser útil para que Azure marque la ejecución como fallida.
        # raise e

    logging.info(f'Python Timer trigger function execution finished at: {datetime.datetime.utcnow()}')