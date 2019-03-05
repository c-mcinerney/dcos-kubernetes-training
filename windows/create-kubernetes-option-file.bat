@echo off
SETLOCAL enableextensions enableDelayedExpansion

set "formattedValue=000000%%1"
@powershell -Command "get-content options-kubernetes-cluster.json.template | %% { $_ -replace \"TOBEREPLACED\",\"!formattedValue:~-2!\" }" > options-kubernetes-cluster!formattedValue:~-2!.json
