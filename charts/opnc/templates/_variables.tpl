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
{{ .Values.openproject.oidcProvider | default "keycloak" }}
{{- end -}}

{{- define "opnc.oidc.realmName" -}}
{{ .Values.oidc.realmName | default "opnc" }}
{{- end -}}

{{- define "opnc.oidc.nextcloudClientId" -}}
{{ .Values.oidc.clients.nextcloud.id | default "nextcloud" }}
{{- end -}}

{{- define "opnc.oidc.nextcloudClientSecret" -}}
{{ .Values.oidc.clients.nextcloud.secret | default "nextcloud-secret" }}
{{- end -}}

{{- define "opnc.oidc.openprojectClientId" -}}
{{ .Values.oidc.clients.openproject.id | default "openproject" }}
{{- end -}}

{{- define "opnc.oidc.openprojectClientSecret" -}}
{{ .Values.oidc.clients.openproject.secret | default "openproject-secret" }}
{{- end -}}
