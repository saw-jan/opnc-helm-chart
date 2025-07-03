{{/*
---------------------------------------------
CA certificate volume and volume mount
---------------------------------------------
*/}}

{{ define "opnc.caCertVolume" }}
- name: ca-cert
  secret:
    secretName: {{ include "opnc.caSecretName" . }}
{{ end }}

{{ define "opnc.caCertVolumeMount" }}
- name: ca-cert
  mountPath: /certs
{{ end }}
