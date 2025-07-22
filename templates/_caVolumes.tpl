{{/*
---------------------------------------------
CA certificate volume and volume mount
---------------------------------------------
*/}}

{{ define "opnc.volumes.caCertVolume" }}
- name: ca-cert
  secret:
    secretName: {{ include "opnc.caSecretName" . }}
{{ end }}

{{ define "opnc.volumes.caCertVolumeMount" }}
- name: ca-cert
  mountPath: /certs
{{ end }}
