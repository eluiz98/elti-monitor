// Monitor externo dos sites da elti (07/11/2026): Cloudflare Worker agendado a cada 15 min.
// O agendamento do GitHub Actions atrasava ~6 h; aqui o cron da Cloudflare roda na hora.
// Para cada host de ../hosts.txt: HTTPS responde com status < 500 (certificado inválido ou
// vencido = erro de conexão = problema). Tudo ok -> ping no Healthchecks; senão /fail com a lista.
// A validade (>= 14 dias) dos certificados continua no GitHub Actions (monitor.sh), que avisa por e-mail.
import listaHosts from "../hosts.txt";

const HOSTS = listaHosts.split("\n").map((l) => l.trim()).filter((l) => l && !l.startsWith("#"));

async function testar(host) {
  let ultimo = "";
  for (let tentativa = 0; tentativa < 3; tentativa++) {
    try {
      const r = await fetch(`https://${host}/`, {
        redirect: "manual",
        signal: AbortSignal.timeout(20000),
        headers: { "user-agent": "elti-monitor" },
      });
      if (r.status < 500) return null;
      ultimo = `HTTP ${r.status}`;
    } catch (e) {
      ultimo = `erro: ${e.message || e}`;
    }
    await new Promise((ok) => setTimeout(ok, 5000));
  }
  return `${host}: ${ultimo}`;
}

async function rodar(env) {
  const problemas = (await Promise.all(HOSTS.map(testar))).filter(Boolean);
  const url = problemas.length ? `${env.HC_URL}/fail` : env.HC_URL;
  const corpo = problemas.length ? problemas.join("\n") : `tudo ok (${HOSTS.length} hosts)`;
  const hc = await fetch(url, { method: "POST", body: corpo, signal: AbortSignal.timeout(15000) });
  console.log(`${corpo} | healthchecks ${hc.status}`);
  return corpo;
}

export default {
  async scheduled(_evento, env, ctx) {
    ctx.waitUntil(rodar(env));
  },
};
