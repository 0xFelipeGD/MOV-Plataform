"""
MOV Platform - Analytics Service
Serviço de processamento e geração de insights em tempo real.
"""

import time
import os
import sys
import signal
import logging
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Flag para graceful shutdown
running = True

def signal_handler(signum, frame):
    """Handler para sinais de terminação (SIGTERM, SIGINT)."""
    global running
    logger.info(f"Sinal {signum} recebido. Encerrando graciosamente...")
    running = False

# Registrar handlers de sinal
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

# Configurações via Variáveis de Ambiente
url = os.environ.get("INFLUX_URL", "http://influxdb:8086")
token = os.environ.get("INFLUX_TOKEN")
org = os.environ.get("INFLUX_ORG")
bucket = os.environ.get("INFLUX_BUCKET")

# Threshold configurável (padrão: 30.0°C)
TEMP_THRESHOLD = float(os.environ.get("ANALYTICS_TEMP_THRESHOLD", "30.0"))

# Intervalo de execução em segundos (padrão: 10s)
RUN_INTERVAL = int(os.environ.get("ANALYTICS_INTERVAL", "10"))

if not token:
    logger.error("INFLUX_TOKEN não definido nas variáveis de ambiente!")
    sys.exit(1)

logger.info("Conectando ao InfluxDB...")
client = InfluxDBClient(url=url, token=token, org=org)
write_api = client.write_api(write_options=SYNCHRONOUS)
query_api = client.query_api()

logger.info(f"Analytics iniciado. Threshold: {TEMP_THRESHOLD}°C | Intervalo: {RUN_INTERVAL}s")

while running:
    try:
        # 1. LER: Pega a última temperatura registrada
        query = f'from(bucket: "{bucket}") |> range(start: -1m) |> filter(fn: (r) => r["_measurement"] == "mqtt_consumer") |> filter(fn: (r) => r["_field"] == "temperatura_c") |> last()'
        tables = query_api.query(query)

        for table in tables:
            for record in table.records:
                temp_atual = record.get_value()
                logger.info(f"Temperatura lida: {temp_atual}°C")

                # 2. PROCESSAR: Lógica de Negócio (Insights)
                status = "Normal"
                if temp_atual > TEMP_THRESHOLD:
                    status = "CRITICO"
                    logger.warning(f"Temperatura acima do threshold ({TEMP_THRESHOLD}°C)!")
                
                # 3. ESCREVER: Grava o insight de volta no banco
                point = Point("insights").tag("tipo", "termico").field("status_calculado", status).field("temp_ref", float(temp_atual))
                write_api.write(bucket=bucket, org=org, record=point)
                logger.info(f"Insight gravado: {status}")

    except Exception as e:
        logger.error(f"Erro no processamento: {e}")

    # Sleep interruptível para graceful shutdown
    for _ in range(RUN_INTERVAL):
        if not running:
            break
        time.sleep(1)

# Cleanup
logger.info("Fechando conexões...")
client.close()
logger.info("Analytics encerrado.")