{{- define "workergroup.pod" -}}
{{- if .Values.rbac.create }}
serviceAccountName: {{ include "logstream-workergroup.fullname" . }}
{{- end }}
{{- if .Values.securityContextXX }}
securityContext:
{{ toYaml .Values.securityContext | indent 2 }}
{{- end }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- with .Values.initContainers }}
initContainers:
  {{- toYaml . | nindent 8 }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.criblImage.repository }}:{{ .Values.criblImage.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.criblImage.pullPolicy }}
    {{- if .Values.securityContext }}
    command: 
    - bash
    - -c 
    - |
      set -ex 
      useradd -d /opt/cribl -g "{{- .Values.securityContext.runAsGroup }}" -u "{{- .Values.securityContext.runAsUser }}" cribl
      chown  -R   "{{- .Values.securityContext.runAsUser }}:{{- .Values.securityContext.runAsGroup }}" /opt/cribl
      su cribl -c "/sbin/entrypoint.sh cribl"
    {{- end }}
    env:
      - name: CRIBL_DIST_MASTER_URL
        valueFrom:
          secretKeyRef:
            name: logstream-config-{{ include "logstream-workergroup.fullname" . }}
            key: url-master
      # Self-Signed Certs
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "{{ .Values.config.rejectSelfSignedCerts }}"
    volumeMounts:
      {{- range .Values.extraConfigmapMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        subPath: {{ .subPath | default "" }}
        readOnly: {{ .readOnly }}
      {{- end }}
      {{- range .Values.extraSecretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        subPath: {{ .subPath | default "" }}
      {{- end }}
      {{- range .Values.extraVolumeMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        subPath: {{ .subPath | default "" }}
        readOnly: {{ .readOnly }}
      {{- end }}

    ports: 
      {{-  range .Values.service.ports }}
      - name: {{ .name }}
        containerPort: {{ .port }}
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 12 }}
  {{- with .Values.extraContainers }}
  {{ tpl . $ | indent 2 }}
  {{- end }}

{{- end }}



