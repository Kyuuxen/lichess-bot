FROM python:3.11-slim

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python3", "lichess-bot.py"]
