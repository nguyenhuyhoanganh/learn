Add-Type -AssemblyName System.Drawing

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$rustGuideRoot = Split-Path -Parent $scriptRoot
$assetRoot = Join-Path $rustGuideRoot "assets"
New-Item -ItemType Directory -Force -Path $assetRoot | Out-Null

function New-Color([string]$hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function New-Brush([string]$hex) {
    return New-Object System.Drawing.SolidBrush (New-Color $hex)
}

function New-PenColor([string]$hex, [float]$width = 3) {
    $pen = New-Object System.Drawing.Pen (New-Color $hex), $width
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
    return $pen
}

function New-Rect([float]$x, [float]$y, [float]$w, [float]$h) {
    return New-Object System.Drawing.RectangleF $x, $y, $w, $h
}

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
$fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Regular)
$fontBoxTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fontSmall = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)

$brushInk = New-Brush "#143642"
$brushMuted = New-Brush "#48525D"
$brushCanvas = New-Brush "#F4F1EA"
$penBorder = New-Object System.Drawing.Pen (New-Color "#143642"), 2
$stringLeft = New-Object System.Drawing.StringFormat
$stringLeft.Alignment = [System.Drawing.StringAlignment]::Near
$stringLeft.LineAlignment = [System.Drawing.StringAlignment]::Near

function New-Canvas([string]$title, [string]$subtitle) {
    $bmp = New-Object System.Drawing.Bitmap 1800, 1100
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.FillRectangle($brushCanvas, 0, 0, 1800, 1100)
    $g.DrawString($title, $fontTitle, $brushInk, (New-Rect 70 40 1660 60), $stringLeft)
    $g.DrawString($subtitle, $fontSubtitle, $brushMuted, (New-Rect 70 90 1660 40), $stringLeft)
    return @{ Bitmap = $bmp; Graphics = $g }
}

function Draw-Box(
    $g,
    [float]$x,
    [float]$y,
    [float]$w,
    [float]$h,
    [string]$fillHex,
    [string]$title,
    [string[]]$lines
) {
    $rect = New-Rect $x $y $w $h
    $fillBrush = New-Brush $fillHex
    $g.FillRectangle($fillBrush, $rect)
    $g.DrawRectangle($penBorder, $x, $y, $w, $h)
    $g.DrawString($title, $fontBoxTitle, $brushInk, (New-Rect ($x + 18) ($y + 14) ($w - 36) 32), $stringLeft)
    $bodyText = [string]::Join("`n", $lines)
    $g.DrawString($bodyText, $fontBody, $brushMuted, (New-Rect ($x + 18) ($y + 54) ($w - 36) ($h - 70)), $stringLeft)
    $fillBrush.Dispose()
}

function Draw-Arrow($g, [float]$x1, [float]$y1, [float]$x2, [float]$y2, [string]$hex) {
    $pen = New-PenColor $hex 4
    $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    $pen.Dispose()
}

function Draw-Note($g, [float]$x, [float]$y, [float]$w, [float]$h, [string]$text) {
    $noteBrush = New-Brush "#FFF4C7"
    $notePen = New-Object System.Drawing.Pen (New-Color "#9A6B00"), 2
    $g.FillRectangle($noteBrush, $x, $y, $w, $h)
    $g.DrawRectangle($notePen, $x, $y, $w, $h)
    $g.DrawString($text, $fontSmall, $brushInk, (New-Rect ($x + 14) ($y + 12) ($w - 28) ($h - 24)), $stringLeft)
    $noteBrush.Dispose()
    $notePen.Dispose()
}

function Save-Canvas($canvas, [string]$fileName) {
    $outPath = Join-Path $assetRoot $fileName
    $canvas.Bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Dispose()
}

# Diagram 1: workspace map
$canvas = New-Canvas "Rust Workspace Map" "How the multi-crate runtime is split into entry, core, capability, and integration layers."
$g = $canvas.Graphics
Draw-Box $g 90 180 270 150 "#D8E5F2" "CLI entry" @("claw-cli", "main.rs real entrypoint", "REPL, login, resume")
Draw-Box $g 430 180 300 150 "#DDEFD9" "Runtime core" @("runtime", "conversation loop", "session, config, prompt", "permissions, compaction")
Draw-Box $g 800 180 260 150 "#F7E0C5" "Model IO" @("api", "provider selection", "stream normalization", "OAuth and retries")
Draw-Box $g 1130 180 290 150 "#E6DCF2" "Capability layer" @("tools", "commands", "plugins", "built-in and extensible actions")
Draw-Box $g 1490 180 230 150 "#F3D8D8" "Parity support" @("compat-harness", "extract TS manifests", "bootstrap intent")
Draw-Box $g 260 470 280 170 "#D8E5F2" "Code intelligence" @("lsp", "diagnostics", "definitions", "references to prompt")
Draw-Box $g 620 470 280 170 "#DDEFD9" "External tool fabric" @("mcp", "typed transports", "stdio manager", "tool and resource bridge")
Draw-Box $g 980 470 280 170 "#F7E0C5" "Service surface" @("server", "HTTP routes", "SSE session events")
Draw-Box $g 1340 470 360 170 "#E6DCF2" "System theme" @("Runtime is real, not only mirror.", "Multiple crates are active execution code.", "Some docs lag behind current source.")
Draw-Arrow $g 360 255 430 255 "#2C5F75"
Draw-Arrow $g 730 255 800 255 "#2C5F75"
Draw-Arrow $g 1060 255 1130 255 "#2C5F75"
Draw-Arrow $g 1420 255 1490 255 "#2C5F75"
Draw-Arrow $g 550 330 400 470 "#2C5F75"
Draw-Arrow $g 550 330 760 470 "#2C5F75"
Draw-Arrow $g 980 330 1120 470 "#2C5F75"
Draw-Arrow $g 1280 330 1520 470 "#2C5F75"
Draw-Note $g 90 770 1620 170 "Critical reading rule: claw-cli/src/main.rs is the active path. args.rs and app.rs exist but are not wired into the current binary entry. Read them as secondary or stale paths unless wiring changes."
Save-Canvas $canvas "rust-workspace-map.png"

