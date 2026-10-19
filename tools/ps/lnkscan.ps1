$ErrorActionPreference = "SilentlyContinue"
# DoctorUSB v1: scan shortcuts for REAL hijack signs only (URL in args / target in temp / attack cmdlets)
# Normal shortcuts with args (VS, WPS, system tools, games) are NOT suspicious - they are the majority.
$ws = New-Object -ComObject WScript.Shell
$dirs = @("$env:USERPROFILE\Desktop","$env:PUBLIC\Desktop","$env:APPDATA\Microsoft\Windows\Start Menu\Programs","$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
$found = $false
foreach ($d in $dirs) {
  if (Test-Path $d) {
    Get-ChildItem $d -Filter *.lnk -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      try {
        $s = $ws.CreateShortcut($_.FullName)
        $t = $s.TargetPath
        $a = $s.Arguments
        if ($a -match "https?://") { "{0}|{1}|{2}" -f "[URL_IN_ARGS]", $_.Name, ($t + " " + $a); $found = $true }
        elseif ($t -match "\\(Temp|tmp)\\") { "{0}|{1}|{2}" -f "[TARGET_IN_TEMP]", $_.Name, $t; $found = $true }
        elseif ($a -match "(?i)(-enc|encodedcommand|downloadstring|mshta|certutil|regsvr32 /s)") { "{0}|{1}|{2}" -f "[SUS_CMDLET]", $_.Name, ($t + " " + $a); $found = $true }
      } catch {}
    }
  }
}
if (-not $found) { Write-Output "NONE" }