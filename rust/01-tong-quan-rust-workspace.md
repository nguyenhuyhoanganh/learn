# Tổng Quan Rust Workspace

## 1. Rust trong dự án này là gì

Rust workspace trong `claw-code/rust/` là phần hiện thực hóa nghiêm túc của một AI coding agent kiểu CLI.

Nó giải đồng thời nhiều bài toán:

- nhận prompt hoặc chạy REPL
- dựng system prompt theo môi trường thực tế
- gọi model qua nhiều provider
- cho model dùng tool
- chặn tool bằng permission policy
- hook trước và sau khi gọi tool
- lưu session và usage
- compact hội thoại khi dài
- quản lý plugin
- giao tiếp với MCP
- lấy ngữ cảnh từ LSP
- expose session qua HTTP/SSE

Nếu Python port là lớp học kiến trúc và mirror surface, thì Rust là nơi năng lực runtime bắt đầu thành hình thật.

```text
+----------------+  +----------------+  +----------------+
|  Interaction   |  | Agent runtime  |  |    Context     |
| CLI / REPL /   |  | tool loop /    |  | CLAW.md / git /|
| slash command  |  | session / cost |  | config / LSP   |
+----------------+  +----------------+  +----------------+

+----------------+  +----------------+
| Control/safety |  |  Integration   |
| permission /   |  | providers /    |
| sandbox / hook |  | MCP / plugins  |
+----------------+  +----------------+
```

## 2. Bài toán mà code đang giải

### 2.1. Bài toán 1: biến một prompt thành vòng lặp agent có tool use

Không chỉ gửi prompt tới model rồi in text.

Hệ thống còn phải:

- gửi system prompt + message history
- nhận stream event
- phát hiện tool call
- kiểm tra quyền
- chạy tool
- đưa tool result quay lại conversation
- tiếp tục cho đến khi agent dừng

Lõi bài toán này nằm ở `runtime/src/conversation.rs`.

### 2.2. Bài toán 2: giữ được state đủ giàu để resume

Session không chỉ là một list string.

Rust giữ:

- role của từng message
- block text
- block tool_use
- block tool_result
- usage token theo từng assistant message

Nhờ đó việc resume, cost tracking, compaction, export, status và session server có nền dữ liệu tốt hơn hẳn Python.

### 2.3. Bài toán 3: agent phải chạy được trong môi trường doanh nghiệp thật

Điều này giải thích vì sao code có:

- config hierarchy
- sandbox detection
- permission mode
- OAuth
- plugin hooks
- MCP transports
- upstream proxy bootstrap
- LSP context

Đây là dấu hiệu của một runtime đang nhắm tới môi trường phát triển thực tế, không chỉ demo local.

## 3. Workspace gồm những crate nào

Workspace hiện có các crate sau:

- `claw-cli`
- `runtime`
- `api`
- `tools`
- `commands`
- `plugins`
- `compat-harness`
- `lsp`
- `server`

Mỗi crate không chỉ là package kỹ thuật.
Nó là một biên phân trách nhiệm khá rõ.

## 4. Trục kiến trúc chính

Có thể nhìn Rust workspace qua 5 trục:

### 4.1. Trục vào hệ thống

- `claw-cli`

Đây là nơi parse argument, khởi tạo runtime, login/logout, resume session, REPL, one-shot prompt.

### 4.2. Trục agent runtime

- `runtime`

Đây là tim của hệ thống:

- session
- conversation loop
- compaction
- config
- prompt building
- permissions
- hooks
- MCP bootstrap types
- sandbox
- oauth persistence
- usage tracker

### 4.3. Trục tương tác bên ngoài

- `api`
- `tools`
- `plugins`
- `lsp`
- `server`

Các crate này đưa runtime chạm vào thế giới ngoài:

- model provider
- shell/file/web tool
- plugin tool
- code intelligence
- service API

### 4.4. Trục workflow người dùng

- `commands`

Crate này chứa slash command registry và logic workflow như:

- help
- status
- compact
- config
- branch
- worktree
- commit
- commit-push-pr
- plugin
- agents
- skills

### 4.5. Trục parity với source gốc

- `compat-harness`

Crate này đọc TypeScript upstream để rút ra manifest command/tool/bootstrap, phục vụ việc so sánh bề mặt tính năng.

## 5. Dấu hiệu cho thấy Rust đã đi khá xa

Một số tín hiệu rất rõ:

- `ConversationRuntime` có test end-to-end cho tool loop
- `Session` có serialization/deserialization đầy đủ
- `ConfigLoader` có deep merge nhiều nguồn config
- provider layer hỗ trợ cả Claw/Anthropic lẫn OpenAI-compatible và xAI
- plugin manager có install, enable, disable, uninstall, update
- `McpServerManager` quản lý process stdio và index tool động
- `LspManager` có diagnostics, definition, references
- `server` có route REST + SSE

Đây không còn là một prototype mỏng.

## 6. So với Python thì Rust khác thế nào

| Trục | Python | Rust |
|---|---|---|
| Vai trò chính | Mirror surface + mô phỏng | Runtime thực thi |
| Session model | Mỏng | Structured conversation |
| Tool execution | Shim | Thực thi thật |
| Permission | Đơn giản | Policy rõ và nhiều mode |
| Prompt build | Mô phỏng | Dựng từ context/config/git/LSP |
| Plugin | Placeholder | Có manager và lifecycle |
| MCP | Metadata thiên về mirror | Có stdio manager chạy thật |
| Parity | Snapshot-based | Vừa runtime thật vừa có compat-harness |

## 7. Điều quan trọng nhất fresher cần nhớ

Nếu phải gói gọn Rust workspace trong một câu:

`claw-cli` mở cửa, `runtime` điều phối, `api` nói chuyện với model, `tools/plugins` tạo tay chân cho agent, `commands` tổ chức workflow, còn `mcp/lsp/server` mở rộng năng lực và integration surface.

Hiểu được câu này, bạn đã có xương sống để đọc phần còn lại.
