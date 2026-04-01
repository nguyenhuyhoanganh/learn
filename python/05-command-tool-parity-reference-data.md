# Command, Tool, Parity Audit Và Reference Data

## 1. Triết lý quan trọng nhất của Python port

Python layer này không cố chép lại toàn bộ runtime gốc.
Nó chép lại **bề mặt hệ thống**.

“Bề mặt” ở đây gồm:

- command surface
- tool surface
- top-level subsystem surface
- số lượng file và cấu trúc archive tham chiếu

Muốn hiểu phần Python, phải hiểu triết lý snapshot-driven này trước.

## 2. Nguồn dữ liệu thực sự nằm ở đâu?

Các module quan trọng không hard-code hàng trăm command/tool trong Python source.
Chúng đọc từ JSON snapshot trong `src/reference_data/`.

Các file cốt lõi:

- `commands_snapshot.json`
- `tools_snapshot.json`
- `archive_surface_snapshot.json`
- `subsystems/*.json`

Sơ đồ nguồn sự thật:

```text
┌──────────────────────────────┐
│ reference_data/             │
├──────────────────────────────┤
│ ├─ commands_snapshot.json   │
│ ├─ tools_snapshot.json      │
│ ├─ archive_surface_snapshot │
│ └─ subsystems/*.json        │
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐
│ consumers                    │
├──────────────────────────────┤
│ ├─ commands.py              │
│ ├─ tools.py                 │
│ ├─ parity_audit.py          │
│ ├─ command_graph.py         │
│ └─ tool_pool.py             │
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐
│ inventory + parity outputs   │
└──────────────────────────────┘
```

Ảnh trên cho thấy đúng tinh thần của lớp Python này:

- dữ liệu gốc đến từ snapshot/reference data
- code Python phần lớn là adapter và report layer
- parity ở đây chủ yếu là parity bề mặt, không phải parity runtime đầy đủ

Điều này có nghĩa:

- thay đổi snapshot là thay đổi mặt nhìn của hệ thống
- Python source chủ yếu là adapter đọc snapshot

## 3. `commands.py`: mirror command surface

### 3.1. Snapshot load

`load_command_snapshot()`:

- đọc JSON từ `commands_snapshot.json`
- map mỗi entry thành `PortingModule`
- cache bằng `@lru_cache(maxsize=1)`

Đây là một best practice tốt:

- tránh parse JSON lặp lại nhiều lần
- giữ API đơn giản

### 3.2. Những API chính

`commands.py` cung cấp:

- `PORTED_COMMANDS`
- `built_in_command_names()`
- `build_command_backlog()`
- `command_names()`
- `get_command(name)`
- `get_commands(...)`
- `find_commands(query, limit)`
- `execute_command(name, prompt)`
- `render_command_index(...)`

Ý đồ thiết kế khá rõ:

- một lớp cho inventory
- một lớp cho lookup
- một lớp cho execution shim
- một lớp cho render/report

### 3.3. `execute_command()` không làm nghiệp vụ thật

Khi gọi:

```bash
python -m src.main exec-command review "inspect security review"
```

thứ nhận được chỉ là message kiểu:

- command nào được mirror
- nó đến từ `source_hint` nào
- nó “would handle prompt”

Nghĩa là:

- đây là educational shim
- không phải business executor

## 4. `tools.py`: mirror tool surface

### 4.1. Cấu trúc tương tự command

`tools.py` cũng:

- đọc snapshot
- map sang `PortingModule`
- cung cấp lookup
- filter theo mode/context
- có execution shim

### 4.2. Hai filter quan trọng

`get_tools()` có hai nhánh filter rất đáng chú ý:

- `simple_mode=True`
- `include_mcp=False`

Nếu `simple_mode=True`, chỉ giữ:

- `BashTool`
- `FileReadTool`
- `FileEditTool`

Ý nghĩa:

- mô phỏng chế độ tool set tối giản
- tiện cho demo và onboarding

Nếu `include_mcp=False`:

- loại bớt tool có chữ `mcp` trong tên hoặc `source_hint`

Ý nghĩa:

- cho phép mô phỏng môi trường không bật MCP

### 4.3. Permission context

`permissions.py` định nghĩa `ToolPermissionContext` với:

- `deny_names`
- `deny_prefixes`

Hàm `blocks(tool_name)` chặn tool nếu:

- trùng tên deny
- hoặc bắt đầu bằng prefix bị deny

Đây là policy layer tối giản nhưng hợp lý cho Python port:

- dễ hiểu
- đủ để minh hoạ gating
- chưa phải authorization framework thật

## 5. `command_graph.py` và `tool_pool.py`

### 5.1. Command graph

`build_command_graph()` phân nhóm command theo `source_hint`:

- builtins
- plugin-like
- skill-like

Kết quả hiện tại trong workspace:

- builtins: `185`
- plugin-like commands: `20`
- skill-like commands: `2`

Điểm quan trọng:

- Python không cố hiểu semantic command graph sâu
- nó chỉ chia nhóm theo pattern tên nguồn

### 5.2. Tool pool

`assemble_tool_pool()` trả về:

- danh sách tool sau filter
- cờ `simple_mode`
- cờ `include_mcp`

Đây là lớp rất hữu ích cho onboarding vì nó trả lời nhanh:

- một mode cụ thể sẽ “thấy” những tool nào
- tool set sau filter còn bao nhiêu entry

