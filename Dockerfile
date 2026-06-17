FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /engine
COPY MyEngine/ .
RUN dotnet publish -r linux-x64 --self-contained true -c Release -o /out

FROM python:3.11-slim
WORKDIR /bot
COPY --from=build /out/MyEngine ./engines/MyEngine
COPY . .
RUN pip install -r requirements.txt
CMD ["python3", "lichess-bot.py"]
