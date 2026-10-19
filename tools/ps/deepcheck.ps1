# 数码医生 v3 深检: 垃圾软件家族识别 + 可疑路径追踪 (纯只读)
# 检测: 计划任务/自启项/服务/运行进程 的路径是否可疑(临时目录/用户Roaming随机目录/ProgramData顶层)
#       + 特征库关键字命中 + 家族聚类(同目录多项=组合拳)
$ErrorActionPreference = "SilentlyContinue"

$base = Split-Path -Parent $PSScriptRoot
$outLines = @()
function Say($t){ $script:outLines += $t }

# ========== 特征库 + 白名单加载 ==========
$libFile = Join-Path $base "deepcheck.txt"
$lib = @()
# Roaming 下的正常目录白名单(默认+特征库whitelist:行)
$roamingWhite = @("Microsoft", "Adobe")
if (Test-Path $libFile) {
    Get-Content $libFile -Encoding UTF8 | ForEach-Object {
        $s = $_.Trim()
        if (-not $s -or $s.StartsWith("#")) { return }
        if ($s -match "^(?i)whitelist:(.+)$") { $roamingWhite += $matches[1].Trim(); return }
        $lib += $s
    }
}

# ========== 可疑路径判定 ==========
function Test-PathSus($path) {
    if (-not $path) { return $false }
    $lp = $path.ToLower()
    if ($lp -match "\\temp\\") { return $true }
    if ($lp -match "c:\\programdata\\[^\\]+\.exe") { return $true }
    if ($lp -match "appdata\\roaming\\([^\\]+)") {
        $d = $matches[1]
        if ($d -notin $roamingWhite) { return $true }
    }
    return $false
}

# ========== 采集四类可疑项 ==========
$suspects = @()

# 1) 计划任务
$tasks = cmd /c "schtasks /query /fo csv /nh" 2>$null
foreach ($t in $tasks) {
    if (-not $t) { continue }
    $cols = $t -split '","'
    if ($cols.Count -ge 8) {
        $run = ($cols[7] -replace '"','').Trim()
        $tname = ($cols[0] -replace '"','').Trim()
        if ($run -and (Test-PathSus $run)) {
            $suspects += [pscustomobject]@{ Type='计划任务'; Name=$tname; Path=$run; Fac='' }
        }
    }
}

# 2) 注册表自启项
$runKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)
foreach ($k in $runKeys) {
    $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
    if ($p) {
        $p.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
            if (Test-PathSus $_.Value) {
                $suspects += [pscustomobject]@{ Type='自启项'; Name=$_.Name; Path=$_.Value; Fac='' }
            }
        }
    }
}

# 3) 启动文件夹
$sf = [Environment]::GetFolderPath("Startup")
if ($sf) {
    Get-ChildItem $sf -File -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-PathSus $_.FullName) {
            $suspects += [pscustomobject]@{ Type='自启项'; Name=$_.Name; Path=$_.FullName; Fac='' }
        }
    }
}

# 4) 服务
Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.PathName -and (Test-PathSus $_.PathName)) {
        $suspects += [pscustomobject]@{ Type='服务'; Name=$_.Name; Path=$_.PathName; Fac='' }
    }
}

# 5) 运行进程(PATHEX)/计划任务/服务的完整路径再跑特征库
$allPaths = @()
foreach ($s in $suspects) { $allPaths += ($s.Type + "|" + $s.Name + "|" + $s.Path) }
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path } | ForEach-Object {
    $lp = $_.Path.ToLower()
    if (Test-PathSus $_.Path) {
        $suspects += [pscustomobject]@{ Type='进程'; Name=$_.ProcessName; Path=$_.Path; Fac='' }
    }
}

# ========== 特征库命中 ==========
foreach ($s in $suspects) {
    $hay = (($s.Type + " " + $s.Name + " " + $s.Path)).ToLower()
    foreach ($kw in $lib) {
        if ($kw -and $hay.Contains($kw.ToLower())) { $s.Fac = $kw; break }
    }
}
# 去重(同路径同类型)
$suspects = $suspects | Sort-Object Type, Path -Unique

# ========== 输出 ==========
Say "【深检结果】垃圾软件家族 / 可疑自启追踪"
Say "检查范围: 计划任务+自启项+服务+运行进程 (共扫描任务$($tasks.Count)个/服务/进程, 纯只读)"
Say ""
if ($suspects.Count -eq 0) {
    Say "未发现可疑项: 没有程序藏在 Temp/随机目录/ProgramData 顶层, 特征库无命中."
    Say "说明: 这台电脑没有典型的捆绑/弹窗广告家族特征."
} else {
    # 家族聚类: 按 特征关键字 或 一级目录名
    Say ("发现可疑项 " + $suspects.Count + " 条:")
    Say ""
    $groups = $suspects | Group-Object {
        if ($_.Fac) { "关键库命中: " + $_.Fac }
        elseif ($_.Path -match "appdata\\roaming\\([^\\]+)") { "Roaming目录: " + $matches[1] }
        elseif ($_.Path -match "\\temp\\") { "临时目录" }
        elseif ($_.Path -match "programdata\\([^\\]+)") { "ProgramData: " + $matches[1] }
        else { "其他" }
    }
    foreach ($g in $groups) {
        Say "  [族] $($g.Name)  ($($g.Count)项)"
        foreach ($s in $g.Group) {
            Say "      - $($s.Type): $($s.Name)"
            Say "          路径: $($s.Path)"
        }
        Say ""
    }
}
# 统计
Say "自启项统计: HKCU/HKLM Run + 启动夹 合计已检查; 计划任务总数为 $($tasks.Count)"

# 保存报告到 根目录 report\ (tools\ps\ -> 数码医生根)
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$root = Split-Path -Parent $base
$out = Join-Path (Join-Path $root "report") ("deepcheck_" + $ts + ".txt")
[System.IO.File]::WriteAllText($out, ($outLines -join "`r`n"), (New-Object System.Text.UTF8Encoding $true))
Write-Output ($outLines -join "`r`n")
Write-Output ""
Write-Output ("报告已保存: " + $out)