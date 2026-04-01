# MCP, Server, LSP Và Service Surface

## 1. Vì sao nhóm này nên đọc cùng nhau

Ba mảng này cùng trả lời một câu hỏi:

Rust runtime kết nối với hệ sinh thái ngoài như thế nào?

Ở đây có ba hướng mở rộng chính:

- dùng MCP để gọi tool/resource từ server ngoài
- dùng LSP để tăng ngữ cảnh code thông minh
- dùng HTTP/SSE server để expose session ra ngoài

```text
external integrations around runtime
├─ MCP
│  └─ external tools / resources
├─ LSP
│  └─ diagnostics / defs / refs
│     └─ prompt enrichment
├─ server
│  └─ HTTP + SSE session surface
└─ compat-harness
   └─ upstream TS parity extraction
```

## 2. MCP trong Rust được chia thành mấy lớp

```text
MCP
├─ config knows
│  ├─ stdio
│  ├─ sse
│  ├─ http
│  ├─ ws
│  ├─ sdk
│  └─ managed-proxy
└─ strongest operational manager today
   └─ stdio

LSP
└─ open / change / save doc
   └─ diagnostics + definitions + references
      └─ prompt section

server
├─ POST /sessions
├─ GET  /sessions
├─ GET  /sessions/{id}
├─ GET  /sessions/{id}/events
└─ POST /sessions/{id}/message
```

Ít nhất có 3 lớp:

- config và naming
- bootstrap transport typed
- stdio manager chạy thực tế

### 2.1. `runtime/src/mcp.rs`

File này lo:

- normalize tên server
- dựng qualified tool name kiểu `mcp__server__tool`
- xử lý signature/config hash
- một số helper cho managed proxy URL

Đây là lớp “quy ước nhận dạng”.

### 2.2. `runtime/src/mcp_client.rs`

File này map typed config thành bootstrap object:

- `Stdio`
- `Sse`
- `Http`
- `WebSocket`
- `Sdk`
- `ManagedProxy`

Điểm cần hiểu đúng:

- đây mới là typed bootstrap model
- chưa phải manager chạy đầy đủ cho mọi transport

### 2.3. `runtime/src/mcp_stdio.rs`

Đây mới là lớp operational quan trọng nhất hiện tại.

Nó xử lý:

- spawn stdio MCP process
- initialize JSON-RPC
- list tools
- call tool
- list/read resources
- shutdown
- index qualified tool name về đúng server/tool thật

## 3. Giới hạn MCP hiện tại cần ghi thật rõ

Code đã hiểu nhiều loại transport ở mức config và bootstrap.

Nhưng `McpServerManager` hiện mạnh nhất ở nhánh:

- stdio

Các server không phải stdio hiện được track như unsupported trong manager thay vì crash.

Điều này rất quan trọng cho documentation:

- bề mặt config rộng hơn bề mặt vận hành thực tế
- không nên quảng bá mọi transport như đã “production-ready” như nhau

## 4. LSP được dùng để làm gì

`lsp` crate giải bài toán:

- lấy diagnostics
- go to definition
- find references
- biến kết quả đó thành context enrich cho prompt

Đây là một hướng đi rất đúng cho AI coding agent:

- không chỉ dựa vào grep hay file read
- còn tận dụng code intelligence từ language server

## 5. `LspManager` hoạt động thế nào

`lsp/src/manager.rs` quản lý:

- map extension -> server name
- lazy start client theo path cần dùng
- open/change/save/close document
- collect workspace diagnostics
- go to definition
- find references
- build `LspContextEnrichment`

Điểm hay:

- client chỉ được khởi tạo khi path thật sự cần
- extension duplicate bị chặn từ lúc build manager
- location được dedupe trước khi trả ra

## 6. `LspContextEnrichment` có giá trị gì

`lsp/src/types.rs` định nghĩa object enrich gồm:

- file focus
- diagnostics toàn workspace
- definitions
- references

Object này còn render được thành một đoạn prompt section rõ ràng.

Điều này rất có giá trị vì:

- LSP context không bị nhốt trong tool riêng
- nó được bơm trực tiếp vào system prompt builder khi cần

## 7. `server` crate cung cấp gì

`server/src/lib.rs` cho thấy một service surface gọn nhưng hữu ích.

Hiện có các route chính:

- `POST /sessions`
- `GET /sessions`
- `GET /sessions/{id}`
- `GET /sessions/{id}/events`
- `POST /sessions/{id}/message`

### Ý nghĩa

Server này đang giải một bài toán rõ:

- tạo session
- liệt kê session
- lấy snapshot session
- stream event bằng SSE
- append user message vào session

Nó chưa phải full orchestration server cho toàn runtime, nhưng đủ để mở một bề mặt service rất hữu ích.

## 8. SSE trong server dùng như thế nào

Server dùng `broadcast` channel cho mỗi session.

Event hiện tại có hai loại chính:

- `Snapshot`
- `Message`

Flow:

1. client subscribe SSE
2. nhận ngay snapshot hiện tại
3. sau đó nhận message mới theo thời gian thực

Đây là thiết kế gọn và hợp lý cho UI hoặc devtool muốn theo dõi session.

## 9. `compat-harness` nằm ở đâu trong bức tranh này

`compat-harness` không trực tiếp là integration runtime, nhưng rất quan trọng cho governance kỹ thuật.

Nó đọc source TypeScript upstream để trích:

- command manifest
- tool manifest
- bootstrap plan

Tức là nó giúp trả lời:

- Rust đang cover bề mặt gốc tới đâu
- command/tool nào tồn tại ở upstream
- bootstrap intent của upstream là gì

Đây là cầu nối giữa “runtime mới” và “nguồn tham chiếu cũ”.

## 10. Góc nhìn senior

### Điểm tốt

- MCP có typed config khá đầy đủ
- LSP integration đặt đúng chỗ: enrich prompt
- server surface nhỏ gọn, dễ mở rộng
- compat-harness giữ được ý thức parity với upstream

### Điểm cần chú ý

- khoảng cách giữa “config hỗ trợ” và “manager chạy thật” của MCP phải được ghi rõ
- LSP process management luôn là nguồn lỗi khó debug
- server session hiện mới là lớp lưu/stream message, chưa phải toàn bộ runtime orchestration

## 11. Kết luận

Nhóm crate này cho thấy Rust port đang muốn trở thành một platform mở rộng được:

- MCP cho tool/resource từ bên ngoài
- LSP cho trí tuệ hiểu code
- server cho UI/service integration
- compat-harness cho kiểm soát parity với upstream
