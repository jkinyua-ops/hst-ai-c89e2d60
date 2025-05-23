FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copy solution and project files first to optimize layer caching
COPY ["Nostra.DataLoad.sln", "./"]
COPY ["Nostra.DataLoad/Nostra.DataLoad.csproj", "Nostra.DataLoad/"]
COPY ["Nostra.DataLoad.APIClient/Nostra.DataLoad.APIClient.csproj", "Nostra.DataLoad.APIClient/"]
COPY ["Nostra.DataLoad.AutotaskAPIClient/Nostra.DataLoad.AutotaskAPIClient.csproj", "Nostra.DataLoad.AutotaskAPIClient/"]
COPY ["Nostra.DataLoad.Cin7APIClient/Nostra.DataLoad.Cin7APIClient.csproj", "Nostra.DataLoad.Cin7APIClient/"]
COPY ["Nostra.DataLoad.Core/Nostra.DataLoad.Core.csproj", "Nostra.DataLoad.Core/"]
COPY ["Nostra.DataLoad.Domain/Nostra.DataLoad.Domain.csproj", "Nostra.DataLoad.Domain/"]
COPY ["Nostra.DataLoad.Host/Nostra.DataLoad.Host.csproj", "Nostra.DataLoad.Host/"]
COPY ["Nostra.DataLoad.UI/Nostra.DataLoad.UI.csproj", "Nostra.DataLoad.UI/"]

# Restore dependencies
RUN dotnet restore "Nostra.DataLoad.UI/Nostra.DataLoad.UI.csproj"

# Copy the rest of the source code
COPY . .

# Build the UI project
WORKDIR "/src/Nostra.DataLoad.UI"
RUN dotnet build "Nostra.DataLoad.UI.csproj" -c Release -o /app/build

# Publish the UI project
FROM build AS publish
RUN dotnet publish "Nostra.DataLoad.UI.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/healthz || exit 1

# Add database connection retry script
COPY ./scripts/wait-for-db.sh /app/wait-for-db.sh
RUN chmod +x /app/wait-for-db.sh

# Set entry point
ENTRYPOINT ["/bin/bash", "-c", "/app/wait-for-db.sh && dotnet Nostra.DataLoad.UI.dll"]