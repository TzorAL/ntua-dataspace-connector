{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "tsg-connector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tsg-connector.fullname" -}}
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
{{- define "tsg-connector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "tsg-connector.labels" -}}
app.kubernetes.io/name: {{ include "tsg-connector.name" . }}
helm.sh/chart: {{ include "tsg-connector.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Data App config map template
*/}}
{{- define "tsg-connector.data-app-configmap" -}}
{{- $appCtx := index . 0 -}}
{{- $rootCtx := index . 1 -}}
ids:
  connector-id: {{ $rootCtx.Values.ids.info.idsid }}
  participant-id: {{ $rootCtx.Values.ids.info.curator }}
{{- with $appCtx.validateResources }}
  validate-resources: {{ .enabled }}
  {{- with .interval }}
  validate-resources-interval {{ int . | quote }}
  {{- end }}
{{- else }}
  validate-resources: true 
{{- end }}
{{- with $appCtx.cacheInvalidationPeriod }}
  cache-invalidation-period: {{ int . | quote }}
{{- end }}
{{- with $appCtx.idsConfig }}
  {{- tpl (toYaml .) $rootCtx | nindent 2 }}
{{- end }}
{{- with $appCtx.config }}
{{ tpl (toYaml .) $rootCtx }}
{{- end }}
# core-container configuration is needed so traffic flows through it
core-container:
  # The endpoint is the core-container deployed along with the data app
  https-forward-endpoint: "http://{{ template "tsg-connector.fullname" $rootCtx }}:8080/https_out"
  idscp-forward-endpoint: "http://{{ template "tsg-connector.fullname" $rootCtx }}:8080/idscp_out"
  api-endpoint: http://{{ template "tsg-connector.fullname" $rootCtx }}:8082/api
  {{- with $appCtx.apiKey }}
  apiKey: {{ . }}
  {{- end }}
{{- end -}}