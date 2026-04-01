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

# Diagram 6: reading paths
$canvas = New-Canvas "Rust Wiki Reading Paths" "Three recommended routes for fresher, runtime work, and ecosystem extension."
$g = $canvas.Graphics
Draw-Box $g 110 210 470 520 "#D8E5F2" "Path A: read for orientation" @("01 overview", "02 workspace map", "03 CLI bootstrap", "04 runtime loop", "07 tools/commands/plugins", "10 problems and solutions")
Draw-Box $g 660 210 470 520 "#DDEFD9" "Path B: read before changing runtime" @("03 CLI bootstrap", "04 conversation/session", "05 config/prompt/permission", "06 API/provider/OAuth", "08 MCP/LSP/service surface", "09 tests and risks")
Draw-Box $g 1210 210 470 520 "#F7E0C5" "Path C: read before extending the platform" @("07 tools/commands/plugins", "08 MCP/LSP/service surface", "06 API/provider", "09 tests/risk", "focus on extension safety", "and integration boundaries")
Draw-Note $g 110 800 1570 130 "Use Path A in the first days, Path B before editing runtime behavior, and Path C before adding integrations, tools, or plugins."
Save-Canvas $canvas "rust-reading-paths.png"

# Diagram 7: problem domains
$canvas = New-Canvas "Rust Problem Domains" "The workspace solves multiple categories of problems, not just model calls."
$g = $canvas.Graphics
Draw-Box $g 110 180 270 170 "#D8E5F2" "Interaction" @("CLI", "REPL", "slash commands", "session UX")
Draw-Box $g 450 180 270 170 "#DDEFD9" "Agent runtime" @("conversation loop", "tool iterations", "hooks", "usage and compaction")
Draw-Box $g 790 180 270 170 "#F7E0C5" "Context" @("project instructions", "git state", "config merge", "LSP enrichment")
Draw-Box $g 1130 180 270 170 "#E6DCF2" "Control and safety" @("permission mode", "allowed tools", "sandbox", "policy hooks")
Draw-Box $g 1470 180 220 170 "#F3D8D8" "Integration" @("providers", "MCP", "plugins", "server API")
Draw-Box $g 470 500 420 180 "#FFF0CF" "Why this matters" @("Rust is not only a port of syntax.", "It is building a real agent platform", "with environment awareness, tool execution,", "state management, and extension surfaces.")
Draw-Arrow $g 245 350 680 500 "#2C5F75"
Draw-Arrow $g 585 350 680 500 "#2C5F75"
Draw-Arrow $g 925 350 680 500 "#2C5F75"
Draw-Arrow $g 1265 350 680 500 "#2C5F75"
Draw-Arrow $g 1580 350 680 500 "#2C5F75"
Save-Canvas $canvas "rust-problem-domains.png"

# Diagram 8: crate rings
$canvas = New-Canvas "Crate Rings" "A practical way to remember workspace layering from center to edge."
$g = $canvas.Graphics
Draw-Box $g 160 210 280 180 "#D8E5F2" "Ring 1" @("claw-cli", "entry and orchestration")
Draw-Box $g 520 210 280 180 "#DDEFD9" "Ring 2" @("runtime", "api", "core execution")
Draw-Box $g 880 210 280 180 "#F7E0C5" "Ring 3" @("tools", "commands", "plugins", "lsp", "mcp")
Draw-Box $g 1240 210 320 180 "#E6DCF2" "Ring 4" @("server", "compat-harness", "service and governance edges")
Draw-Box $g 360 540 1040 180 "#FFF0CF" "How to use this model" @("Entry problems usually start in ring 1.", "Agent behavior problems usually live in ring 2.", "Capability and integration problems often live in ring 3.", "Service or parity support concerns usually live in ring 4.")
Draw-Arrow $g 440 300 520 300 "#2C5F75"
Draw-Arrow $g 800 300 880 300 "#2C5F75"
Draw-Arrow $g 1160 300 1240 300 "#2C5F75"
Save-Canvas $canvas "rust-crate-rings.png"

