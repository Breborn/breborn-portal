# 🚀 Breborn Sales Hub • Viña del Mar & Valparaíso

Portal web interactivo para la prospección, gestión y contacto directo vía WhatsApp con locales comerciales, pymes y emprendedores de la V Región (Viña del Mar, Valparaíso, Concón y alrededores) para la venta de páginas web profesionales e integración al bucle de **[Breborn.cl](https://breborn.cl)**.

---

## 🌟 Características Principales

- **Base de Datos Especializada (148 Locales):**
  - 💇 **Peluquerías y Salones de Belleza** (Secrets Viña, Llongueras, Vermelho Spa, Mapu Barber, Danny Barber, etc.)
  - ☕ **Cafeterías de Especialidad** (Fausta Café, Amatista, Café Entre Cerros, Medialuna Valpo, etc.)
  - 🥐 **Pastelerías y Panaderías** (Dulcería Coca, Séptima, La María, La Campezana, Doña Javiera, etc.)
  - 🍔 **Locales de Comida / Restaurantes** (Minga Sushi, Sushi Punto, Kami Sushi, Pizzería Ecuador, etc.)
  - 🛍️ **Comercio, Boutiques, Florerías y Talleres** (La Casa de las Novias, Florería Nataly, Encactus, Julio Automotriz, etc.)

- **🔥 Segmentación de Alto Impacto:**
  - **42 Locales con WhatsApp Funcional Directo (+569)**: Validación de numeración móvil chilena.
  - **115 Locales sin Página Web**: Clientes ideales para el pitch de desarrollo web.
  - **14 Leads de Oro**: Combinan WhatsApp verificado y carecen de sitio web (prioridad inmediata).

- **💬 1-Click WhatsApp Direct:**
  - Al hacer clic en *"Enviar WhatsApp"*, se abre WhatsApp con el mensaje personalizado y contextualizado listo para enviar.
  - Al hacer clic, el estado del local cambia automáticamente a *"Mensaje Enviado"*.

- **📊 Pipeline y Persistencia Local:**
  - Control de estados: `⚪ Nuevo`, `💬 Mensaje Enviado`, `⭐ Interesado`, `🎉 En el Bucle`, `❌ No Interesado`.
  - Los estados se guardan automáticamente en tu navegador (`localStorage`), de modo que no pierdes tu avance al recargar.

- **📥 Exportación a Excel / CSV:**
  - Descarga la lista completa o tus resultados filtrados en formato CSV compatible con Excel o Google Sheets.

---

## 🖥️ Cómo Probarlo Ahora Mismo (Local)

No requieres instalar ningún servidor. Simplemente:
1. Dirígete a la carpeta:
   ```
   C:\Users\edote\.gemini\antigravity\scratch\breborn-portal
   ```
2. Haz doble clic sobre **`index.html`** para abrirlo en tu navegador favorito (Chrome, Edge, Brave, Firefox).
3. ¡Listo! Todo el sistema es autónomo y funciona al instante.

---

## 🌐 Cómo Publicarlo en GitHub y GitHub Pages

Para tenerlo accesible desde cualquier dispositivo o celular a través de una URL de GitHub (`https://tu-usuario.github.io/breborn-portal`):

### 1. Crear el repositorio en GitHub
1. Entra a [github.com/new](https://github.com/new).
2. Nómbralo por ejemplo: `breborn-portal` (o el nombre que prefieras).
3. Déjalo **Público** (Public) y no agregues README ni .gitignore (ya están creados acá).
4. Haz clic en **Create repository**.

### 2. Subir el código desde tu terminal (PowerShell)
Abre PowerShell y ejecuta los siguientes comandos:

```powershell
cd C:\Users\edote\.gemini\antigravity\scratch\breborn-portal

# Conecta tu repositorio de GitHub (reemplaza 'TU_USUARIO' con tu usuario real de GitHub):
git remote add origin https://github.com/TU_USUARIO/breborn-portal.git

# Renombra la rama a main y sube los archivos:
git branch -M main
git push -u origin main
```

### 3. Activar GitHub Pages (1 Clic)
1. En tu repositorio de GitHub, ve a la pestaña **Settings** (Configuración).
2. En la barra lateral izquierda, haz clic en **Pages**.
3. En la sección **Build and deployment > Source**, selecciona **Deploy from a branch**.
4. En **Branch**, selecciona `main` y la carpeta `/ (root)`.
5. Haz clic en **Save**.
6. En 1-2 minutos, tu panel estará disponible en vivo en:
   `https://TU_USUARIO.github.io/breborn-portal/`

---

## 📁 Estructura del Proyecto

```
breborn-portal/
├── index.html                  # Interfaz principal responsive y moderna
├── style.css                   # Estilos visuales, temas claro/oscuro y componentes
├── app.js                      # Lógica de búsqueda, filtros, WhatsApp y almacenamiento
├── data/
│   └── breborn_leads.json      # Dataset completo de 148 locales
├── .github/
│   └── workflows/
│       └── deploy.yml          # Despliegue automático con GitHub Actions
└── README.md                   # Documentación y guía de uso
```

---

*Desarrollado para Breborn ([breborn.cl](https://breborn.cl)) con Harvey & Google Antigravity.*
