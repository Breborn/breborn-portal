const fs = require('fs');

const [leadId, newStatus] = process.argv.slice(2);
if (!leadId || !newStatus) {
  console.error('Usage: node update_status.js <leadId> <newStatus>');
  process.exit(1);
}

const PORTAL_DIR = 'C:/Users/edote/.gemini/antigravity/scratch/breborn-portal';
const FILES = [
  `${PORTAL_DIR}/breborn_leads.json`,
  `${PORTAL_DIR}/data/breborn_leads.json`
];

for (const file of FILES) {
  if (!fs.existsSync(file)) continue;
  let raw = fs.readFileSync(file, 'utf8');
  if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);
  const leads = JSON.parse(raw);
  const item = leads.find(l => l.id === leadId);
  if (item) {
    item.status = newStatus;
    if (newStatus === 'Sin WhatsApp') {
      item.has_whatsapp = false;
    }
    fs.writeFileSync(file, JSON.stringify(leads, null, 2), 'utf8');
  }
}
