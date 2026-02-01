import time
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Configurações (No futuro usaremos Variáveis de Ambiente)
url = "http://influxdb:8086"
token = "uvfg4ovhrAdZ98DldpfBqkCmQn2Z970Bf2D8q6shEvI2zSUI0KilKpfMGa0IsdC8hFHWfkUFozY3f_lsrGdeAA=="
org = "mov_industria"
bucket = "mov_dados"

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