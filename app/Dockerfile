# syntax=docker/dockerfile:1
#
# Multi-stage build for the service. Target is linux/arm64 (Graviton / Fargate ARM64).
#
#   docker buildx build --platform linux/arm64 -t my-service:local app/
#
# The SDK stage runs on the *build host's* native platform ($BUILDPLATFORM) and
# cross-compiles for $TARGETARCH, so building arm64 images on an x86_64 agent does
# not need QEMU emulation for the dotnet restore/publish steps.

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG TARGETARCH
WORKDIR /src

COPY src/MyService/MyService.csproj src/MyService/
RUN dotnet restore src/MyService/MyService.csproj -a $TARGETARCH

COPY src/ src/
RUN dotnet publish src/MyService/MyService.csproj \
      -c Release -a $TARGETARCH --no-restore \
      -o /out /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /out .

ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true
EXPOSE 8080

# Built-in non-root user shipped with the .NET 8 images (UID 1654).
USER $APP_UID

ENTRYPOINT ["dotnet", "MyService.dll"]
