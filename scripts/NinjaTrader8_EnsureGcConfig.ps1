<#
.SYNOPSIS
  Keeps the GC performance paragraph in NinjaTrader.exe.config across updates.

.DESCRIPTION
  Every NinjaTrader update ships a fresh NinjaTrader.exe.config and drops the
  tuning paragraph (gcServer / gcConcurrent / gcAllowVeryLargeObjects) from the
  <runtime> section. Copying an old config over the new one is WRONG: the new
  file carries updated assembly binding redirects the new build needs. So this
  script MERGES: it reads the installed config, and only if the paragraph is
  missing it inserts the elements at the top of <runtime>, after writing a
  dated backup beside the file. Everything else in the file is left byte-exact.

  Idempotent: run it any time. Nothing to do -> exit 0, no write.
  Needs administrator rights to write under Program Files (the launcher is
  already elevated; by hand, run from an elevated prompt).

.PARAMETER ConfigPath
  The installed config. Default: C:\Program Files\NinjaTrader 8\bin\NinjaTrader.exe.config

.PARAMETER ParagraphPath
  Optional XML fragment to use instead of the built-in paragraph, so the values
  can be changed without editing this script. Must be a fragment whose root is
  <runtime> holding the elements to merge.

.PARAMETER BackupDir
  Where the installer's untouched config is kept before the merge. Default: a
  config-backups folder beside this script, so Program Files stays exactly as
  NinjaTrader shipped it and the backups survive an uninstall.

.PARAMETER Quiet
  No pause at the end (for launchers).
#>
param(
  [string]$ConfigPath = 'C:\Program Files\NinjaTrader 8\bin\NinjaTrader.exe.config',
  [string]$ParagraphPath = (Join-Path $PSScriptRoot 'NinjaTrader8_GcParagraph.xml'),
  [string]$BackupDir = (Join-Path $PSScriptRoot 'config-backups'),
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
function Done([int]$code, [string]$msg) { Write-Host $msg; if (-not $Quiet) { Read-Host 'Press Enter to close' | Out-Null }; exit $code }

# The paragraph as AlphaWolfTrader keeps it (2025-12-02). gcServer stays false
# here on purpose: the launcher turns server GC on through COMPlus_gcServer=1,
# which wins over the config, so machines launched by hand keep the default.
$builtIn = @'
<runtime>
  <!-- ============================================== -->
  <!-- GC PERFORMANCE OPTIMIZATIONS FOR TRADING -->
  <!-- Added by AlphaWolfTrader - 2025-12-02 -->
  <!-- ============================================== -->
  <!-- Server GC: Uses dedicated GC threads per CPU core -->
  <!-- Better for multi-core systems with heavy workloads -->
  <gcServer enabled="false" />
  <!-- Concurrent/Background GC: Reduces pause times -->
  <!-- GC runs mostly in background, minimizing UI freezes -->
  <gcConcurrent enabled="true" />
  <!-- Allow large objects (>2GB arrays) if needed -->
  <!-- Typically not required, but enables future capability -->
  <gcAllowVeryLargeObjects enabled="true" />
  <!-- ============================================== -->
  <!-- END GC OPTIMIZATIONS -->
  <!-- ============================================== -->
</runtime>
'@

if (-not (Test-Path -LiteralPath $ConfigPath)) { Done 1 "STOP: config not found: $ConfigPath" }

$fragmentText = if (Test-Path -LiteralPath $ParagraphPath) { Get-Content -LiteralPath $ParagraphPath -Raw } else { $builtIn }
$frag = New-Object System.Xml.XmlDocument; $frag.PreserveWhitespace = $true; $frag.LoadXml($fragmentText)
if ($frag.DocumentElement.Name -ne 'runtime') { Done 1 "STOP: the paragraph fragment's root must be <runtime>, got <$($frag.DocumentElement.Name)>" }
$wanted = @($frag.DocumentElement.ChildNodes | Where-Object { $_.NodeType -eq 'Element' } | ForEach-Object { $_.Name })
if ($wanted.Count -eq 0) { Done 1 'STOP: the paragraph holds no elements' }

$doc = New-Object System.Xml.XmlDocument; $doc.PreserveWhitespace = $true
$doc.Load($ConfigPath)
$runtime = $doc.SelectSingleNode('/configuration/runtime')
if (-not $runtime) { Done 1 'STOP: the config has no <configuration><runtime> section; not guessing where to put the paragraph.' }

$present = @($runtime.ChildNodes | Where-Object { $_.NodeType -eq 'Element' -and $wanted -contains $_.Name } | ForEach-Object { $_.Name })
$missing = @($wanted | Where-Object { $present -notcontains $_ })
Write-Host " Config  : $ConfigPath"
Write-Host " Wanted  : $($wanted -join ', ')"
Write-Host " Present : $(if ($present) { $present -join ', ' } else { 'none' })"
if ($missing.Count -eq 0) { Done 0 ' STATE: paragraph present - nothing to do.' }

# Back up (outside Program Files), then insert the whole fragment (comments included) at the top of <runtime>.
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
try { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null } catch { Done 1 "STOP: could not create the backup folder $BackupDir ($($_.Exception.Message))" }
$backup = Join-Path $BackupDir "NinjaTrader.exe.config.before-gc-$stamp"
try { Copy-Item -LiteralPath $ConfigPath -Destination $backup -Force } catch { Done 1 "STOP: could not write the backup ($($_.Exception.Message))." }

$anchor = $runtime.FirstChild
foreach ($node in @($frag.DocumentElement.ChildNodes)) {
  if ($node.NodeType -eq 'Element' -and $present -contains $node.Name) { continue }   # keep an existing element, do not duplicate it
  $imported = $doc.ImportNode($node, $true)
  if ($anchor) { [void]$runtime.InsertBefore($imported, $anchor) } else { [void]$runtime.AppendChild($imported) }
}
try { $doc.Save($ConfigPath) } catch { Done 1 "STOP: could not write the config ($($_.Exception.Message)). Backup is at $backup" }

# Verify by re-reading the file.
$check = New-Object System.Xml.XmlDocument; $check.Load($ConfigPath)
$now = @($check.SelectSingleNode('/configuration/runtime').ChildNodes | Where-Object { $_.NodeType -eq 'Element' -and $wanted -contains $_.Name } | ForEach-Object { $_.Name })
$still = @($wanted | Where-Object { $now -notcontains $_ })
if ($still.Count -gt 0) { Done 1 " STOP: wrote the file but these are still missing: $($still -join ', '). Backup is at $backup" }
Done 0 " DONE: inserted $($missing -join ', '). Backup of the installer's file: $backup"
