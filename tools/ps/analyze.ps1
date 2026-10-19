param(
  [string]$Facts = "facts.txt",
  [string]$Out = "ai_result.txt",
  [string]$Model = "qwen2.5:3b",
  [int]$Port = 11435
)
$ErrorActionPreference = "Stop"
# DoctorUSB v3: ask local Ollama for Chinese diagnosis

$promptTpl = Join-Path $PSScriptRoot "..\prompt.txt"
$ctx = Get-Content -Raw -Encoding UTF8 $promptTpl
$facts = Get-Content -Raw -Encoding UTF8 $Facts
$full = $ctx + "`r`n`r`n===== 体检事实数据(键=值) =====`r`n" + $facts

$body = @{ model = $Model; prompt = $full; stream = $false; options = @{ temperature = 0.3; num_predict = 1500 } } | ConvertTo-Json -Depth 5 -Compress
$resp = Invoke-RestMethod -Uri ("http://127.0.0.1:{0}/api/generate" -f $Port) -Method Post -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec 600
$text = $resp.response
$header = "======== DoctorUSB AI Report  " + (Get-Date) + "  ========" + "`r`nModel: " + $Model + " (offline on USB)"
$fullOut = $header + "`r`n`r`n" + $text
[System.IO.File]::WriteAllText($Out, $fullOut, (New-Object System.Text.UTF8Encoding $true))
Write-Host ""
Write-Host $text