# elti-monitor

Monitor externo dos sites da elti (item U2 do pente fino de 02/11/2026). Duas partes, as duas fora da rede da elti e lendo o mesmo `hosts.txt`:

- **Está no ar, a cada 15 min: Cloudflare Worker `elti-monitor`** (`worker/`, desde 07/11/2026, conta Cloudflare eluiz98). Para cada host: HTTPS com status < 500 (certificado inválido ou vencido também conta como falha). Tudo ok = ping no Healthchecks.io, check **"Sites externos"** (15 min + 45 min de tolerância); problema = `/fail` com a lista. Falha ou falta de ping = e-mail. O endereço do ping fica no segredo `HC_URL` do Worker.
  - Publicar depois de mudar `hosts.txt` ou o código: `cd worker; npx wrangler@4 deploy`.
  - Ver as execuções: `npx wrangler@4 tail elti-monitor` ou o painel da Cloudflare (Workers → elti-monitor → Logs).
  - Motivo da troca: o agendamento `*/15` do GitHub Actions rodava só a cada ~6 h, o que gerava alertas falsos no Healthchecks.
- **Certificados, a cada 6 h: GitHub Actions** (`.github/workflows/monitor.yml` + `monitor.sh`): HTTPS e certificado válido por mais de 14 dias. Se falhar, o próprio GitHub manda o e-mail de "workflow failed" (não usa o Healthchecks).
  - O GitHub desliga agendamentos de repositório sem commit há 60 dias (avisa por e-mail antes). Para reativar: Actions → Certificados → Enable workflow.
- Host novo no NPM = uma linha em `hosts.txt` + `git push` + publicar o Worker.
- Rodar à mão: `bash monitor.sh` (só mostra).
