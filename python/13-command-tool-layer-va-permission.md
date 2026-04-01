# Command Layer, Tool Layer Và Permission Filtering

## 1. Vì sao phải tách command và tool thành một chuyên đề riêng?

Trong Python port, command và tool là hai inventory lớn nhất.
Đây cũng là nơi bề mặt hệ thống được mirror rõ nhất:

- `207` command entries
- `184` tool entries

Nếu không hiểu phần này, bạn sẽ không hiểu:

- routing đang route vào cái gì
- execution shim đang đại diện cho cái gì
- parity inventory đang mạnh ở đâu

```text
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│ commands.py          │  │ tools.py             │  │ permissions.py       │
├──────────────────────┤  ├──────────────────────┤  ├──────────────────────┤
│ snapshot             │  │ snapshot             │  │ lightweight gate     │
│ └─ PortingModule     │  │ └─ PortingModule     │  │ ├─ deny by name      │
│    └─ lookup/render  │  │    └─ filter         │  │ └─ deny by prefix    │
│       / shim         │  │       ├─ simple_mode │  └──────────────────────┘
└──────────────────────┘  │       ├─ include_mcp │
                          │       └─ perm ctx    │
                          └──────────────────────┘

┌──────────────────────┐
│ support analyzers    │
├──────────────────────┤
│ ├─ command_graph.py  │
│ └─ tool_pool.py      │
└──────────────────────┘
```

## 2. `commands.py`: lớp mirror command

### 2.1. `load_command_snapshot()`

Hàm này:

- đọc `commands_snapshot.json`
- map sang `PortingModule`
- cache bằng `lru_cache(maxsize=1)`

Đây là một pattern tốt vì:

- đơn giản
- rẻ
- hợp với dữ liệu gần như immutable trong một process CLI

### 2.2. API quan trọng

- `PORTED_COMMANDS`
- `built_in_command_names()`
- `build_command_backlog()`
- `command_names()`
- `get_command()`
- `get_commands()`
- `find_commands()`
- `execute_command()`
- `render_command_index()`

Chỉ nhìn API đã thấy team tách rất rõ:

- load
- lookup
- filter
- render
- shim execute

### 2.3. Plugin command và skill command

`get_commands()` có thể lọc:

- bỏ plugin command
- bỏ skill command

Logic phân loại dựa vào `source_hint`.
Tức là:

- classification hiện metadata-driven
- chưa phải graph ngữ nghĩa thật

## 3. `tools.py`: lớp mirror tool

### 3.1. Cấu trúc giống command nhưng có thêm policy

Giống `commands.py`, file này:

- load snapshot
- map sang `PortingModule`
- lookup
- render
- shim execute

Nhưng `tools.py` có thêm hai lớp tư duy:

- mode filtering
- permission filtering

### 3.2. `simple_mode`

Nếu bật `simple_mode`, tool set chỉ còn:

- `BashTool`
- `FileReadTool`
- `FileEditTool`

Đây là quyết định thiết kế rất thực dụng vì:

- tạo được một “tool pool tối giản”
- hữu ích cho demo hoặc môi trường giới hạn

### 3.3. `include_mcp`

Nếu `include_mcp=False`, các tool liên quan MCP bị loại khỏi pool.

Điều này cho phép mô phỏng:

- môi trường có MCP
- môi trường không có MCP

## 4. `permissions.py`: policy layer mỏng nhưng đúng vai

`ToolPermissionContext` có:

- `deny_names`
- `deny_prefixes`

Và method:

- `blocks(tool_name)`

Điểm hay:

- API cực dễ hiểu
- đủ để làm demo permission gating
- dễ test trong CLI

Điểm hạn chế:

- không có allowlist/denylist theo capability
- không có context sâu theo project/user/mode
- không có audit log riêng cho permission decision

## 5. `filter_tools_by_permission_context()`

Hàm này là cây cầu giữa:

- inventory tool
- policy context

Nó cho thấy Python port đang giữ quan điểm rất rõ:

- permission nên được áp vào tool pool, không nhét trực tiếp vào route score

Đây là quyết định tốt vì:

- tách concern routing và concern policy
- tool pool đầu ra rõ ràng hơn

## 6. `command_graph.py` và `tool_pool.py` nên đọc như thế nào?

### 6.1. `command_graph.py`

File này không dựng graph theo dependency thật.
Nó dựng segmentation report:

- builtins
- plugin-like
- skill-like

Đây là report logic, không phải execution graph thật.

### 6.2. `tool_pool.py`

File này gom kết quả filter thành `ToolPool`.
Nó là lớp trả lời nhanh cho câu hỏi:

- ở chế độ này, hệ thống nhìn thấy những tool nào?

Với onboarding, đây là file rất có ích.

## 7. Execution shim trong command/tool layer

`execute_command()` và `execute_tool()` đều trả object execution nhỏ với:

- tên
- source hint
- input
- handled hay không
- message mô tả

Điều này có giá trị ở chỗ:

- caller có thể biết lookup có thành công không
- report có thể in message dễ đọc
- test dễ xác nhận hơn

## 8. Những hiểu lầm hay gặp

### 8.1. “PORTED_COMMANDS nhiều nghĩa là command đã port xong”

Sai.

Điều đó chỉ nghĩa là snapshot command surface khá đầy.

### 8.2. “Permission filtering là bảo mật hoàn chỉnh”

Sai.

Đây là gating minh hoạ ở mức đơn giản, không phải security layer production.

### 8.3. “tool_pool là runtime tool registry thật”

Không hẳn.

Đây là assembled inventory cho lớp mirror/simulation.

## 9. Nếu muốn phát triển sâu phần command/tool layer

- thêm index dictionary cho lookup nhanh
- enrich snapshot bằng tag/capability/domain
- tách render layer khỏi lookup hơn nữa nếu output format tăng
- thêm confidence hoặc reason vào kết quả search
- bổ sung schema version cho snapshot

## 10. Chốt lại

Command/tool layer là phần Python port mirror tốt nhất.
Nó rất hữu ích cho:

- inventory
- onboarding
- route simulation
- parity reporting

Nhưng cần nhớ:

- đây là surface mirror trước hết
- chưa phải full execution layer
