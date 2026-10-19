param([string]$Facts = "facts.txt")
$ErrorActionPreference = "SilentlyContinue"
# DoctorUSB v3: collect facts (ASCII keys, UTF-8 out). Read-only.

$out = @()
function W($k, $v) { $script:out += ($k + " = " + $v) }

W "=== SYSTEM ===" ""
W "HOSTNAME" $env:COMPUTERNAME
W "USER" $env:USERNAME
$os = Get-CimInstance Win32_OperatingSystem
if ($os) {
  W "OS" ($os.Caption + " " + $os.Version)
  W "ARCH" $os.OSArchitecture
  $ramTotal = [math]::Round($os.TotalVisibleMemorySize)
  $ramFree = [math]::Round($os.FreePhysicalMemory)
  W "RAM_TOTAL_MB" $ramTotal
  W "RAM_FREE_MB" $ramFree
}
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if ($cpu) { W "CPU" $cpu.Name }
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  W ("DISK_" + $_.DeviceID) ("total_GB=" + [math]::Round($_.Size/1GB,1) + " free_GB=" + [math]::Round($_.FreeSpace/1GB,1))
}
$gpus = @(Get-CimInstance Win32_VideoController)
for ($i = 0; $i -lt $gpus.Count; $i++) { W ("GPU_" + $i) $gpus[$i].Name }
$dds = @(Get-CimInstance Win32_DiskDrive)
for ($i = 0; $i -lt $dds.Count; $i++) { W ("DISK_MODEL_" + $i) ($dds[$i].Model + " SN=" + $dds[$i].SerialNumber + " " + [math]::Round($dds[$i].Size/1GB,0) + "GB") }
$mb = Get-CimInstance Win32_BaseBoard
if ($mb) { W "MOTHERBOARD" ($mb.Manufacturer + " " + $mb.Product) }
$bios = Get-CimInstance Win32_BIOS
if ($bios) { W "BIOS" ($bios.SMBIOSBIOSVersion + " " + $bios.ReleaseDate) }
$mems = @(Get-CimInstance Win32_PhysicalMemory)
for ($i = 0; $i -lt $mems.Count; $i++) { W ("MEM_" + $i) ($mems[$i].Manufacturer + " " + $mems[$i].PartNumber + " " + [math]::Round($mems[$i].Capacity/1GB,0) + "GB " + $mems[$i].Speed + "MHz") }
$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
W "RAN_AS_ADMIN" $adm

W "" ""
W "=== NETWORK ===" ""
$gw = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty NextHop
W "GATEWAY" $gw
if ($gw) {
  $pg = Test-Connection -ComputerName $gw -Count 2 -ErrorAction SilentlyContinue
  W "PING_GATEWAY" $pg.Count
}
$pe = Test-Connection -ComputerName "223.5.5.5" -Count 2 -ErrorAction SilentlyContinue
W "PING_223.5.5.5" $pe.Count
try { $r = Resolve-DnsName "www.baidu.com" -ErrorAction Stop | Select-Object -First 1; W "DNS_RESOLVE_BAIDU" ("OK " + $r.NameHost + " " + $r.IPAddress) } catch { W "DNS_RESOLVE_BAIDU" ("FAIL " + $_.Exception.Message) }
$dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses } | ForEach-Object { $_.InterfaceAlias + ":" + ($_.ServerAddresses -join ",") }
W "DNS_SERVERS" ($dns -join " | ")
W "IPCONFIG_ALL" ((cmd /c "ipconfig /all" | Select-Object -First 18) -join "`n")
W "ARP_-A" ((cmd /c "arp -a" | Select-Object -Skip 3 -First 15) -join "`n")
$listen = cmd /c "netstat -ano" | Select-String "LISTENING" | Select-Object -First 20
$procMap = @{}
Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $procMap[$_.Id] = $_.ProcessName }
$listenPretty = foreach ($line in $listen) {
  $raw = $line.Line
  if ($raw -match '(\d+)\s*$') {
    $p = $matches[1]
    $nm = if ($procMap.ContainsKey([int]$p)) { $procMap[[int]$p] } else { "?" }
    $raw + "  [" + $nm + "]"
  } else { $raw }
}
W "NETSTAT_LISTEN" ($listenPretty -join "`n")
$prof = Get-NetFirewallProfile -ErrorAction SilentlyContinue
if ($prof) { $prof | ForEach-Object { W ("FIREWALL_" + $_.Name) ("Enabled=" + $_.Enabled) } }