## 6. `execution_registry.py`: bridge giữa inventory và “thực thi”

Registry build ra:

- `MirroredCommand`
- `MirroredTool`
- `ExecutionRegistry`

Thứ registry làm không phải chạy logic thật, mà là:

- nhận `match.name`
- tìm object tương ứng
- gọi execution shim trả message

Vai trò kiến trúc:

- tách routing khỏi execution surface
- giữ code ở `runtime.py` dễ đọc
- giúp report `bootstrap` có phần “Command Execution” và “Tool Execution”

## 7. Parity audit đo cái gì?

`parity_audit.py` đo 5 nhóm tín hiệu:

- root file coverage
- directory coverage
- tổng số file Python so với snapshot archive
- command entry ratio
- tool entry ratio

Nó dùng 3 loại dữ liệu:

- mapping root file TS -> Python
- mapping top-level directory archive -> target Python
- snapshot surface counts

### 7.1. Root file coverage

Ví dụ mapping:

- `QueryEngine.ts` -> `QueryEngine.py`
- `main.tsx` -> `main.py`
- `tools.ts` -> `tools.py`

Đây là phép đo “các file bề mặt cấp cao đã có target Python tương ứng chưa”.

### 7.2. Directory coverage

Ví dụ mapping:

- `assistant` -> `assistant`
- `services` -> `services`
- `skills` -> `skills`
- `remote` -> `remote`

Đây là phép đo “các subsystem chính có tên tương ứng trong Python workspace chưa”.

### 7.3. Surface ratio

`archive_surface_snapshot.json` đang ghi:

- `1902` file TS-like
- `207` command entries
- `184` tool entries

Trong Python workspace hiện tại:

- snapshot command = `207`
- snapshot tool = `184`
- file Python thật = `66`

Đọc các con số này đúng cách:

- parity metadata rất cao ở command/tool
- parity implementation thật còn thấp ở file count/runtime depth

## 8. Tại sao parity audit vẫn hữu ích dù archive local không có?

Trong máy hiện tại, `parity-audit` báo:

- local archive unavailable

Điều này không làm module vô dụng.

Lý do:

- nó vẫn có mapping logic rõ ràng
- vẫn có reference surface snapshot
- vẫn cho team biết khi nào cần so khớp lại với archive local

Nói cách khác:

- module này vừa là tool audit
- vừa là nơi ghi lại “định nghĩa parity” của dự án

## 9. Placeholder subsystem package hoạt động ra sao?

Nhiều package trong `src/` chỉ có `__init__.py`.

Pattern chung:

1. đọc `reference_data/subsystems/<name>.json`
2. expose hằng số metadata

Các hằng số điển hình:

- `ARCHIVE_NAME`
- `MODULE_COUNT`
- `SAMPLE_FILES`
- `PORTING_NOTE`

Ý nghĩa thực tế:

- package tồn tại để giữ surface parity
- test có thể import package đó
- người onboarding biết subsystem gốc lớn cỡ nào

Đây là một quyết định rất thực dụng:

- chấp nhận “chưa port logic”
- nhưng vẫn không làm mất dấu subsystem khỏi codebase Python

## 10. Các subsystem lớn nhất theo snapshot

Các nhóm lớn nhất đang thấy:

- `utils`: `564`
- `components`: `389`
- `services`: `130`
- `hooks`: `104`
- `bridge`: `31`
- `constants`: `21`
- `skills`: `20`
- `cli`: `19`

Từ góc nhìn senior engineer, con số này cho thấy:

- hệ thống gốc rất nặng utility layer
- component và service layer cũng lớn
- Python layer hiện chủ yếu mới “đánh dấu bản đồ”, chưa đi sâu vào runtime behavior của các lớp đó

## 11. Best practice đang làm đúng trong phần snapshot layer

- dùng `lru_cache` để tránh parse JSON lặp
- tách inventory ra khỏi orchestration
- dùng `PortingModule` làm model chung
- render/report tách riêng khỏi raw loader
- giữ API lookup ngắn, ít bất ngờ

## 12. Hạn chế hiện tại của snapshot-driven design

- snapshot có thể stale nếu archive gốc thay đổi mà không refresh
- `source_hint` chỉ là metadata, không phải dependency graph thật
- lookup chủ yếu dựa vào chuỗi tên nên không hiểu quan hệ sâu
- execution shim có thể khiến người mới ngộ nhận là command/tool đã “port xong”

Vì thế khi onboarding, nên nhắc rõ:

- “mirror surface” không đồng nghĩa với “mirror implementation”

## 13. Performance tips cho lớp inventory

- chỉ load snapshot một lần mỗi process, đúng như code đang làm
- nếu số lượng command/tool tăng mạnh, nên thêm index dictionary theo tên lower-case
- với search nâng cao, nên tách offline build index thay vì scan toàn bộ tuple mỗi lần
- nếu parity audit chạy thường xuyên trong CI, nên cache `archive_surface_snapshot.json`

## 14. Kết luận

Phần command/tool/parity/reference data chính là xương sống của Python port.
Nó giúp team “nhìn thấy toàn bộ bề mặt hệ thống” nhanh, rẻ, dễ test, rất hợp cho audit và onboarding, nhưng không nên bị nhầm là lớp nghiệp vụ thực thi đầy đủ.
