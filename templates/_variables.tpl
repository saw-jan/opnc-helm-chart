{{/*
---------------------------------------------
Host name of the servers used in the stack.
---------------------------------------------
*/}}

{{- define "opnc.openprojectHost" -}}
{{ .Values.openprojectHost | default "openproject.local" }}
{{- end -}}

{{- define "opnc.nextcloudHost" -}}
{{ .Values.nextcloudHost | default "nextcloud.local" }}
{{- end -}}

{{- define "opnc.keycloakHost" -}}
{{ .Values.keycloakHost | default "keycloak.local" }}
{{- end -}}

{{/*
---------------------------------------------
Variables for cert-manager and TLS secrets.
---------------------------------------------
*/}}

{{- define "opnc.issuerName" -}}
{{ .Values.ingress.issuerName | default "opnc-ca-issuer" }}
{{- end -}}

{{- define "opnc.caSecretName" -}}
{{ .Values.ingress.caSecretName | default "opnc-ca-secret" }}
{{- end -}}

{{- define "opnc.tlsSecretName" -}}
{{ .Values.ingress.tlsSecretName | default "opnc-tsl-secret" }}
{{- end -}}