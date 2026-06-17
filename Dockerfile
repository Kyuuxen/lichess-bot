FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

RUN chmod +x ./engines/Chess-Coding-Adventure.exe

CMD ["python", "lichess-bot.py"]