# Diagram 2: cli bootstrap map
$canvas = New-Canvas "CLI Bootstrap And REPL Flow" "How user input becomes a configured runtime turn or an interactive REPL session."
$g = $canvas.Graphics
Draw-Box $g 100 180 240 120 "#D8E5F2" "User input" @("command line", "one-shot prompt", "or empty args for REPL")
Draw-Box $g 420 180 260 120 "#DDEFD9" "parse_args()" @("flags", "model alias", "allowed tools", "permission mode")
Draw-Box $g 760 180 260 120 "#F7E0C5" "CliAction" @("Prompt", "Repl", "Login", "Resume", "Utility actions")
Draw-Box $g 1100 100 280 120 "#E6DCF2" "Config and prompt" @("ConfigLoader", "load_system_prompt()", "ProjectContext")
Draw-Box $g 1100 260 280 120 "#E6DCF2" "Plugin and tool setup" @("PluginManager", "GlobalToolRegistry", "PermissionPolicy")
Draw-Box $g 1460 180 240 120 "#F3D8D8" "LiveCli" @("run turn", "or start REPL loop")
Draw-Box $g 390 500 300 140 "#FFF0CF" "Login branch" @("PKCE + state", "loopback callback", "save OAuth credentials")
Draw-Box $g 770 500 300 140 "#FFF0CF" "Resume branch" @("load Session JSON", "allow resume-safe slash commands")
Draw-Box $g 1150 500 420 140 "#FFF0CF" "Utility branch" @("dump manifests", "bootstrap plan", "system prompt", "agents, skills, version, init")
Draw-Arrow $g 340 240 420 240 "#2C5F75"
Draw-Arrow $g 680 240 760 240 "#2C5F75"
Draw-Arrow $g 1020 240 1100 160 "#2C5F75"
Draw-Arrow $g 1020 240 1100 320 "#2C5F75"
Draw-Arrow $g 1380 160 1460 220 "#2C5F75"
Draw-Arrow $g 1380 320 1460 240 "#2C5F75"
Draw-Arrow $g 890 300 540 500 "#2C5F75"
Draw-Arrow $g 890 300 920 500 "#2C5F75"
Draw-Arrow $g 980 280 1320 500 "#2C5F75"
Save-Canvas $canvas "rust-cli-bootstrap-map.png"

# Diagram 3: conversation runtime flow
$canvas = New-Canvas "ConversationRuntime Flow" "How the Rust runtime loops through assistant output, tool calls, hooks, and session updates."
$g = $canvas.Graphics
Draw-Box $g 90 180 240 120 "#D8E5F2" "1. User message" @("append into Session", "role = User")
Draw-Box $g 400 180 260 120 "#DDEFD9" "2. Build ApiRequest" @("system prompt", "message history")
Draw-Box $g 730 180 260 120 "#F7E0C5" "3. ApiClient.stream" @("provider emits AssistantEvent")
Draw-Box $g 1060 180 280 120 "#E6DCF2" "4. Build assistant msg" @("text blocks", "tool use blocks", "usage")
Draw-Box $g 1410 180 300 120 "#F3D8D8" "5. Push to Session" @("assistant message", "record usage")
Draw-Box $g 350 460 280 150 "#D8E5F2" "6. Extract tool uses" @("pending tool calls", "if none -> finish turn")
Draw-Box $g 700 460 280 150 "#DDEFD9" "7. Safety gate" @("PermissionPolicy", "runtime pre-hook")
Draw-Box $g 1050 460 280 150 "#F7E0C5" "8. ToolExecutor" @("built-in or plugin tool", "execute input")
Draw-Box $g 1400 460 300 150 "#E6DCF2" "9. Post processing" @("post-hook", "tool result message", "loop again if needed")
Draw-Box $g 540 780 720 150 "#FFF0CF" "Turn summary" @("assistant_messages", "tool_results", "iterations", "usage", "stop when no tool use or max_iterations is hit")
Draw-Arrow $g 330 240 400 240 "#2C5F75"
Draw-Arrow $g 660 240 730 240 "#2C5F75"
Draw-Arrow $g 990 240 1060 240 "#2C5F75"
Draw-Arrow $g 1340 240 1410 240 "#2C5F75"
Draw-Arrow $g 1480 300 510 460 "#2C5F75"
Draw-Arrow $g 630 535 700 535 "#2C5F75"
Draw-Arrow $g 980 535 1050 535 "#2C5F75"
Draw-Arrow $g 1330 535 1400 535 "#2C5F75"
Draw-Arrow $g 1550 610 920 780 "#2C5F75"
Save-Canvas $canvas "rust-conversation-runtime-flow.png"

