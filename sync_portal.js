const fs = require('fs');
const { execSync } = require('child_process');

const PORTAL_DIR = 'C:/Users/edote/.gemini/antigravity/scratch/breborn-portal';
const JSON_FILE = `${PORTAL_DIR}/breborn_leads.json`;
const DATA_JSON_FILE = `${PORTAL_DIR}/data/breborn_leads.json`;
const APP_JS = `${PORTAL_DIR}/app.js`;
const HARVEY_JSON = 'C:/Users/edote/.gemini/antigravity/scratch/harvey/data/breborn_leads.json';

let raw = fs.readFileSync(JSON_FILE, 'utf8');
if (raw.charCodeAt(0) === 0xFEFF) {
  raw = raw.slice(1);
}
const leads = JSON.parse(raw);

const formattedJson = JSON.stringify(leads, null, 2);
fs.writeFileSync(JSON_FILE, formattedJson, 'utf8');
fs.writeFileSync(DATA_JSON_FILE, formattedJson, 'utf8');
if (fs.existsSync('C:/Users/edote/.gemini/antigravity/scratch/harvey/data')) {
  fs.writeFileSync(HARVEY_JSON, formattedJson, 'utf8');
}

// Update EMBEDDED_LEADS and count comment in app.js
let appJs = fs.readFileSync(APP_JS, 'utf8');
const compactLeads = JSON.stringify(leads);
appJs = appJs.replace(
  /\/\/ Dataset embebido con .*?\r?\nconst EMBEDDED_LEADS = \[[\s\S]*?\];/,
  `// Dataset embebido con ${leads.length} locales de Viña del Mar y Valparaíso\nconst EMBEDDED_LEADS = ${compactLeads};`
);
fs.writeFileSync(APP_JS, appJs, 'utf8');

const sentCount = leads.filter(l => l.status === 'Mensaje Enviado').length;
const pendingCount = leads.filter(l => l.has_whatsapp && (!l.status || l.status === 'Nuevo')).length;
console.log(`Synchronized ${leads.length} leads (${sentCount} Mensaje Enviado, ${pendingCount} Nuevo con WA).`);

try {
  const git = 'C:/Users/edote/.gemini/antigravity/scratch/tools/git/cmd/git.exe';
  execSync(`"${git}" add app.js index.html breborn_leads.json data/breborn_leads.json`, { cwd: PORTAL_DIR });
  const status = execSync(`"${git}" status --porcelain`, { cwd: PORTAL_DIR }).toString().trim();
  if (status) {
    execSync(`"${git}" commit -m "sync: ${sentCount} enviados, ${pendingCount} pendientes (${leads.length} locales)"`, { cwd: PORTAL_DIR });
    execSync(`"${git}" push origin main`, { cwd: PORTAL_DIR });
    console.log('Pushed to GitHub Pages!');
  } else {
    console.log('No git changes to push.');
  }
} catch (e) {
  console.log('Git commit/push output:', e.message);
}
