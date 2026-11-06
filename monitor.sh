#!/bin/bash
# Monitor externo (U2 do pente fino de 02/11/2026). Roda no GitHub Actions, fora da rede da elti.
# Para cada host: HTTPS responde com status < 500 e certificado vale por mais de DIAS_CERT dias.
# Tudo ok -> ping no Healthchecks; algum problema -> /fail com a lista. Sem ping -> o Healthchecks avisa.
set -u
DIAS_CERT=${DIAS_CERT:-14}
problemas=()
agora=$(date +%s)
while read -r h; do
  case "$h" in ''|\#*) continue;; esac
  c=$(curl -s -o /dev/null -m 20 --retry 2 --retry-delay 5 -w '%{http_code}' "https://$h/")
  if [ "$c" = 000 ] || [ "$c" -ge 500 ]; then problemas+=("$h: HTTP $c"); fi
  fim=$(echo | timeout 15 openssl s_client -servername "$h" -connect "$h:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  if [ -z "$fim" ]; then problemas+=("$h: sem certificado"); continue; fi
  dias=$(( ($(date -d "$fim" +%s) - agora) / 86400 ))
  [ "$dias" -ge "$DIAS_CERT" ] || problemas+=("$h: certificado vence em $dias dias ($fim)")
  printf '%-36s %s  cert %3s dias\n' "$h" "$c" "$dias"
done < "${1:-hosts.txt}"
if [ ${#problemas[@]} -eq 0 ]; then
  echo "tudo ok"; [ -z "${HC_URL:-}" ] || curl -fsS -m 15 --retry 3 -o /dev/null "$HC_URL"
else
  printf 'PROBLEMA: %s\n' "${problemas[@]}"
  [ -z "${HC_URL:-}" ] || printf '%s\n' "${problemas[@]}" | curl -fsS -m 15 --retry 3 -o /dev/null --data-binary @- "$HC_URL/fail"
  exit 1
fi
