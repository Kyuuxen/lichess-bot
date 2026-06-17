FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN chmod +x ./engines/OpenTal

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python3", "lichess-bot.py"]
