param(
    [int]$BatchSize = 10,
    [int]$DelaySec = 25,
    [string]$City = "",
    [string]$LeadIds = "",
    [switch]$All,
    [switch]$OnlySinWeb,
    [switch]$DryRun
)

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$uiaClient = [System.Windows.Automation.AutomationElement].Assembly.Location
$uiaTypes = [System.Windows.Automation.ControlType].Assembly.Location

Add-Type -ReferencedAssemblies $uiaClient, $uiaTypes @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Automation;

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

    private static List<IntPtr> GetWhatsAppWindows(IntPtr hInput) {
        var list = new List<IntPtr>();
        EnumDesktopWindows(hInput, (hWnd, lParam) => {
            if (IsWindowVisible(hWnd)) {
                StringBuilder sb = new StringBuilder(256);
                GetWindowText(hWnd, sb, 256);
                string title = sb.ToString();
                if (title == "WhatsApp" || Regex.IsMatch(title, @"^\(\d+\)\s+WhatsApp$")) {
                    list.Add(hWnd);
                }
            }
            return true;
        }, IntPtr.Zero);
        return list;
    }

    private static string DigitsOnly(string s) {
        if (s == null) return "";
        var sb = new StringBuilder();
        foreach (char c in s) if (char.IsDigit(c)) sb.Append(c);
        return sb.ToString();
    }

    private static void ScanWindowState(IntPtr hInput, out string activeCompose, out AutomationElement composeEl, out IntPtr composeHwnd, out string errorMsg, out AutomationElement okBtn) {
        activeCompose = "";
        composeEl = null;
        composeHwnd = IntPtr.Zero;
        errorMsg = "";
        okBtn = null;
        var hwnds = GetWhatsAppWindows(hInput);
        foreach (IntPtr hwnd in hwnds) {
            try {
                var root = AutomationElement.FromHandle(hwnd);
                var all = root.FindAll(TreeScope.Descendants, Condition.TrueCondition);
                if (all.Count < 20) continue;
                foreach (AutomationElement el in all) {
                    try {
                        string name = el.Current.Name ?? "";
                        string ct = el.Current.ControlType.ProgrammaticName ?? "";
                        if ((ct == "ControlType.Text" || ct == "ControlType.Group" || ct == "ControlType.Window") &&
                            (name.Contains("no est\u00e1 en WhatsApp") || name.Contains("isn't on WhatsApp") || name.Contains("no es v\u00e1lido") || name.Contains("phone number shared via url is invalid"))) {
                            errorMsg = name;
                        }
                        if (ct == "ControlType.Button" && (name == "OK" || name == "Aceptar" || name == "Cerrar")) {
                            okBtn = el;
                        }
                        if (ct == "ControlType.Edit" && (name.StartsWith("Escribir un mensaje") || name.StartsWith("Type a message"))) {
                            activeCompose = name;
                            composeEl = el;
                            composeHwnd = hwnd;
                        }
                    } catch {}
                }
            } catch {}
        }
    }

    public static string SendMessageSafe(string phone, string uri) {
        string outcome = "FAILED";
        string prevCompose = "";

        Thread thPrev = new Thread(() => {
            IntPtr hInput = OpenInputDesktop(0, false, 0x01FF);
            if (hInput != IntPtr.Zero && SetThreadDesktop(hInput)) {
                string e;
                AutomationElement cel, ok;
                IntPtr chw;
                ScanWindowState(hInput, out prevCompose, out cel, out chw, out e, out ok);
                if (!string.IsNullOrEmpty(e) && ok != null) {
                    try {
                        object pat;
                        if (ok.TryGetCurrentPattern(InvokePattern.Pattern, out pat)) {
                            ((InvokePattern)pat).Invoke();
                            Thread.Sleep(350);
                        }
                    } catch {}
                }
            }
            if (hInput != IntPtr.Zero) CloseDesktop(hInput);
        });
        thPrev.SetApartmentState(ApartmentState.STA);
        thPrev.Start();
        thPrev.Join();

        Process.Start(new ProcessStartInfo(uri) { UseShellExecute = true });

        Thread t = new Thread(() => {
            IntPtr hInput = OpenInputDesktop(0, false, 0x01FF);
            if (hInput != IntPtr.Zero && SetThreadDesktop(hInput)) {
                Thread.Sleep(1800);
                var sw = Stopwatch.StartNew();
                string phoneTail = phone.Length >= 8 ? phone.Substring(phone.Length - 8) : phone;

                while (sw.ElapsedMilliseconds < 8000) {
                    string activeCompose, errorMsg;
                    AutomationElement composeEl, okBtn;
                    IntPtr composeHwnd;
                    ScanWindowState(hInput, out activeCompose, out composeEl, out composeHwnd, out errorMsg, out okBtn);

                    if (!string.IsNullOrEmpty(errorMsg)) {
                        if (okBtn != null) {
                            try {
                                object pat;
                                if (okBtn.TryGetCurrentPattern(InvokePattern.Pattern, out pat)) {
                                    ((InvokePattern)pat).Invoke();
                                    Thread.Sleep(350);
                                }
                            } catch {}
                        }
                        outcome = "NO_WHATSAPP";
                        break;
                    }

                    if (!string.IsNullOrEmpty(activeCompose) && composeEl != null) {
                        string composeDigits = DigitsOnly(activeCompose);
                        bool matchesPhone = composeDigits.EndsWith(phoneTail);
                        bool changedToSavedName = (composeDigits.Length == 0 && activeCompose != prevCompose);
                        bool timedOutWithSwitch = (sw.ElapsedMilliseconds >= 4500 && (string.IsNullOrEmpty(prevCompose) || activeCompose != prevCompose));

                        if (matchesPhone || changedToSavedName || timedOutWithSwitch) {
                            Thread.Sleep(800);
                            string c2, e2;
                            AutomationElement cel2, ok2;
                            IntPtr chw2;
                            ScanWindowState(hInput, out c2, out cel2, out chw2, out e2, out ok2);
                            if (!string.IsNullOrEmpty(e2)) {
                                if (ok2 != null) {
                                    try {
                                        object pat;
                                        if (ok2.TryGetCurrentPattern(InvokePattern.Pattern, out pat)) ((InvokePattern)pat).Invoke();
                                    } catch {}
                                }
                                outcome = "NO_WHATSAPP";
                                break;
                            }

                            var hwnds = GetWhatsAppWindows(hInput);
                            foreach (IntPtr hw in hwnds) {
                                ShowWindow(hw, 9); // SW_RESTORE
                                SetForegroundWindow(hw);
                            }
                            if (chw2 != IntPtr.Zero) SetForegroundWindow(chw2);
                            Thread.Sleep(350);
                            try { if (cel2 != null) cel2.SetFocus(); } catch {}
                            Thread.Sleep(350);

                            keybd_event(VK_RETURN, 0, 0, UIntPtr.Zero);
                            Thread.Sleep(90);
                            keybd_event(VK_RETURN, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
                            outcome = "SENT";
                            break;
                        }
                    }
                    Thread.Sleep(250);
                }
            }
            if (hInput != IntPtr.Zero) CloseDesktop(hInput);
        });
        t.SetApartmentState(ApartmentState.STA);
        t.Start();
        t.Join();
        return outcome;
    }
}
"@

