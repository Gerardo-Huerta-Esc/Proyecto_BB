import pika
import subprocess
import os
import time

# ===== Configuración RabbitMQ (VIENE DEL docker-compose) =====
RABBIT_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBIT_USER = os.getenv("RABBITMQ_USER", "admin")
RABBIT_PASSWORD = os.getenv("RABBITMQ_PASSWORD", "admin")

QUEUE_NAME = "etl_queue"


def run_script(script_name):
    print(f"[WORKER] Ejecutando {script_name}...")
    subprocess.run(["python3", f"/app/{script_name}"], check=True)


def main():
    while True:
        try:
            # ===== AUTENTICACIÓN (ESTO ES LO QUE FALTABA) =====
            credentials = pika.PlainCredentials(
                RABBIT_USER,
                RABBIT_PASSWORD
            )

            params = pika.ConnectionParameters(
                host=RABBIT_HOST,
                credentials=credentials,
                heartbeat=30
            )

            connection = pika.BlockingConnection(params)
            channel = connection.channel()

            channel.queue_declare(queue=QUEUE_NAME, durable=True)

            def callback(ch, method, properties, body):
                step = body.decode()
                print(f"[WORKER] Mensaje recibido: {step}")

                if step == "stage":
                    run_script("stage.py")
                    channel.basic_publish(
                        exchange="",
                        routing_key=QUEUE_NAME,
                        body="clean"
                    )

                elif step == "clean":
                    run_script("clean.py")
                    channel.basic_publish(
                        exchange="",
                        routing_key=QUEUE_NAME,
                        body="agg"
                    )

                elif step == "agg":
                    run_script("agg.py")
                    print("[WORKER] Pipeline ETL finalizado.")

                ch.basic_ack(delivery_tag=method.delivery_tag)

            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(
                queue=QUEUE_NAME,
                on_message_callback=callback
            )

            print("[WORKER] Esperando mensajes en la cola...")
            channel.start_consuming()

        except pika.exceptions.AMQPConnectionError:
            print("[WORKER] RabbitMQ no disponible, reintentando en 5s...")
            time.sleep(5)


if __name__ == "__main__":
    main()

