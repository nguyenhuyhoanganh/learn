# Claw CLI, Bootstrap Và REPL

## 1. Entry point thật nằm ở đâu

Entry point của binary `claw` nằm ở:

- `claw-code/rust/crates/claw-cli/src/main.rs`

Luồng tối cao của file này rất ngắn:

1. `main()`
2. gọi `run()`
3. `run()` đọc `env::args()`
4. `parse_args()` map input thành `CliAction`
5. `match CliAction` để rẽ sang đúng flow

## 2. `CliAction` thể hiện những mode nào

`main.rs` định nghĩa các action chính:

- `DumpManifests`
- `BootstrapPlan`
- `Agents`
- `Skills`
- `PrintSystemPrompt`
- `Version`
- `ResumeSession`
- `Prompt`
- `Login`
- `Logout`
- `Init`
- `Repl`
- `Help`

Điều này nói lên một sự thật quan trọng:

CLI không chỉ là “chat prompt”.
Nó còn là trung tâm vận hành cho:

- bootstrap inspection
- OAuth lifecycle
- session resume
- agent/skill inventory
- init project
- render system prompt

## 3. Parser đang hoạt động ra sao

Khác với `args.rs` dùng `clap`, `main.rs` parse argument thủ công bằng `parse_args()`.

Nó xử lý:

- `--version`
- `--model`
- `--output-format`
- `--permission-mode`
- `--dangerously-skip-permissions`
- `--allowedTools` hoặc `--allowed-tools`
- `-p`
- `--print`
- `--resume`

Ngoài ra còn support:

- `prompt <text>`
- nhập thẳng chuỗi prompt mà không cần subcommand
- gọi trực tiếp slash-style như `/agents`, `/skills`

## 4. Alias model được xử lý sớm

CLI resolve model alias ngay ở lớp argument:

- `opus` -> `claude-opus-4-6`
- `sonnet` -> `claude-sonnet-4-6`
- `haiku` -> `claude-haiku-4-5-20251213`

Lợi ích:

- UX ngắn gọn hơn
- phía dưới ít phải xử lý alias lặp lại

Rủi ro:

- alias bị hard-code trong CLI, nên khi model roadmap thay đổi cần cập nhật đồng bộ

## 5. Hai mode dùng quan trọng nhất

### 5.1. One-shot prompt

Có 3 cách phổ biến:

- `claw prompt "..."`
- `claw -p "..."`
- `claw "..."`

Tất cả cuối cùng quy về `CliAction::Prompt`.

Sau đó CLI tạo `LiveCli` và gọi:

- `run_turn_with_output(&prompt, output_format)`

### 5.2. REPL

Khi không có đối số nào, parser trả về `CliAction::Repl`.

Mode này:

- giữ session trong memory
- đọc line từ terminal
- hỗ trợ slash command
- render markdown và spinner
- lặp nhiều turn liên tiếp

## 6. Bootstrap flow thực tế

```text
args
  |
  v
parse_args()
  |
  v
CliAction
  +--> Prompt ----+
  +--> Repl ------+--> load config -> load system prompt
  +--> Resume ----+                    -> load plugins/tools
  +--> Login ------------------------> OAuth loopback flow
  +--> Utility ----------------------> manifests / version / agents / skills
                                       |
                                       v
                                     LiveCli
```

Luồng khái niệm:

1. CLI parse input
2. load config
3. load plugin manager
4. build plugin registry
5. build global tool registry
6. build permission policy
7. load system prompt
8. tạo runtime/session
9. chạy turn hoặc vào REPL loop

Điểm quan trọng:

`BootstrapPlan` trong `runtime/bootstrap.rs` không phải parser CLI, mà là cách encode các phase bootstrap ở mức kiến trúc:

- `CliEntry`
- `FastPathVersion`
- `StartupProfiler`
- `SystemPromptFastPath`
- `ChromeMcpFastPath`
- `DaemonWorkerFastPath`
- `BridgeFastPath`
- `DaemonFastPath`
- `BackgroundSessionFastPath`
- `TemplateFastPath`
- `EnvironmentRunnerFastPath`
- `MainRuntime`

Nó đóng vai “bản đồ intent bootstrap”, hữu ích cho parity và documentation.

## 7. OAuth login/logout trong CLI

CLI có flow login khá hoàn chỉnh:

1. dựng `OAuthConfig`
2. sinh `state` và PKCE pair
3. mở local callback server trên loopback
4. build authorize URL
5. mở browser
6. đợi callback
7. verify state
8. exchange code lấy token
9. lưu credentials xuống runtime oauth store

Logout thì đơn giản hơn:

- xóa credentials đã lưu

Điều này cho thấy CLI đang chịu trách nhiệm cho auth UX chứ không đẩy hết xuống API layer.

## 8. Resume session hoạt động thế nào

`resume_session()` đọc session đã persist và cho phép thực hiện một tập slash command an toàn khi resume.

Điểm hay:

- không phải slash command nào cũng được phép ở resume mode
- `commands::resume_supported_slash_commands()` định nghĩa tập được support

Ý nghĩa kiến trúc:

- session persisted là asset hạng nhất
- resume không phải “nạp lại raw text”, mà là nối tiếp trạng thái hội thoại một cách có kiểm soát

## 9. `args.rs` và `app.rs` nên hiểu ra sao

```text
ACTIVE PATH
  Cargo binary -> src/main.rs -> run() -> parse_args() -> CliAction -> LiveCli

SECONDARY / NOT WIRED INTO MAIN PATH
  src/args.rs
  src/app.rs
```

Đây là điểm phải ghi thật rõ cho người mới.

### `args.rs`

File này dùng `clap` và mô tả một bề mặt CLI nhỏ hơn nhiều.

Nhưng:

- `main.rs` không import file này
- parser đang chạy thật là parser thủ công trong `main.rs`

### `app.rs`

File này có `CliApp`, `SlashCommand`, `ConversationClient` abstraction và một vòng lặp khác.

Nhưng:

- `main.rs` không dùng `app.rs`
- nên nó không phải main execution path ở hiện tại

### Kết luận

Khi đọc `claw-cli`, ưu tiên tuyệt đối:

1. `main.rs`
2. `input.rs`
3. `render.rs`
4. `init.rs`

Chỉ đọc `args.rs` và `app.rs` như tư liệu phụ để hiểu lịch sử hoặc ý định thiết kế.

## 10. Những thực hành tốt rút ra từ CLI code

### Điểm tốt

- parser hỗ trợ mode compat thực dụng
- normalize allowed tools ngay ở CLI
- tách render terminal riêng
- tách login/logout/init thành flow rõ

### Điểm cần lưu ý

- parser thủ công khá dài, maintenance cost cao
- code entrypoint ôm nhiều trách nhiệm
- presence của `args.rs`/`app.rs` dễ gây nhiễu nhận thức

## 11. Fresher nên debug CLI thế nào

Thứ tự đúng:

1. bắt đầu từ `main.rs`
2. xác định `CliAction` đang được chọn
3. xem `LiveCli` được dựng với model, permission, allowed tools nào
4. xem `load_system_prompt()` lấy gì
5. xem `ConversationRuntime` được cấp `ApiClient` và `ToolExecutor` nào
6. nếu có slash command thì sang `commands`

Nếu bỏ qua bước 2, bạn rất dễ lần sai nhánh code.
