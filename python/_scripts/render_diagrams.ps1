Add-Type -AssemblyName System.Drawing

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonGuideRoot = Split-Path -Parent $scriptRoot
$assetRoot = Join-Path $pythonGuideRoot "assets"
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

$brushInk = New-Brush "#16324F"
$brushMuted = New-Brush "#51606F"
$brushCanvas = New-Brush "#F6F3EE"
$penBorder = New-Object System.Drawing.Pen (New-Color "#16324F"), 2
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
    $noteBrush = New-Brush "#FFF7D9"
    $notePen = New-Object System.Drawing.Pen (New-Color "#A36F00"), 2
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

# Diagram 1: module map
$canvas = New-Canvas "Python Port Module Map" "How CLI, runtime simulation, persistence, and reference data connect."
$g = $canvas.Graphics
Draw-Box $g 90 180 260 150 "#D8E7F5" "CLI entrypoint" @("main.py", "argparse subcommands", "summary / route / bootstrap")
Draw-Box $g 420 180 280 150 "#DCEFD9" "Inventory mirror" @("commands.py", "tools.py", "lookup + render", "execution shim metadata")
Draw-Box $g 770 180 280 150 "#F8E1C6" "Runtime simulation" @("runtime.py", "query_engine.py", "turn loop", "routing + stream events")
Draw-Box $g 1120 180 280 150 "#E9DDF5" "Persistence" @("transcript.py", "session_store.py", "flush + replay", "save_session / load_session")
Draw-Box $g 1450 180 260 150 "#F7D8D8" "Reference data" @("commands snapshot", "tools snapshot", "archive surface", "subsystems metadata")
Draw-Box $g 250 460 320 170 "#D8E7F5" "Setup and context" @("setup.py", "context.py", "prefetch stubs", "deferred init")
Draw-Box $g 640 460 320 170 "#DCEFD9" "Execution registry" @("MirroredCommand", "MirroredTool", "registry bridge", "no real business logic")
Draw-Box $g 1030 460 320 170 "#F8E1C6" "Analysis and audit" @("port_manifest.py", "command_graph.py", "tool_pool.py", "parity_audit.py")
Draw-Box $g 1420 460 290 170 "#E9DDF5" "Placeholder subsystems" @("assistant / bridge / utils", "__init__.py metadata", "archive name", "sample files")
Draw-Arrow $g 350 255 420 255 "#355C7D"
Draw-Arrow $g 700 255 770 255 "#355C7D"
Draw-Arrow $g 1050 255 1120 255 "#355C7D"
Draw-Arrow $g 1400 255 1450 255 "#355C7D"
Draw-Arrow $g 220 330 300 460 "#355C7D"
Draw-Arrow $g 560 330 690 460 "#355C7D"
Draw-Arrow $g 910 330 1120 460 "#355C7D"
Draw-Arrow $g 1580 330 1560 460 "#355C7D"
Draw-Note $g 90 760 1620 170 "Key reading rule: the Python layer mostly mirrors surface area and architecture intent. It is strong at inventory, reporting, and lightweight simulation. It is not yet a full production runtime like the original system."
Save-Canvas $canvas "python-module-map.png"

