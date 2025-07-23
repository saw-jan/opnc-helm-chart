{{/*
---------------------------------------------
CA certificate volume and volume mount
---------------------------------------------
*/}}

{{ define "opnc.volumes.caCertVolume" }}
{{- if not .Values.ingress.existingTlsSecretName }}
- name: ca-cert
  secret:
    secretName: {{ include "opnc.caSecretName" . }}
{{ end }}
{{ end }}

{{ define "opnc.volumes.caCertVolumeMount" }}
{{- if not .Values.ingress.existingTlsSecretName }}
- name: ca-cert
  mountPath: /certs
{{ end }}
{{ end }}