W "" ""
W "=== SECURITY ===" ""
$hosts = "C:\Windows\System32\drivers\etc\hosts"
if (Test-Path $hosts) {
  $hc = Get-Content $hosts
  W "HOSTS_TOTAL_LINES" $hc.Count
  $non = $hc | Where-Object { $_ -match "\S" -and -not $_.TrimStart().StartsWith("#") }
  W "HOSTS_NONCOMMENT_LINES" ($non -join " | ")
} else { W "HOSTS_TOTAL_LINES" "NOT FOUND" }
$is = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
if ($is) {
  W "PROXY_ENABLE" $is.ProxyEnable
  W "PROXY_SERVER" $is.ProxyServer
  W "PROXY_AUTOCONFIGURL" $is.AutoConfigURL
}
W "WINHTTP_PROXY" ((cmd /c "netsh winhttp show proxy" | Out-String).Trim())
foreach ($k in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")) {
  $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
  if ($p) { $p.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object { W ("RUN_" + ($k -replace ".*\\","") + "_" + $_.Name) $_.Value } }
}
$st = cmd /c "schtasks /query /fo csv /nh" 2>$null
W "SCHTASKS_COUNT" $st.Count
W "SCHTASKS_NAMES" (($st | Select-Object -First 15 | ForEach-Object { ($_ -split ",")[0] }) -join " | ")

$ws = New-Object -ComObject WScript.Shell
$lnkDirs = @("$env:USERPROFILE\Desktop","$env:PUBLIC\Desktop","$env:APPDATA\Microsoft\Windows\Start Menu\Programs","$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
$lnkTotal = 0
$lnkNormal = 0
$lnkSus = @()
foreach ($d in $lnkDirs) {
  if (Test-Path $d) {
    Get-ChildItem $d -Filter *.lnk -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      try {
        $s = $ws.CreateShortcut($_.FullName)
        $t = $s.TargetPath
        $a = $s.Arguments
        $lnkTotal++
        if ($a -match "https?://") { $lnkSus += ("[参数带网址] " + $_.Name + " -> " + $t + " " + $a) }
        elseif ($t -match "\\(Temp|tmp)\\") { $lnkSus += ("[目标在临时目录] " + $_.Name + " -> " + $t) }
        elseif ($a -match "(?i)(-enc|encodedcommand|downloadstring|mshta|certutil|regsvr32 /s)") { $lnkSus += ("[可疑命令参数] " + $_.Name + " -> " + $t + " " + $a) }
        elseif (-not [string]::IsNullOrWhiteSpace($a)) { $lnkNormal++ }
      } catch {}
    }
  }
}
W "LNK_TOTAL" $lnkTotal
W "LNK_NORMAL_WITH_ARGS" $lnkNormal
if ($lnkSus.Count -gt 0) { W "LNK_SUSPICIOUS" ($lnkSus -join "`n") } else { W "LNK_SUSPICIOUS" "NONE" }

$procs = Get-Process -ErrorAction SilentlyContinue
W "PROCESS_COUNT" $procs.Count
W "PROCESS_TOP_MEM" (($procs | Sort-Object WS -Descending | Select-Object -First 15 | ForEach-Object { $_.ProcessName + "=" + [math]::Round($_.WS/1MB) + "MB" }) -join " | ")

$out | ForEach-Object { $_ }
[System.IO.File]::WriteAllText($Facts, ($out -join "`r`n"), (New-Object System.Text.UTF8Encoding $true))
Write-Host ("OK facts -> " + $Facts)