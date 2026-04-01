# Lộ Trình Đọc Rust Wiki

## 1. Mục tiêu của file này

File này là bản đồ điều hướng cho toàn bộ tài liệu Rust trong `claw-code/rust/`.

Rust là phần quan trọng nhất của dự án ở thời điểm hiện tại vì đây không còn là lớp mirror mỏng như Python nữa, mà là một runtime agent khá đầy đủ:

- có CLI thật
- có vòng lặp hội thoại thật
- có provider layer thật
- có tool execution thật
- có plugin system thật
- có session persistence thật
- có MCP, LSP, server surface và OAuth

```text
+-------------------+        +-------------------+
|     claw-cli      | -----> |      runtime      |
| entry, REPL, UX   |        | conversation core |
+-------------------+        +-------------------+
                                   |      |      \
                                   |      |       \
                                   v      v        v
                              +--------+ +--------+ +-----------+
                              |  api   | | tools  | | commands  |
                              +--------+ +--------+ +-----------+
                                   |         |           |
                                   v         v           v
                              +--------+ +--------+ +-----------+
                              |plugins | |  lsp   | |  server   |
                              +--------+ +--------+ +-----------+
                                   \
                                    v
                              +---------------+
                              | compat-harness|
                              +---------------+
```

## 2. Nên hiểu Rust theo cách nào

Khi đọc phần Rust, đừng xem nó như một bản dịch cú pháp từ NodeJS sang Rust.

Cách đọc đúng là:

- xem đây là một workspace nhiều crate
- mỗi crate giải một lát cắt trách nhiệm riêng
- `claw-cli` chỉ là cửa vào
- lõi điều phối thật nằm ở `runtime`
- khả năng tương tác với thế giới ngoài nằm ở `api`, `tools`, `plugins`, `mcp`, `lsp`, `server`

## 3. Có 3 nhánh đọc chính

```text
Path A: orientation
  01 -> 02 -> 03 -> 04 -> 07 -> 10

Path B: change runtime safely
  03 -> 04 -> 05 -> 06 -> 08 -> 09

Path C: extend ecosystem
  07 -> 08 -> 06 -> 09
```

### Nhánh A: đọc nhanh để nắm toàn cảnh

Đọc theo thứ tự:

1. `01-tong-quan-rust-workspace.md`
2. `02-ban-do-workspace-va-crates.md`
3. `03-claw-cli-bootstrap-va-repl.md`
4. `04-runtime-conversation-session-va-compaction.md`
5. `07-tools-commands-plugins.md`
6. `10-cac-van-de-rust-giai-quyet-va-cach-giai.md`

Mục tiêu:

- hiểu Rust đang giải bài toán gì
- biết crate nào giữ trách nhiệm nào
- biết luồng chạy thật bắt đầu từ đâu
- biết agent loop thật nằm ở đâu

### Nhánh B: đọc để chuẩn bị sửa runtime

Đọc theo thứ tự:

1. `03-claw-cli-bootstrap-va-repl.md`
2. `04-runtime-conversation-session-va-compaction.md`
3. `05-config-prompt-permission-sandbox.md`
4. `06-api-provider-oauth-streaming.md`
5. `08-mcp-server-lsp-va-service-surface.md`
6. `09-tests-rui-ro-best-practice.md`

Mục tiêu:

- hiểu bootstrap
- hiểu prompt và config được dựng thế nào
- hiểu permission và tool loop vận hành ra sao
- hiểu các integration point để tránh sửa đứt đường chạy

### Nhánh C: đọc để chuẩn bị mở rộng ecosystem

Đọc theo thứ tự:

1. `07-tools-commands-plugins.md`
2. `08-mcp-server-lsp-va-service-surface.md`
3. `06-api-provider-oauth-streaming.md`
4. `09-tests-rui-ro-best-practice.md`

Mục tiêu:

- thêm tool/plugin mà không phá permission model
- hiểu giới hạn MCP hiện tại
- hiểu cách provider abstraction đang hoạt động
- biết chỗ nào cần test trước khi thêm feature

## 4. Những điều rất dễ hiểu nhầm

### `claw-cli/src/main.rs` mới là entrypoint thật

Trong crate `claw-cli` có `main.rs`, `args.rs`, `app.rs`.

Điểm cần nhớ:

- `main.rs` là đường chạy thật của binary
- `main.rs` chỉ `mod init; mod input; mod render;`
- `args.rs` và `app.rs` không nằm trên critical path hiện tại

Nếu fresher không biết điểm này, rất dễ đọc nhầm code cũ và hiểu sai toàn bộ CLI.

### README của Rust có một vài điểm lệch so với code

Ví dụ quan trọng nhất:

- README nói plugin system còn “planned”
- nhưng source code cho thấy plugin manager, bundled plugins, registry, lifecycle, hooks, aggregated tool execution đều đã có thật

### MCP không phải transport nào cũng operational như nhau

Code config và bootstrap đã biết nhiều transport:

- stdio
- sse
- http
- websocket
- sdk
- managed proxy

Nhưng manager đang chạy thực tế mạnh nhất là nhánh stdio.

## 5. Ghi chú phương pháp đọc

Tài liệu Rust dưới đây được dựng từ đọc source code trong workspace hiện tại.

Có một giới hạn phải ghi rõ:

- môi trường hiện tại không có `cargo` trong `PATH`
- vì vậy chưa compile/test lại được workspace từ máy này
- các mô tả được xác nhận bằng static reading và test code hiện diện trong source

Điều đó có nghĩa:

- kiến trúc và intent đọc được khá chắc
- nhưng trạng thái “build xanh” chưa được xác minh từ môi trường local hiện tại

## 6. Nếu chỉ có 30 phút

Hãy đọc 5 file sau:

1. `01-tong-quan-rust-workspace.md`
2. `02-ban-do-workspace-va-crates.md`
3. `03-claw-cli-bootstrap-va-repl.md`
4. `04-runtime-conversation-session-va-compaction.md`
5. `10-cac-van-de-rust-giai-quyet-va-cach-giai.md`

Đây là 5 file cho tỷ lệ “thời gian bỏ ra / hiểu dự án thu lại” tốt nhất.
