FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine64
    
RUN chmod +x ./engines/Chess-Coding-Adventure.exe

CMD ["python", "lichess-bot.py"]
