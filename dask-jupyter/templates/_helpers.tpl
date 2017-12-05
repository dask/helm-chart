{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dask.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 -}}
{{- end -}}

{{/*
Create fully qualified names.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "dask.jupyter-fullname" -}}
{{- $name := default .Chart.Name .Values.jupyter.name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 -}}
{{- end -}}

{{- define "dask.scheduler-fullname" -}}
{{- $name := default .Chart.Name .Values.scheduler.name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 -}}
{{- end -}}
