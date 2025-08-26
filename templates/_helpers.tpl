{{- define "openvpn-as.name" -}}
openvpn-as
{{- end }}

{{- define "openvpn-as.fullname" -}}
{{ .Release.Name }}-{{ include "openvpn-as.name" . }}
{{- end }}
