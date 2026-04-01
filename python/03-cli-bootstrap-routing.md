# CLI, Bootstrap Và Routing

## 1. Entry point: `src/main.py`

Toàn bộ trải nghiệm Python bắt đầu từ `python -m src.main ...`.

`main.py` có hai phần lớn:

1. `build_parser()`
2. `main(argv=None)`

### 1.1. `build_parser()`

Parser được tổ chức theo kiểu subcommand.
Mỗi subcommand map sang một mục tiêu rất rõ.

### Nhóm báo cáo / inventory

- `summary`
- `manifest`
- `parity-audit`
- `setup-report`
- `command-graph`
- `tool-pool`
- `bootstrap-graph`
- `subsystems`
- `commands`
- `tools`

### Nhóm routing / runtime mô phỏng

- `route`
- `bootstrap`
- `turn-loop`

### Nhóm session

- `flush-transcript`
- `load-session`

### Nhóm mode branching

- `remote-mode`
- `ssh-mode`
- `teleport-mode`
- `direct-connect-mode`
- `deep-link-mode`

### Nhóm lookup / execution shim

- `show-command`
- `show-tool`
- `exec-command`
- `exec-tool`

## 2. Bootstrap flow của lớp Python

`bootstrap_graph.py` cho biết nhóm phase mà Python đang mirror:

1. top-level prefetch side effects
2. warning handler and environment guards
3. CLI parser and pre-action trust gate
4. setup() + commands/agents parallel load
5. deferred init after trust
6. mode routing: local / remote / ssh / teleport / direct-connect / deep-link
7. query engine submit loop

Điều quan trọng:

- đây là **bootstrap graph mô tả**
- không phải bootstrap framework production

## 3. `setup.py`: setup thật sự làm gì?

`run_setup()` tạo `SetupReport` bằng cách:

1. xác định root hiện tại
2. gọi 3 prefetch giả lập:
   - `start_mdm_raw_read()`
   - `start_keychain_prefetch()`
   - `start_project_scan(root)`
3. gọi `run_deferred_init(trusted=...)`
4. trả về report dạng markdown

### Ý nghĩa kiến trúc

Mục tiêu của lớp này không phải lấy dữ liệu thật từ MDM/keychain.
Mục tiêu là **bảo tồn hình dạng flow khởi động** của hệ thống gốc để người đọc có thể hình dung:

- có prefetch trước
- có trust gate
- có deferred init
- có branch theo mode

## 4. Flow `bootstrap`

Khi chạy:

```bash
python -m src.main bootstrap "review MCP tool" --limit 5
```

Python tạo một `RuntimeSession` và in ra report hoàn chỉnh.

### 4.1. Trình tự thực hiện

```text
┌──────────────┐
│ CLI command  │
└──────┬───────┘
       ▼
┌──────────────────────────────┐
│ PortRuntime.bootstrap_session│
├──────────────────────────────┤
│ ├─ build_port_context()      │
│ ├─ run_setup(trusted=True)   │
│ ├─ route_prompt()            │
│ ├─ registry shims            │
│ ├─ QueryEnginePort           │
│ └─ persist + render report   │
└──────────────────────────────┘
```

Ảnh trên bám sát flow hiện tại của `bootstrap_session()`.
Nó cũng cố ý làm nổi bật bug quan trọng nhất: prompt hiện bị submit hai lần trong cùng một lượt bootstrap.

### 4.2. Kết quả report gồm gì?

Report `RuntimeSession.as_markdown()` gồm:

- Prompt
- Context
- Setup
- Startup steps
- System init
- Routed matches
- Command execution
- Tool execution
- Stream events
- Turn result
- Persisted session path
- Session history

Đây là một “ảnh chụp toàn cảnh” rất tốt cho fresher.

## 5. Routing prompt hoạt động ra sao?

`PortRuntime.route_prompt()` dùng cơ chế cực đơn giản:

1. chuẩn hóa prompt thành token bằng cách:
   - thay `/` và `-` bằng dấu cách
   - split theo whitespace
2. chấm điểm từng command/tool theo việc token có xuất hiện trong:
   - `module.name`
   - `module.source_hint`
   - `module.responsibility`
3. gom match theo 2 loại:
   - command
   - tool
4. ưu tiên lấy:
   - 1 command top đầu
   - 1 tool top đầu
5. phần còn lại lấy theo score giảm dần

### Hệ quả

Ưu điểm:

- rẻ
- dễ hiểu
- ổn cho demo

Nhược điểm:

- không semantic
- dễ match nhiễu
- kết quả phụ thuộc naming của snapshot

Ví dụ prompt `review MCP tool` từng route ra:

- command: `UltrareviewOverageDialog`
- tools:
  - `ListMcpResourcesTool`
  - `MCPTool`
  - `McpAuthTool`
  - `ReadMcpResourceTool`

Điều này cho thấy:

- phần MCP match khá hợp lý
- phần command `UltrareviewOverageDialog` là một false-positive tương đối dễ xảy ra

## 6. `ExecutionRegistry`: thực thi kiểu shim

`execution_registry.py` build registry từ snapshot:

- mỗi `MirroredCommand` gọi `execute_command()`
- mỗi `MirroredTool` gọi `execute_tool()`

Nhưng cần nhấn mạnh:

- đây không phải executor thật
- nó chỉ trả về chuỗi kiểu:
  - command nào “sẽ xử lý”
  - tool nào “sẽ nhận payload”

Mục tiêu là giúp:

- debug routing
- explain mapping
- không phải hoàn thành nghiệp vụ

## 7. Mode branching

Các mode sau hiện chỉ là placeholder report:

- `remote-mode`
- `ssh-mode`
- `teleport-mode`
- `direct-connect-mode`
- `deep-link-mode`

Chúng giúp giữ bề mặt API và flow branching, nhưng chưa có remote runtime thật.

## 8. System init message

`system_init.py` ghép:

- trạng thái trusted
- số command names built-in
- số command entries đã load
- số tool entries đã load
- danh sách startup steps

Đây là cách Python kể lại “nội dung system init” ở mức học kiến trúc.

## 9. Quick reference CLI cho fresher

### Muốn nhìn toàn cảnh

```bash
python -m src.main summary
python -m src.main setup-report
python -m src.main bootstrap "review MCP tool" --limit 5
```

### Muốn đọc inventory

```bash
python -m src.main manifest
python -m src.main commands --limit 20
python -m src.main tools --limit 20
python -m src.main command-graph
python -m src.main tool-pool
```

### Muốn debug route

```bash
python -m src.main route "review MCP tool" --limit 5
python -m src.main show-command review
python -m src.main show-tool MCPTool
```

## 10. Kết luận

CLI Python không mạnh ở chỗ “làm việc thật”.
Nó mạnh ở chỗ:

- cho thấy bề mặt dự án
- kể lại flow bootstrap
- cho phép thử route prompt
- tạo báo cáo onboarding rất nhanh