# Diagram 2: runtime data flow
$canvas = New-Canvas "Runtime Data Flow" "Prompt routing, registry lookup, state mutation, transcript buffering, and session persistence."
$g = $canvas.Graphics
Draw-Box $g 100 190 250 120 "#D8E7F5" "1. User prompt" @("Input text from CLI", "example: review MCP tool")
Draw-Box $g 430 190 280 120 "#DCEFD9" "2. route_prompt()" @("tokenize prompt", "score command/tool entries", "select top matches")
Draw-Box $g 790 190 280 120 "#F8E1C6" "3. ExecutionRegistry" @("map names to shims", "build command/tool messages")
Draw-Box $g 1150 190 280 120 "#E9DDF5" "4. submit_message()" @("mutate turn state", "append prompt", "update usage")
Draw-Box $g 1510 190 190 120 "#F7D8D8" "5. TurnResult" @("output", "usage", "stop_reason")
Draw-Box $g 540 470 280 140 "#F8E1C6" "TranscriptStore" @("append()", "compact()", "replay()", "flush()")
Draw-Box $g 980 470 320 140 "#E9DDF5" "SessionStore" @("StoredSession", "save_session()", "load_session()", "JSON in .port_sessions")
Draw-Box $g 260 760 430 140 "#FFF0CF" "Important side effect" @("stream_submit_message() also calls submit_message().", "If orchestration calls both stream_submit_message() and submit_message(),", "the same prompt gets counted twice.")
Draw-Box $g 860 760 550 140 "#FFF0CF" "How to read this flow" @("Routing and execution are mostly metadata-driven.", "The real state change happens inside QueryEnginePort.", "Persistence is prompt-history oriented, not full conversation replay.")
Draw-Arrow $g 350 250 430 250 "#355C7D"
Draw-Arrow $g 710 250 790 250 "#355C7D"
Draw-Arrow $g 1070 250 1150 250 "#355C7D"
Draw-Arrow $g 1430 250 1510 250 "#355C7D"
Draw-Arrow $g 1220 310 1120 470 "#355C7D"
Draw-Arrow $g 1220 310 1140 470 "#355C7D"
Draw-Arrow $g 1150 540 980 540 "#355C7D"
Save-Canvas $canvas "python-runtime-dataflow.png"

# Diagram 3: bootstrap sequence
$canvas = New-Canvas "Bootstrap Session Sequence" "What happens when CLI runs bootstrap on the Python port."
$g = $canvas.Graphics
Draw-Box $g 90 180 240 110 "#D8E7F5" "CLI command" @("python -m src.main", "bootstrap <prompt>")
Draw-Box $g 90 330 240 110 "#D8E7F5" "PortRuntime" @("bootstrap_session()", "orchestration entry")
Draw-Box $g 420 180 270 110 "#DCEFD9" "Context + setup" @("build_port_context()", "run_setup(trusted=True)")
Draw-Box $g 420 330 270 110 "#DCEFD9" "Routing" @("route_prompt()", "collect matches")
Draw-Box $g 750 180 290 110 "#F8E1C6" "Execution registry" @("command shims", "tool shims")
Draw-Box $g 750 330 290 110 "#F8E1C6" "QueryEnginePort" @("stream_submit_message()", "submit_message()", "persist_session()")
Draw-Box $g 1090 180 280 110 "#E9DDF5" "Session file" @(".port_sessions/<id>.json", "prompt history + usage")
Draw-Box $g 1090 330 280 110 "#E9DDF5" "RuntimeSession report" @("markdown report", "startup steps", "history log")
Draw-Box $g 1420 250 290 140 "#FFF0CF" "Known issue" @("Current bootstrap flow submits the same prompt twice:", "1) inside stream_submit_message()", "2) then again via submit_message()")
Draw-Arrow $g 210 290 210 330 "#355C7D"
Draw-Arrow $g 330 235 420 235 "#355C7D"
Draw-Arrow $g 330 385 420 385 "#355C7D"
Draw-Arrow $g 690 235 750 235 "#355C7D"
Draw-Arrow $g 690 385 750 385 "#355C7D"
Draw-Arrow $g 1040 235 1090 235 "#355C7D"
Draw-Arrow $g 1040 385 1090 385 "#355C7D"
Draw-Arrow $g 1370 385 1420 320 "#355C7D"
Save-Canvas $canvas "python-bootstrap-sequence.png"

