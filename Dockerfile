FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /engine
COPY engines/Hyper.cs .

# Create a minimal project file
RUN dotnet new console -o HyperProject --force
COPY engines/Hyper.cs HyperProject/Program.cs
RUN dotnet publish HyperProject -r linux-x64 --self-contained true -c Release -o /out

FROM python:3.11-slim
WORKDIR /bot
COPY --from=build /out/HyperProject ./engines/Hyper
COPY . .
RUN pip install -r requirements.txt
CMD ["python3", "lichess-bot.py"]
