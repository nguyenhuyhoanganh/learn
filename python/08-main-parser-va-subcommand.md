# `main.py`: Parser, Subcommand Và Cửa Vào Của Toàn Bộ Python Port

## 1. Vì sao phải đọc `main.py` đầu tiên?

Trong một codebase kiểu CLI harness, file entrypoint gần như là nơi tiết lộ:

- hệ thống muốn người dùng làm gì
- team đang coi những capability nào là “chính thức”
- module nào là xương sống của kiến trúc

Với Python port này, `src/main.py` đặc biệt quan trọng vì:

- toàn bộ trải nghiệm đi qua `python -m src.main ...`
- mọi module quan trọng đều lộ ra thông qua subcommand
- chỉ cần nhìn parser là biết Python layer thiên về inventory, report hay runtime thật

Kết luận rất nhanh sau khi đọc file này:

- Python layer thiên mạnh về `report + mirror + simulation`
- chưa phải executor nghiệp vụ production

```text
main.py parser
  |
  +--> inventory/report commands
  |      summary / manifest / commands / tools / graphs / parity
  |
  +--> runtime simulation commands
  |      route / bootstrap / turn-loop
  |
  +--> session commands
  |      flush-transcript / load-session
  |
  +--> mode-branching commands
         remote-mode / ssh-mode / teleport-mode / ...
```

## 2. `build_parser()` đang kể câu chuyện gì?

`build_parser()` dùng `argparse` để khai báo hàng loạt subcommand.
Thay vì coi đây là “chi tiết CLI”, nên coi nó như bản đồ capability của hệ thống.

Nhìn vào parser, có thể chia capability thành 6 nhóm.

### 2.1. Nhóm báo cáo và inventory

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

Nhóm này cho thấy Python port rất mạnh ở:

- kiểm kê
- trình bày bề mặt hệ thống
- giải thích kiến trúc
- đối chiếu snapshot

### 2.2. Nhóm runtime mô phỏng

- `route`
- `bootstrap`
- `turn-loop`

Đây là nhóm giúp người đọc “thấy hệ thống chạy”, nhưng cần nhớ:

- chạy ở đây là chạy logic mô phỏng
- không phải assistant runtime thật

### 2.3. Nhóm session

- `flush-transcript`
- `load-session`

Nhóm này cho thấy team muốn giữ được:

- cảm giác có state
- khả năng persist
- khả năng replay ở mức tối thiểu

### 2.4. Nhóm mode branching

- `remote-mode`
- `ssh-mode`
- `teleport-mode`
- `direct-connect-mode`
- `deep-link-mode`

Các command này nói lên một ý rất hay:

- dù runtime thật chưa có, Python port vẫn muốn giữ nguyên “shape” của luồng điều hướng mode

### 2.5. Nhóm lookup

- `show-command`
- `show-tool`

Nhóm này phục vụ:

- onboarding
- debug inventory
- xác minh snapshot entry

### 2.6. Nhóm execution shim

- `exec-command`
- `exec-tool`

Đây là nơi dễ gây hiểu lầm nhất cho người mới.

Tên nghe giống “chạy thật”, nhưng thực chất:

- chỉ gọi shim
- chỉ in thông điệp giải thích mapping
- không chạy nghiệp vụ thật

## 3. Cách `main()` phân luồng

Hàm `main(argv=None)` có phong cách rất thẳng:

1. build parser
2. parse args
3. dựng `manifest`
4. `if args.command == ...` cho từng nhánh
5. in ra stdout

Ưu điểm:

- cực dễ đọc
- rõ control flow
- rất hợp với utility CLI

Nhược điểm:

- khi command tăng nhiều, file sẽ dài và khó maintain hơn
- chưa có dispatch table nên khó tái sử dụng metadata của command

Trong trạng thái hiện tại, cách viết này vẫn ổn vì:

- số lệnh vừa phải
- logic mỗi nhánh tương đối ngắn
- đây là lớp onboarding/report, không phải command bus phức tạp

## 4. Mỗi nhánh `if` đang trỏ về đâu?

