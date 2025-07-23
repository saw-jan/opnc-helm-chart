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
opnc-ca-issuer
{{- end -}}

{{- define "opnc.caSecretName" -}}
opnc-ca-secret
{{- end -}}

{{- define "opnc.tlsSecretName" -}}
    {{- if .Values.ingress.existingTlsSecretName }}
        {{- .Values.ingress.existingTlsSecretName -}}
    {{- else }}
        {{- .Values.ingress.tlsSecretName | default "opnc-tls-secret" -}}
    {{- end -}}
{{- end -}}

{{/*
---------------------------------------------
OpenID Connect variables.
---------------------------------------------
*/}}

{{- define "opnc.oidc.providerName" -}}
{{ .Values.oidcProvider.name | default "keycloak" }}
{{- end -}}

{{- define "opnc.oidc.openprojectClientId" -}}
{{ .Values.oidcProvider.openprojectClientId | default "openproject" }}
{{- end -}}
