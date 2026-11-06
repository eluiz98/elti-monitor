# elti-monitor

Monitor externo dos sites da elti (item U2 do pente fino de 02/11/2026).

- `.github/workflows/monitor.yml` roda a cada 15 min no GitHub Actions (fora da rede da elti).
- `monitor.sh` confere cada host de `hosts.txt`: HTTPS com status < 500 e certificado válido por mais de 14 dias.
- Resultado no Healthchecks.io, check **"Sites externos (GitHub elti-monitor)"** (15 min + 45 min de tolerância): falha ou falta de ping = e-mail. O endereço do ping fica no segredo `HC_URL`.
- Host novo no NPM = uma linha em `hosts.txt`.
- O GitHub desliga agendamentos de repositório sem commit há 60 dias (avisa por e-mail antes); se o ping parar, o Healthchecks também avisa. Para reativar: Actions → Monitor externo → Enable workflow.
- Rodar à mão: `bash monitor.sh` (sem `HC_URL`, só mostra).