Đây là bản đồ mental model rất đáng nhớ:

| Nhánh trong `main.py` | Module chính được gọi |
|---|---|
| `summary` | `QueryEnginePort.render_summary()` |
| `manifest` | `build_port_manifest()` |
| `parity-audit` | `run_parity_audit()` |
| `setup-report` | `run_setup()` |
| `command-graph` | `build_command_graph()` |
| `tool-pool` | `assemble_tool_pool()` |
| `bootstrap-graph` | `build_bootstrap_graph()` |
| `commands` | `get_commands()` hoặc `render_command_index()` |
| `tools` | `get_tools()` hoặc `render_tool_index()` |
| `route` | `PortRuntime.route_prompt()` |
| `bootstrap` | `PortRuntime.bootstrap_session()` |
| `turn-loop` | `PortRuntime.run_turn_loop()` |
| `flush-transcript` | `QueryEnginePort.submit_message()` + `persist_session()` |
| `load-session` | `load_session()` |
| `show-command` | `get_command()` |
| `show-tool` | `get_tool()` |
| `exec-command` | `execute_command()` |
| `exec-tool` | `execute_tool()` |

Chỉ cần nhìn bảng này đã thấy:

- mọi capability lớn đều quy về vài module trung tâm
- `runtime.py`, `query_engine.py`, `commands.py`, `tools.py` là 4 trục chính

## 5. Điểm mạnh của cách tổ chức CLI hiện tại

### 5.1. Độ discoverability cao

Người mới chỉ cần chạy `--help` hoặc đọc `build_parser()` là hiểu được:

- hệ thống có những chế độ nào
- phần nào đã có surface rõ ràng
- phần nào chỉ là mô phỏng

### 5.2. Dễ smoke test

Test file hiện tại tận dụng đúng lợi thế này:

- nhiều lệnh được gọi trực tiếp qua subprocess
- dễ xác minh output tiêu đề
- wiring lỗi sẽ lộ nhanh

### 5.3. Phù hợp với mục tiêu học dự án

Đây không phải CLI để chạy nghiệp vụ nặng.
Đây là CLI để:

- đọc dự án
- hiểu dự án
- kiểm kê dự án
- mô phỏng dự án

Cho mục tiêu đó, `main.py` đang hoàn thành vai trò khá tốt.

## 6. Điểm yếu và bẫy đọc hiểu

### 6.1. Dễ ngộ nhận rằng có nhiều command nghĩa là runtime mạnh

Không đúng.

Số lượng subcommand ở `main.py` phản ánh:

- nhiều loại báo cáo và mô phỏng

chứ không phản ánh:

- chiều sâu runtime thật

### 6.2. Lookup path và execution path trông khá giống nhau

Ví dụ:

- `show-tool MCPTool`
- `exec-tool MCPTool payload`

Hai lệnh này nhìn bề ngoài có vẻ như một lệnh xem, một lệnh chạy thật.
Thực tế:

- cả hai vẫn làm việc với mirror layer

### 6.3. Một số mode branch mới chỉ là report stub

Các mode như `remote-mode` hay `teleport-mode` giữ surface rất có ích.
Nhưng nếu không đọc tiếp code, người mới sẽ dễ tưởng:

- remote transport đã được port khá sâu

## 7. Best practice nếu tiếp tục mở rộng `main.py`

- tách command registration thành function theo nhóm nếu số lệnh tiếp tục tăng
- giữ help text thật rõ giữa “report”, “simulate”, và “execute shim”
- với các lệnh có side effect, nên ghi rõ trong help string
- nếu thêm command thật sự chạy nghiệp vụ, nên phân biệt naming với nhóm shim hiện tại

## 8. Chốt lại

`main.py` là lớp “điều hướng nhận thức” của cả Python port.
Nó nói với người đọc rằng dự án này mạnh ở inventory, report và mô phỏng kiến trúc.
Nếu đọc đúng file này, bạn sẽ ít bị ngộ nhận về phạm vi thật của phần Python.
