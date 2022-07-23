{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dask.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dask.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dask.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "dask.labels" -}}
{{- $ := index . 1 }}
{{- with index . 0 }}
{{- if eq "kubernetes" $.Values.label.style }}
helm.sh/chart: {{ include "dask.chart" $ }}
{{- else }}
chart: {{ include "dask.chart" $ }}
{{- end }}
{{- include "dask.selectorLabels" (list . $) }}
{{- if $.Chart.AppVersion }}
{{- if eq "kubernetes" $.Values.label.style }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- else }}
version: {{ $.Chart.AppVersion | quote }}
{{- end }}
{{- end }}
{{- if eq "kubernetes" $.Values.label.style }}
app.kubernetes.io/part-of: {{ include "dask.fullname" $ }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app.kubernetes.io/created-by: {{ include "dask.chart" $ }}
{{- else }}
heritage: {{ $.Release.Service }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dask.selectorLabels" -}}
{{- $ := index . 1 }}
{{- with index . 0 }}
{{- if eq "kubernetes" $.Values.label.style }}
app.kubernetes.io/name: {{ include "dask.name" $ }}-{{ .name }}
app.kubernetes.io/instance: {{ include "dask.name" $ }}-{{ .name }}
app.kubernetes.io/component: {{ .component }}
{{- else }}
app: {{ include "dask.name" $ }}
release: {{ $.Release.Name | quote }}
component: {{ .component }}
{{- end }}
{{- end }}
{{- end }}
