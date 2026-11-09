param(
    [int]$BatchSize = 5,
    [int]$DelaySec = 20
)

Add-Type -ReferencedAssemblies "System.Drawing.dll", "System.Windows.Forms.dll" @"
using System;
using System.Runtime.InteropServices;
using System.Threading;
using System.Drawing;
using System.Drawing.Imaging;
using System.Windows.Forms;
using System.Text;

public class WaAutomator {
    [DllImport("user32.dll")]
    public static extern IntPtr OpenInputDesktop(uint dwFlags, bool fInherit, uint dwDesiredAccess);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);
    [DllImport("user32.dll")]
    public static extern bool CloseDesktop(IntPtr hDesktop);

    [DllImport("user32.dll")]
    public static extern bool EnumDesktopWindows(IntPtr hDesktop, EnumWindowsProc lpfn, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const byte VK_RETURN = 0x0D;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public static bool SendEnterToWhatsApp() {
        bool success = false;
        Thread t = new Thread(() => {
            IntPtr hInput = OpenInputDesktop(0, false, 0x01FF);
            if (hInput != IntPtr.Zero && SetThreadDesktop(hInput)) {
                IntPtr waHwnd = IntPtr.Zero;
                EnumDesktopWindows(hInput, (hWnd, lParam) => {
                    if (IsWindowVisible(hWnd)) {
                        StringBuilder sb = new StringBuilder(256);
                        GetWindowText(hWnd, sb, 256);
                        if (sb.ToString() == "WhatsApp") {
                            waHwnd = hWnd;
                            return false;
                        }
                    }
                    return true;
                }, IntPtr.Zero);

                if (waHwnd != IntPtr.Zero) {
                    ShowWindow(waHwnd, 9); // SW_RESTORE
                    ShowWindow(waHwnd, 3); // SW_MAXIMIZE
                    SetForegroundWindow(waHwnd);
                    Thread.Sleep(700);

                    // Send Enter
                    keybd_event(VK_RETURN, 0, 0, UIntPtr.Zero);
                    Thread.Sleep(90);
                    keybd_event(VK_RETURN, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
                    success = true;
                }
            }
            if (hInput != IntPtr.Zero) CloseDesktop(hInput);
        });
        t.SetApartmentState(ApartmentState.STA);
        t.Start();
        t.Join();
        return success;
    }
}
"@

$portalDir = "C:\Users\edote\.gemini\antigravity\scratch\breborn-portal"
$jsonFile = Join-Path $portalDir "breborn_leads.json"

# Read leads safely
$rawJson = [System.IO.File]::ReadAllText($jsonFile, [System.Text.Encoding]::UTF8)
$leads = $rawJson | ConvertFrom-Json

# Find pending gastronomy leads
$pending = @($leads | Where-Object {
    $_.has_whatsapp -and
    (-not $_.has_website) -and
    ($_.category -match 'Caf|Restauran|Past|Comida') -and
    ([string]::IsNullOrEmpty($_.status) -or $_.status -eq 'Nuevo')
})

Write-Output "Total de locales gastronómicos pendientes sin web: $($pending.Count)"

$count = [Math]::Min($BatchSize, $pending.Count)
if ($count -le 0) {
    Write-Output "No quedan locales pendientes en estado 'Nuevo'."
    exit 0
}

Write-Output "Iniciando tanda de $count envíos automáticos..."
Write-Output "Por favor NO toques el teclado ni el ratón durante el proceso."
Write-Output ""

for ($i = 0; $i -lt $count; $i++) {
    $lead = $pending[$i]
    Write-Output "============================================================"
    Write-Output "[$($i + 1)/$count] Procesando: $($lead.name) ($($lead.city)) -> +$($lead.whatsapp)"

    $encoded = [System.Uri]::EscapeDataString($lead.pitch)
    $uri = "whatsapp://send?phone=$($lead.whatsapp)&text=$encoded"

    Start-Process $uri
    Write-Output "   -> Abriendo chat y precargando texto (4.5s)..."
    Start-Sleep -Milliseconds 4500

    $sent = [WaAutomator]::SendEnterToWhatsApp()
    Write-Output "   -> Tecla ENTER enviada: $sent (Mensaje despachado)"

    # Update in memory
    $lead.status = "Mensaje Enviado"

    # Save to disk
    $leadsJson = $leads | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($jsonFile, $leadsJson, [System.Text.UTF8Encoding]::new($false))

    $dataJson = Join-Path $portalDir "data\breborn_leads.json"
    if (Test-Path $dataJson) {
        [System.IO.File]::WriteAllText($dataJson, $leadsJson, [System.Text.UTF8Encoding]::new($false))
    }

    Write-Output "   -> Estado actualizado a 'Mensaje Enviado'."

    if ($i -lt ($count - 1)) {
        Write-Output "   -> Pausa de seguridad de $DelaySec segundos para proteger tu cuenta de WhatsApp..."
        Start-Sleep -Seconds $DelaySec
    }
}

Write-Output ""
Write-Output "============================================================"
Write-Output "Sincronizando cambios con GitHub Pages..."
$syncScript = Join-Path $portalDir "sync_portal.js"
if (Test-Path $syncScript) {
    node $syncScript
}

Write-Output "============================================================"
Write-Output "¡Tanda de $count mensajes finalizada con éxito!"
Write-Output "Ya puedes revisar los chats en tu WhatsApp de escritorio o teléfono."
