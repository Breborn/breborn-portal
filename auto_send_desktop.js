const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORTAL_DIR = 'C:/Users/edote/.gemini/antigravity/scratch/breborn-portal';
const HARVEY_DATA = 'C:/Users/edote/.gemini/antigravity/scratch/harvey/data/breborn_leads.json';
const PORTAL_JSON_1 = path.join(PORTAL_DIR, 'breborn_leads.json');
const PORTAL_JSON_2 = path.join(PORTAL_DIR, 'data/breborn_leads.json');
const APP_JS = path.join(PORTAL_DIR, 'app.js');

const GASTRO_CATEGORIES = [
  'Cafetería',
  'Pastelería y Panadería',
  'Local de Comida / Restaurante'
];

const BATCH_SIZE = parseInt(process.argv[2] || '5', 10);
const DELAY_SEC = parseInt(process.argv[3] || '22', 10);

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('============================================================');
  console.log('  BREBORN - ENVIO AUTOMATICO DE WHATSAPP (APP + TELEFONO)');
  console.log('============================================================\n');

  const leads = JSON.parse(fs.readFileSync(PORTAL_JSON_1, 'utf8'));

  // Filter pending gastronomy leads without websites
  const pending = leads.filter(l =>
    l.has_whatsapp &&
    !l.has_website &&
    GASTRO_CATEGORIES.includes(l.category) &&
    (!l.status || l.status === 'Nuevo')
  );

  // Prioritize Viña del Mar first, then Valparaíso
  pending.sort((a, b) => {
    if (a.city === 'Viña del Mar' && b.city !== 'Viña del Mar') return -1;
    if (a.city !== 'Viña del Mar' && b.city === 'Viña del Mar') return 1;
    return 0;
  });

  const batch = pending.slice(0, BATCH_SIZE);

  if (batch.length === 0) {
    console.log('No quedan leads gastronómicos pendientes en estado "Nuevo".');
    return;
  }

  console.log(`Se enviarán ${batch.length} mensajes reales desde tu WhatsApp de Escritorio`);
  console.log('(Sincronizados automáticamente con tu teléfono móvil).\n');
  console.log('IMPORTANTE: No cierres la ventana de WhatsApp mientras se envía cada mensaje.\n');

  for (let i = 0; i < batch.length; i++) {
    const lead = batch[i];
    console.log(`[${i + 1}/${batch.length}] Abriendo chat con: ${lead.name} (${lead.city}) -> +${lead.whatsapp}`);

    const encodedText = encodeURIComponent(lead.pitch);
    const waUri = `whatsapp://send?phone=${lead.whatsapp}&text=${encodedText}`;

    // Use PowerShell in the user's interactive session to open whatsapp:// protocol,
    // focus WhatsApp window, wait for draft to populate, and press ENTER
    const psScript = `
      Start-Process "${waUri}"
      Start-Sleep -Milliseconds 4500
      $wshell = New-Object -ComObject wscript.shell
      $activated = $wshell.AppActivate("WhatsApp")
      Start-Sleep -Milliseconds 800
      $wshell.SendKeys("~")
      Write-Output "ACTIVATED:$activated"
    `;

    try {
      const out = execSync(`powershell -NoProfile -Command "${psScript.replace(/\r?\n/g, '; ')}"`, { encoding: 'utf8' });
      console.log(`   -> Mensaje disparado en WhatsApp (${out.trim()})`);
    } catch (err) {
      console.error(`   -> Error al abrir WhatsApp para ${lead.name}:`, err.message);
    }

    // Update status in memory
    lead.status = 'Mensaje Enviado';

    // Save immediately to JSON files and app.js
    const targetInFull = leads.find(x => x.id === lead.id);
    if (targetInFull) targetInFull.status = 'Mensaje Enviado';

    fs.writeFileSync(PORTAL_JSON_1, JSON.stringify(leads, null, 2), 'utf8');
    if (fs.existsSync(PORTAL_JSON_2)) {
      fs.writeFileSync(PORTAL_JSON_2, JSON.stringify(leads, null, 2), 'utf8');
    }
    if (fs.existsSync(HARVEY_DATA)) {
      fs.writeFileSync(HARVEY_DATA, JSON.stringify(leads, null, 2), 'utf8');
    }

    // Also update embedded FALLBACK_LEADS in app.js
    let appJsContent = fs.readFileSync(APP_JS, 'utf8');
    appJsContent = appJsContent.replace(
      /const FALLBACK_LEADS = \[[\s\S]*?\];/,
      `const FALLBACK_LEADS = ${JSON.stringify(leads, null, 2)};`
    );
    fs.writeFileSync(APP_JS, appJsContent, 'utf8');

    if (i < batch.length - 1) {
      console.log(`   Esperando ${DELAY_SEC} segundos antes del siguiente envío para cuidar tu cuenta...\n`);
      await sleep(DELAY_SEC * 1000);
    }
  }

  console.log('\nSincronizando estados con el Portal Web (GitHub Pages)...');
  try {
    const gitExe = 'C:/Users/edote/.gemini/antigravity/scratch/tools/git/cmd/git.exe';
    execSync(`"${gitExe}" add app.js breborn_leads.json data/breborn_leads.json`, { cwd: PORTAL_DIR });
    execSync(`"${gitExe}" commit -m "chore: mark batch of ${batch.length} gastronomy leads as Mensaje Enviado"`, { cwd: PORTAL_DIR });
    execSync(`"${gitExe}" push origin main`, { cwd: PORTAL_DIR });
    console.log('¡Portal Web actualizado exitosamente!');
  } catch (e) {
    console.log('Estados guardados localmente.');
  }

  console.log('\n============================================================');
  console.log('  ¡LOTE COMPLETADO! Revisa tu WhatsApp en el PC o Teléfono.');
  console.log('============================================================');
}

main();