# Diagram 9: active cli path
$canvas = New-Canvas "Active Versus Secondary CLI Paths" "Which files are on the real binary path today and which ones are likely stale or alternate."
$g = $canvas.Graphics
Draw-Box $g 120 190 420 210 "#DDEFD9" "Active path" @("Cargo binary entry -> src/main.rs", "main.rs declares: init, input, render", "parse_args() in main.rs", "run() matches CliAction", "LiveCli starts real runtime flows")
Draw-Box $g 660 190 420 210 "#F7E0C5" "Secondary file: args.rs" @("contains clap-based parser", "smaller surface than main.rs", "not imported by main.rs", "not on current execution path")
Draw-Box $g 1200 190 420 210 "#F3D8D8" "Secondary file: app.rs" @("contains alternate app abstraction", "not imported by main.rs", "useful for history or intent", "not the current binary path")
Draw-Box $g 420 520 920 170 "#FFF0CF" "Reading rule" @("When debugging or editing CLI behavior, start from main.rs first. Only read args.rs and app.rs after confirming whether the active path has changed.")
Draw-Arrow $g 540 295 660 295 "#2C5F75"
Draw-Arrow $g 1080 295 1200 295 "#2C5F75"
Save-Canvas $canvas "rust-cli-active-path.png"

# Diagram 10: session and compaction cycle
$canvas = New-Canvas "Session And Compaction Cycle" "How structured session state, usage tracking, and compaction fit into a long-running agent."
$g = $canvas.Graphics
Draw-Box $g 110 220 250 150 "#D8E5F2" "New turn" @("user message", "assistant blocks", "tool results")
Draw-Box $g 430 220 250 150 "#DDEFD9" "Structured Session" @("MessageRole", "ContentBlock", "usage per assistant message")
Draw-Box $g 750 220 250 150 "#F7E0C5" "UsageTracker" @("latest turn", "cumulative totals", "cost estimate")
Draw-Box $g 1070 220 280 150 "#E6DCF2" "Compaction decision" @("estimate tokens", "should compact?", "preserve recent messages")
Draw-Box $g 1420 220 250 150 "#F3D8D8" "Continuation summary" @("summary system message", "pending work", "recent context")
Draw-Box $g 560 560 660 170 "#FFF0CF" "Long session behavior" @("A long conversation does not have to keep every raw message forever. Rust summarizes the old part, preserves recent state, and continues with an explicit continuation context.")
Draw-Arrow $g 360 295 430 295 "#2C5F75"
Draw-Arrow $g 680 295 750 295 "#2C5F75"
Draw-Arrow $g 1000 295 1070 295 "#2C5F75"
Draw-Arrow $g 1350 295 1420 295 "#2C5F75"
Draw-Arrow $g 1540 370 880 560 "#2C5F75"
Save-Canvas $canvas "rust-session-compaction-cycle.png"

# Diagram 11: config prompt stack
$canvas = New-Canvas "Config, Prompt, Permission, And Sandbox Stack" "The four foundational layers that shape agent behavior before tool execution."
$g = $canvas.Graphics
Draw-Box $g 110 180 300 170 "#D8E5F2" "Config sources" @("user legacy + settings", "project legacy + settings", "local settings.local.json")
Draw-Box $g 470 180 300 170 "#DDEFD9" "Typed runtime config" @("model", "oauth", "mcp", "plugins", "hooks", "sandbox", "permission mode")
Draw-Box $g 830 180 300 170 "#F7E0C5" "Prompt context" @("CLAW.md chain", "git status + diff", "instruction budget", "LSP enrichment")
Draw-Box $g 1190 180 300 170 "#E6DCF2" "Permission gate" @("required tool mode", "authorize()", "prompt or deny")
Draw-Box $g 1190 450 300 170 "#F3D8D8" "Sandbox gate" @("filesystem mode", "network isolation", "namespace support", "fallback reason")
Draw-Box $g 350 500 520 170 "#FFF0CF" "Behavior outcome" @("Before any tool executes, the agent has already been shaped by merged config, contextual prompt, explicit permission rules, and the real sandbox capabilities of the host.")
Draw-Arrow $g 410 265 470 265 "#2C5F75"
Draw-Arrow $g 770 265 830 265 "#2C5F75"
Draw-Arrow $g 1130 265 1190 265 "#2C5F75"
Draw-Arrow $g 1340 350 1340 450 "#2C5F75"
Draw-Arrow $g 1190 535 870 585 "#2C5F75"
Save-Canvas $canvas "rust-config-prompt-stack.png"

