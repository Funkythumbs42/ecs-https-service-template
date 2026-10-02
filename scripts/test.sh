#!/usr/bin/env bash
# PR check: unit tests for the app.
source "$(dirname "$0")/lib.sh"
cd "${REPO_ROOT}/app"
dotnet test tests/MyService.Tests/MyService.Tests.csproj -c Release
