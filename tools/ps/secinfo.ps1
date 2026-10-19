# DoctorUSB: security check info (hosts/proxy/run keys/startup), ASCII labels
$hosts = "C:\Windows\System32\drivers\etc\hosts"
if (Test-Path $hosts) {
  $hc = Get-Content $hosts -ErrorAction SilentlyContinue
  Write-Output "--- hosts 内容 ---"
  if ($hc) { $hc }
  Write-Output "--- hosts 非注释行(默认只有localhost两行; 行多=可能被塞广告域名) ---"
  if ($hc) { $hc | Where-Object { $_ -match "\S" -and -not $_.TrimStart().StartsWith("#") } }
} else {
  Write-Output "--- hosts 文件不存在 ---"
}
$is = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
if ($is) {
  Write-Output ("ProxyEnable(0=正常): " + $is.ProxyEnable)
  Write-Output ("ProxyServer(空=正常): " + $is.ProxyServer)
  Write-Output ("AutoConfigURL(空=正常): " + $is.AutoConfigURL)
}
Write-Output "--- WinHTTP 代理 ---"
cmd /c "netsh winhttp show proxy"
foreach ($k in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")) {
  $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
  if ($p) {
    $p.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object { Write-Output ("RUN: " + $_.Name + " => " + $_.Value) }
  }
}
Write-Output "--- 启动项(注册表+启动文件夹综合) ---"
foreach ($s in @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue)) { Write-Output ("STARTUP: " + $s.Name + " => " + $s.Command) }