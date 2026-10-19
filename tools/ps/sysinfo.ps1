param([string]$Section = "ALL")
# DoctorUSB: system/disk/hardware info (ASCII labels, UTF-8 via console)
function P($t){ Write-Output $t }
if ($Section -in @("ALL","SYSTEM")) {
  $os = Get-CimInstance Win32_OperatingSystem
  if ($os) {
    P ("OS: " + $os.Caption + " " + $os.Version + " " + $os.OSArchitecture)
    P ("RAM_TOTAL_GB: " + [math]::Round($os.TotalVisibleMemorySize/1MB,1) + "  RAM_FREE_GB: " + [math]::Round($os.FreePhysicalMemory/1MB,1))
  }
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  if ($cpu) { P ("CPU: " + $cpu.Name) }
  $i = 0
  foreach ($d in @(Get-CimInstance Win32_DiskDrive)) { P ("HDD" + $i + ": " + $d.Model + "  SN=" + $d.SerialNumber + "  " + [math]::Round($d.Size/1GB) + "GB"); $i++ }
  foreach ($v in @(Get-CimInstance Win32_VideoController)) { P ("GPU: " + $v.Name) }
  $mb = Get-CimInstance Win32_BaseBoard; if ($mb) { P ("MOTHERBOARD: " + $mb.Manufacturer + " " + $mb.Product) }
  $b = Get-CimInstance Win32_BIOS; if ($b) { P ("BIOS: " + $b.SMBIOSBIOSVersion + " " + $b.ReleaseDate) }
  foreach ($m in @(Get-CimInstance Win32_PhysicalMemory)) { P ("RAM_STICK: " + $m.Manufacturer + " " + $m.PartNumber + " " + [math]::Round($m.Capacity/1GB) + "GB " + $m.Speed + "MHz") }
}
if ($Section -in @("ALL","DISKS")) {
  foreach ($l in @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3")) { P ($l.DeviceID + "  total_GB=" + [math]::Round($l.Size/1GB,1) + "  free_GB=" + [math]::Round($l.FreeSpace/1GB,1)) }
}
if ($Section -in @("ALL","STARTUP")) {
  foreach ($s in @(Get-CimInstance Win32_StartupCommand)) { P ("STARTUP: " + $s.Name + " => " + $s.Command) }
}