# Diagram 4: provider tool plugin stack
$canvas = New-Canvas "Provider, Tool, Command, And Plugin Stack" "How model-facing definitions, runtime policy, and extensibility fit together."
$g = $canvas.Graphics
Draw-Box $g 110 170 280 140 "#D8E5F2" "Provider layer" @("api", "Claw / OpenAI / xAI", "stream normalized events")
Draw-Box $g 470 170 320 140 "#DDEFD9" "Runtime tool boundary" @("ToolDefinition list", "tool choice", "tool name + JSON input")
Draw-Box $g 870 170 320 140 "#F7E0C5" "GlobalToolRegistry" @("merge built-in + plugin tools", "validate conflicts", "allowed subset normalization")
Draw-Box $g 1270 170 330 140 "#E6DCF2" "Permission mapping" @("tool -> required permission", "runtime authorize() gate")
Draw-Box $g 250 460 290 170 "#D8E5F2" "Commands" @("slash command registry", "git workflows", "plugin, agent, skill UX")
Draw-Box $g 620 460 320 170 "#DDEFD9" "Built-in tools" @("bash, read/write/edit", "search, web, todo", "agent, notebook, config")
Draw-Box $g 1020 460 320 170 "#F7E0C5" "Plugin tools" @("manifest-defined", "hooked lifecycle", "shell-out execution")
Draw-Box $g 1420 460 260 170 "#E6DCF2" "Extensibility rules" @("name conflict deny", "enabled state", "bundled sync")
Draw-Arrow $g 390 240 470 240 "#2C5F75"
Draw-Arrow $g 790 240 870 240 "#2C5F75"
Draw-Arrow $g 1190 240 1270 240 "#2C5F75"
Draw-Arrow $g 1030 310 780 460 "#2C5F75"
Draw-Arrow $g 1030 310 1180 460 "#2C5F75"
Draw-Arrow $g 1410 310 1540 460 "#2C5F75"
Draw-Arrow $g 710 630 410 630 "#2C5F75"
Draw-Note $g 110 780 1570 150 "Important reality check: the plugin system is materially implemented in source code. If docs say it is only planned, trust the source and update the docs."
Save-Canvas $canvas "rust-provider-tool-plugin-stack.png"

# Diagram 5: service surface
$canvas = New-Canvas "Integration And Service Surface" "MCP, LSP, session server, and upstream compatibility support around the runtime."
$g = $canvas.Graphics
Draw-Box $g 110 180 290 150 "#D8E5F2" "MCP typed config" @("stdio, sse, http, ws,", "sdk, managed proxy", "scope-aware server config")
Draw-Box $g 470 180 300 150 "#DDEFD9" "MCP stdio manager" @("spawn process", "JSON-RPC initialize", "index tools/resources", "call and shutdown")
Draw-Box $g 840 180 300 150 "#F7E0C5" "LSP manager" @("lazy client start", "diagnostics", "definition", "references")
Draw-Box $g 1210 180 300 150 "#E6DCF2" "Prompt enrichment" @("render LSP section", "append to system prompt")
Draw-Box $g 660 470 320 170 "#D8E5F2" "Session server" @("POST /sessions", "GET /sessions", "GET /sessions/{id}", "SSE /events stream")
Draw-Box $g 1040 470 330 170 "#DDEFD9" "Compat harness" @("read TS upstream", "extract commands/tools", "extract bootstrap plan")
Draw-Box $g 1430 470 250 170 "#F7E0C5" "Operational note" @("MCP transport support", "is broader in config", "than in active manager code")
Draw-Arrow $g 400 255 470 255 "#2C5F75"
Draw-Arrow $g 1140 255 1210 255 "#2C5F75"
Draw-Arrow $g 990 255 1040 470 "#2C5F75"
Draw-Arrow $g 990 330 1360 470 "#2C5F75"
Draw-Arrow $g 770 330 820 470 "#2C5F75"
Draw-Arrow $g 1370 555 1430 555 "#2C5F75"
Draw-Note $g 110 790 1570 140 "The architecture already knows many integration modes. But the most mature operational paths visible in source are: stdio-based MCP, prompt-bound LSP enrichment, and a small but real HTTP/SSE session server."
Save-Canvas $canvas "rust-service-surface.png"

$fontTitle.Dispose()
$fontSubtitle.Dispose()
$fontBoxTitle.Dispose()
$fontBody.Dispose()
$fontSmall.Dispose()
$brushInk.Dispose()
$brushMuted.Dispose()
$brushCanvas.Dispose()
$penBorder.Dispose()
$stringLeft.Dispose()