# Diagram 4: session lifecycle
$canvas = New-Canvas "Session Lifecycle" "From a new engine to persisted JSON, with stop conditions and transcript state."
$g = $canvas.Graphics
Draw-Box $g 130 220 240 120 "#D8E7F5" "New engine" @("from_workspace()", "or from_saved_session()")
Draw-Box $g 470 220 240 120 "#DCEFD9" "Ready state" @("has session_id", "keeps mutable_messages", "tracks total_usage")
Draw-Box $g 810 220 260 120 "#F8E1C6" "Processing turn" @("submit_message()", "build output", "update usage")
Draw-Box $g 1190 140 260 120 "#E9DDF5" "Completed" @("stop_reason=completed", "session can continue")
Draw-Box $g 1190 300 260 120 "#F7D8D8" "Budget stop" @("stop_reason=max_budget_reached")
Draw-Box $g 1190 460 260 120 "#F7D8D8" "Turn limit stop" @("stop_reason=max_turns_reached")
Draw-Box $g 810 520 260 120 "#FFF0CF" "Persist session" @("flush_transcript()", "save_session()", "write JSON file")
Draw-Box $g 470 520 240 120 "#E9DDF5" "Transcript state" @("entries in memory", "compact if needed", "flushed flag only")
Draw-Arrow $g 370 280 470 280 "#355C7D"
Draw-Arrow $g 710 280 810 280 "#355C7D"
Draw-Arrow $g 1070 280 1190 200 "#355C7D"
Draw-Arrow $g 1070 280 1190 360 "#355C7D"
Draw-Arrow $g 1070 280 1190 520 "#355C7D"
Draw-Arrow $g 940 340 940 520 "#355C7D"
Draw-Arrow $g 810 580 710 580 "#355C7D"
Draw-Arrow $g 590 520 590 340 "#355C7D"
Draw-Note $g 130 760 1580 150 "Flush does not mean full transcript persistence. In the current code, flush only marks the transcript buffer as flushed, while the session JSON stores prompt history and token totals."
Save-Canvas $canvas "python-session-lifecycle.png"

# Diagram 5: snapshot and parity
$canvas = New-Canvas "Snapshot, Subsystem Metadata, and Parity Audit" "How the Python port reads frozen reference data and measures surface coverage."
$g = $canvas.Graphics
Draw-Box $g 90 180 310 150 "#D8E7F5" "commands_snapshot.json" @("207 mirrored command entries", "name", "responsibility", "source_hint")
Draw-Box $g 90 390 310 150 "#D8E7F5" "tools_snapshot.json" @("184 mirrored tool entries", "name", "responsibility", "source_hint")
Draw-Box $g 90 600 310 150 "#D8E7F5" "subsystems/*.json" @("archive_name", "module_count", "sample_files", "porting_note")
Draw-Box $g 510 180 340 150 "#DCEFD9" "commands.py / tools.py" @("load snapshot once", "lru_cache(maxsize=1)", "lookup + render + shim execution")
Draw-Box $g 510 420 340 150 "#DCEFD9" "placeholder packages" @("assistant / bridge / utils", "__init__.py exposes metadata", "keeps subsystem names visible")
Draw-Box $g 980 180 330 150 "#F8E1C6" "command_graph / tool_pool" @("segment commands", "filter tools by mode", "inventory reporting")
Draw-Box $g 980 420 330 150 "#F8E1C6" "parity_audit.py" @("root file coverage", "directory coverage", "command/tool entry ratio")
Draw-Box $g 1440 300 270 180 "#FFF0CF" "How to interpret parity" @("High command/tool counts do not mean full runtime parity.", "The Python layer mirrors surface area much better than it mirrors execution depth.")
Draw-Arrow $g 400 255 510 255 "#355C7D"
Draw-Arrow $g 400 465 510 250 "#355C7D"
Draw-Arrow $g 400 675 510 495 "#355C7D"
Draw-Arrow $g 850 255 980 255 "#355C7D"
Draw-Arrow $g 850 495 980 495 "#355C7D"
Draw-Arrow $g 1310 255 1440 350 "#355C7D"
Draw-Arrow $g 1310 495 1440 430 "#355C7D"
Save-Canvas $canvas "python-snapshot-parity-map.png"

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