# Diagram 12: api auth stream map
$canvas = New-Canvas "API Auth And Streaming Map" "How credentials, provider selection, request translation, and normalized events connect."
$g = $canvas.Graphics
Draw-Box $g 120 200 300 170 "#D8E5F2" "Auth inputs" @("API keys", "saved OAuth credentials", "refresh tokens", "env overrides")
Draw-Box $g 480 200 300 170 "#DDEFD9" "Provider resolution" @("ClawApi", "OpenAI-compatible", "xAI", "model + credential driven")
Draw-Box $g 840 200 300 170 "#F7E0C5" "Request translation" @("canonical MessageRequest", "vendor-specific HTTP shape", "tool definitions and choice")
Draw-Box $g 1200 200 300 170 "#E6DCF2" "Streaming layer" @("SSE parser", "retry + backoff", "request id handling")
Draw-Box $g 640 540 560 180 "#FFF0CF" "Normalized output" @("internal StreamEvent values: message start, deltas, content block events, message stop. This keeps runtime logic independent from vendor wire format.")
Draw-Arrow $g 420 285 480 285 "#2C5F75"
Draw-Arrow $g 780 285 840 285 "#2C5F75"
Draw-Arrow $g 1140 285 1200 285 "#2C5F75"
Draw-Arrow $g 1350 370 920 540 "#2C5F75"
Save-Canvas $canvas "rust-api-auth-stream-map.png"

# Diagram 13: plugin lifecycle
$canvas = New-Canvas "Plugin Lifecycle And Registry Flow" "How plugins move from source to installed state, enabled state, hooks, and tool execution."
$g = $canvas.Graphics
Draw-Box $g 110 180 290 160 "#D8E5F2" "Plugin source" @("bundled directory", "external path", "git/url materialized source")
Draw-Box $g 470 180 290 160 "#DDEFD9" "Manifest validation" @("plugin.json", "permissions", "hooks", "lifecycle", "tool definitions")
Draw-Box $g 830 180 320 160 "#F7E0C5" "Install registry" @("installed.json", "settings enabled state", "install root", "bundled sync")
Draw-Box $g 1220 180 360 160 "#E6DCF2" "Runtime aggregation" @("PluginRegistry", "aggregated hooks", "plugin tools", "duplicate name protection")
Draw-Box $g 420 500 780 190 "#FFF0CF" "Execution path" @("Enabled plugins contribute hooks and tools. Plugin tools shell out with structured JSON input and environment metadata, while lifecycle commands can run initialize and shutdown steps.")
Draw-Arrow $g 400 260 470 260 "#2C5F75"
Draw-Arrow $g 760 260 830 260 "#2C5F75"
Draw-Arrow $g 1150 260 1220 260 "#2C5F75"
Draw-Arrow $g 1400 340 840 500 "#2C5F75"
Save-Canvas $canvas "rust-plugin-lifecycle-map.png"