$portalDir = "C:\Users\edote\.gemini\antigravity\scratch\breborn-portal"
$jsonFile = Join-Path $portalDir "breborn_leads.json"
$updateJs = Join-Path $portalDir "update_status.js"

# Read leads safely
$rawJson = [System.IO.File]::ReadAllText($jsonFile, [System.Text.Encoding]::UTF8)
$leads = $rawJson | ConvertFrom-Json

$idFilterSet = if ([string]::IsNullOrWhiteSpace($LeadIds)) { @() } else { $LeadIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
$cityFilterSet = if ([string]::IsNullOrWhiteSpace($City)) { @() } else { $City -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
# Select EVERYTHING on the page with WhatsApp that has NOT had a message sent yet
$pending = @($leads | Where-Object {
    $_.has_whatsapp -and
    (-not [string]::IsNullOrEmpty($_.whatsapp)) -and
    ((-not $OnlySinWeb) -or (-not $_.has_website)) -and
    (($cityFilterSet.Count -eq 0) -or ($cityFilterSet -contains $_.city)) -and
    (($idFilterSet.Count -eq 0) -or ($idFilterSet -contains $_.id)) -and
    ($_.status -ne 'Mensaje Enviado' -and $_.status -ne 'Interesado' -and $_.status -ne 'En el Bucle' -and $_.status -ne 'No Interesado' -and $_.status -ne 'Sin WhatsApp')
})

$sinWebPending = @($pending | Where-Object { -not $_.has_website }).Count
Write-Output "Total de locales en el portal SIN 'Mensaje Enviado' y con WhatsApp: $($pending.Count) (de ellos, $sinWebPending sin web propia)"

if ($DryRun) {
    Write-Output "[DRY RUN] Primeros 10 en la cola universal:"
    $pending | Select-Object -First 10 | ForEach-Object -Begin { $idx = 0 } -Process {
        $idx++
        $wt = if ($_.has_website) { "Con Web" } else { "Sin Web" }
        Write-Output "  $idx. $($_.name) [$($_.category) | $wt | $($_.city)] -> +$($_.whatsapp)"
    }
    exit 0
}

if ($All -or $BatchSize -le 0) {
    $count = $pending.Count
} else {
    $count = [Math]::Min($BatchSize, $pending.Count)
}

if ($count -le 0) {
    Write-Output "No quedan locales pendientes sin mensaje enviado."
    exit 0
}

Write-Output "Iniciando tanda de $count envios automaticos (todas las categorias del portal)..."
Write-Output "Por favor NO toques el teclado ni el raton durante el proceso."
Write-Output ""

$sentCount = 0
$noWaCount = 0

for ($i = 0; $i -lt $count; $i++) {
    $lead = $pending[$i]
    $webTag = if ($lead.has_website) { "Con Web / Bucle" } else { "Sin Web" }
    Write-Output "============================================================"
    Write-Output "[$($i + 1)/$count] $($lead.name) [$($lead.category) | $webTag | $($lead.city)] -> +$($lead.whatsapp)"

    $encoded = [System.Uri]::EscapeDataString($lead.pitch)
    $uri = "whatsapp://send?phone=$($lead.whatsapp)&text=$encoded"

    Write-Output "   -> Abriendo WhatsApp Desktop, validando numero y preparando envio..."
    $res = [WaAutomator]::SendMessageSafe($lead.whatsapp, $uri)

    if ($res -eq "SENT") {
        $sentCount++
        node $updateJs $lead.id "Mensaje Enviado"
        Write-Output "   -> ENVIADO! Estado actualizado a 'Mensaje Enviado'."
    } elseif ($res -eq "NO_WHATSAPP") {
        $noWaCount++
        node $updateJs $lead.id "Sin WhatsApp"
        Write-Output "   -> AVISO: Numero no disponible en WhatsApp. Descartado sin enviar."
    } else {
        Write-Output "   -> AVISO: No se pudo confirmar el envio ($res). Queda en 'Nuevo' para reintentar."
    }

    if ($i -lt ($count - 1)) {
        if ((($i + 1) % 15) -eq 0) {
            Write-Output "   -> Pausa extendida de proteccion anti-spam (45 segundos tras 15 envios)..."
            Start-Sleep -Seconds 45
        } else {
            Write-Output "   -> Pausa de seguridad de $DelaySec segundos..."
            Start-Sleep -Seconds $DelaySec
        }
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
Write-Output "Tanda finalizada! Enviados: $sentCount | Sin WhatsApp detectados: $noWaCount"
Write-Output "Ya puedes revisar los chats y la pagina actualizada."
