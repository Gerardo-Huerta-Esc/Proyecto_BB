# /etl/Dockerfile
FROM python:3.12-slim

# Evitar buffering en logs
ENV PYTHONUNBUFFERED=1

# Directorio de trabajo
WORKDIR /app

# Instalar librerías necesarias
RUN pip install --no-cache-dir pika psycopg2-binary

# Copiar todo el código del ETL
COPY . /app

# Comando por defecto al arrancar el contenedor
CMD ["python3", "worker.py"]
