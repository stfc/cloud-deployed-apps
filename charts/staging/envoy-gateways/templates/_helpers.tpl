{{/*
Expand the name of the chart.
*/}}
{{- define "envoy-gateways.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "envoy-gateways.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Expand the namespace of the release.
Allows overriding it for multi-namespace deployments in combined charts.
*/}}
{{- define "envoy-gateways.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Resolve the oauth2-proxy service name from its subchart.
If oauth2-proxy.fullnameOverride is set, use that; otherwise use <release>-oauth2-proxy.
*/}}
{{- define "envoy-gateways.oauth2ProxyServiceName" -}}
{{- if index .Values "oauth2-proxy" "fullnameOverride" }}
{{- index .Values "oauth2-proxy" "fullnameOverride" }}
{{- else }}
{{- printf "%s-oauth2-proxy" .Release.Name }}
{{- end }}
{{- end }}

{{/*
Resolve extAuth HTTP service name — explicit override wins, then auto-detect.
*/}}
{{- define "envoy-gateways.extAuthServiceName" -}}
{{- if .Values.internal.extAuth.httpService.name }}
{{- .Values.internal.extAuth.httpService.name }}
{{- else }}
{{- include "envoy-gateways.oauth2ProxyServiceName" . }}
{{- end }}
{{- end }}

{{- define "envoy-gateways.extAuthNamespace" -}}
{{- if .Values.internal.extAuth.httpService.namespace }}
{{- .Values.internal.extAuth.httpService.namespace }}
{{- else }}
{{- include "envoy-gateways.namespace" . }}
{{- end }}
{{- end }}