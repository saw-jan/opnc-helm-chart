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

{{/*
---------------------------------------------
OpenID Connect variables.
---------------------------------------------
*/}}

{{- define "opnc.idp.providerName" -}}
{{ .Values.openproject.oidcProvider | default "keycloak" }}
{{- end -}}

{{- define "opnc.idp.realmName" -}}
{{ .Values.keycloak.realmName | default "opnc" }}
{{- end -}}

{{- define "opnc.idp.nextcloudClientId" -}}
{{ .Values.keycloak.clients.nextcloud.id | default "nextcloud" }}
{{- end -}}

{{- define "opnc.idp.nextcloudClientSecret" -}}
{{ .Values.keycloak.clients.nextcloud.secret | default "nextcloud-secret" }}
{{- end -}}

{{- define "opnc.idp.openprojectClientId" -}}
{{ .Values.keycloak.clients.openproject.id | default "openproject" }}
{{- end -}}

{{- define "opnc.idp.openprojectClientSecret" -}}
{{ .Values.keycloak.clients.openproject.secret | default "openproject-secret" }}
{{- end -}}
