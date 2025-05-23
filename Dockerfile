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
RUN dotnet restore "Nostra.DataLoad.sln"

# Copy the rest of the source code
COPY . .

# Build the Host project (Orleans server)
FROM build AS build-host
WORKDIR "/src/Nostra.DataLoad.Host"
RUN dotnet build "Nostra.DataLoad.Host.csproj" -c Release -o /app/build

# Build the UI project
FROM build AS build-ui
WORKDIR "/src/Nostra.DataLoad.UI"
RUN dotnet build "Nostra.DataLoad.UI.csproj" -c Release -o /app/build

# Publish the Host project
FROM build-host AS publish-host
RUN dotnet publish "Nostra.DataLoad.Host.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Publish the UI project
FROM build-ui AS publish-ui
RUN dotnet publish "Nostra.DataLoad.UI.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final image for Host
FROM base AS host
WORKDIR /app
COPY --from=publish-host /app/publish .
ENTRYPOINT ["dotnet", "Nostra.DataLoad.Host.dll"]

# Final image for UI
FROM base AS ui
WORKDIR /app
COPY --from=publish-ui /app/publish .
ENTRYPOINT ["dotnet", "Nostra.DataLoad.UI.dll"]