# Diagram 14: service detail
$canvas = New-Canvas "MCP, LSP, And Session Service Detail" "Three integration styles with different maturity and purposes around the core runtime."
$g = $canvas.Graphics
Draw-Box $g 110 190 420 220 "#D8E5F2" "MCP" @("typed configs for many transports", "stdio manager is most operational", "list tools, call tools,", "list/read resources")
Draw-Box $g 690 190 420 220 "#DDEFD9" "LSP" @("lazy client per language", "workspace diagnostics", "definitions and references", "prompt enrichment for coding context")
Draw-Box $g 1270 190 420 220 "#F7E0C5" "HTTP/SSE session server" @("create/list/get sessions", "stream events over SSE", "append user message", "small but real service surface")
Draw-Box $g 370 540 1060 190 "#FFF0CF" "How to interpret maturity" @("These integrations do not all mean the same thing. MCP has broad config modeling but stronger stdio execution today; LSP enriches prompts rather than replacing tools; the session server exposes state but is not yet the whole orchestration plane.")
Draw-Arrow $g 320 410 700 540 "#2C5F75"
Draw-Arrow $g 900 410 900 540 "#2C5F75"
Draw-Arrow $g 1480 410 1040 540 "#2C5F75"
Save-Canvas $canvas "rust-mcp-lsp-service-detail.png"

# Diagram 15: tests and risk map
$canvas = New-Canvas "Tests And Risk Map" "Where test coverage is visible in source and where reasoning drift can still hurt the team."
$g = $canvas.Graphics
Draw-Box $g 110 180 270 170 "#D8E5F2" "runtime tests" @("conversation loop", "config", "prompt", "compaction", "mcp stdio", "sandbox")
Draw-Box $g 450 180 270 170 "#DDEFD9" "tools tests" @("todo", "skill", "tool search", "agent", "notebook", "structured output")
Draw-Box $g 790 180 270 170 "#F7E0C5" "plugins tests" @("install/update", "enable/disable", "bundled sync", "lifecycle", "aggregated hooks")
Draw-Box $g 1130 180 270 170 "#E6DCF2" "commands tests" @("parse/help", "resume-safe set", "plugin command", "branch/worktree", "commit workflows")
Draw-Box $g 1470 180 220 170 "#F3D8D8" "lsp tests" @("mock server", "diagnostics", "definition", "references")
Draw-Box $g 370 500 1040 220 "#FFF0CF" "Risk hotspots" @("1. main.rs versus args.rs/app.rs path drift", "2. README drift versus implemented source", "3. MCP transport assumption drift", "4. no local cargo verification in the current environment")
Draw-Arrow $g 245 350 720 500 "#2C5F75"
Draw-Arrow $g 585 350 720 500 "#2C5F75"
Draw-Arrow $g 925 350 720 500 "#2C5F75"
Draw-Arrow $g 1265 350 720 500 "#2C5F75"
Draw-Arrow $g 1580 350 720 500 "#2C5F75"
Save-Canvas $canvas "rust-tests-risk-map.png"

# Diagram 16: problem solution matrix
$canvas = New-Canvas "Problem To Solution Matrix" "A visual summary of what the Rust workspace is solving and which crates carry the solution."
$g = $canvas.Graphics
Draw-Box $g 110 180 300 140 "#D8E5F2" "Prompt entry" @("claw-cli", "CliAction parser", "REPL or one-shot")
Draw-Box $g 470 180 300 140 "#DDEFD9" "Agent execution" @("runtime conversation loop", "session, usage, compaction")
Draw-Box $g 830 180 300 140 "#F7E0C5" "Model connection" @("api providers", "OAuth, retry, SSE")
Draw-Box $g 1190 180 300 140 "#E6DCF2" "Action layer" @("tools, commands, plugins")
Draw-Box $g 550 450 560 180 "#FFF0CF" "Context and integration" @("prompt builder, config loader, permissions, sandbox, MCP, LSP, session server, compat harness")
Draw-Arrow $g 410 250 470 250 "#2C5F75"
Draw-Arrow $g 770 250 830 250 "#2C5F75"
Draw-Arrow $g 1130 250 1190 250 "#2C5F75"
Draw-Arrow $g 260 320 640 450 "#2C5F75"
Draw-Arrow $g 620 320 760 450 "#2C5F75"
Draw-Arrow $g 980 320 1000 450 "#2C5F75"
Draw-Arrow $g 1340 320 1020 450 "#2C5F75"
Save-Canvas $canvas "rust-problem-solution-matrix.png"

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
