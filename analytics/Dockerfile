FROM python:3.12-slim

# Criar usuário non-root
RUN useradd -m -u 1000 appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .

# Trocar para usuário non-root
USER appuser

CMD ["python", "-u", "main.py"]