import time
import os
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Configurações via Variáveis de Ambiente
url = os.environ.get("INFLUX_URL", "http://influxdb:8086")
token = os.environ.get("INFLUX_TOKEN")
org = os.environ.get("INFLUX_ORG")
bucket = os.environ.get("INFLUX_BUCKET")

if not token:
    raise ValueError("ERRO: INFLUX_TOKEN não definido nas variáveis de ambiente!")

client = InfluxDBClient(url=url, token=token, org=org)
write_api = client.write_api(write_options=SYNCHRONOUS)
query_api = client.query_api()

print("Iniciando o Robô de Analytics...")

while True:
    try:
        # 1. LER: Pega a última temperatura registrada
        query = f'from(bucket: "{bucket}") |> range(start: -1m) |> filter(fn: (r) => r["_measurement"] == "mqtt_consumer") |> filter(fn: (r) => r["_field"] == "temperatura_c") |> last()'
        tables = query_api.query(query)

        for table in tables:
            for record in table.records:
                temp_atual = record.get_value()
                print(f"Temperatura lida: {temp_atual}")

                # 2. PROCESSAR: Lógica de Negócio (Insights)
                status = "Normal"
                if temp_atual > 30.0:
                    status = "CRITICO"
                
                # 3. ESCREVER: Grava o insight de volta no banco
                point = Point("insights").tag("tipo", "termico").field("status_calculado", status).field("temp_ref", float(temp_atual))
                write_api.write(bucket=bucket, org=org, record=point)
                print(f"Insight gravado: {status}")

    except Exception as e:
        print(f"Erro: {e}")

    time.sleep(10) # Roda a cada 10 segundos