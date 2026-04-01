# Tests, Khoảng Trống, Issue, Best Practice Và Performance Tips

## 1. Mục tiêu của chương này

Sau khi hiểu kiến trúc và luồng chạy, fresher thường hỏi 4 câu:

1. Code này đã được test đến đâu?
2. Chỗ nào đang là stub hoặc có vấn đề?
3. Nếu tiếp tục port thì nên giữ best practice gì?
4. Có mẹo hiệu năng nào cần biết không?

Chương này trả lời trực tiếp 4 câu đó.

```text
┌──────────────────────────────┐  ┌──────────────────────────────┐  ┌──────────────────────────────┐
│ safer areas                  │  │ mid-risk areas               │  │ high-risk areas              │
├──────────────────────────────┤  ├──────────────────────────────┤  ├──────────────────────────────┤
│ ├─ inventory loading         │  │ ├─ routing                   │  │ ├─ placeholder subsystems    │
│ ├─ reports                   │  │ ├─ bootstrap simulation      │  │ ├─ shallow permission model  │
│ ├─ parity summaries          │  │ └─ query engine flow         │  │ ├─ double-submit bug         │
│ └─ basic session persistence │  └──────────────────────────────┘  │ └─ runtime depth limited     │
└──────────────────────────────┘                                     └──────────────────────────────┘
```

## 2. Tình trạng test hiện tại

Test chính nằm trong:

- `claw-code/tests/test_porting_workspace.py`

Trong workspace mình đã chạy:

```bash
python -m unittest discover -s tests -v
```

và toàn bộ `22` test đều pass.

## 3. Test đang cover những gì?

### 3.1. Manifest và summary

Test xác nhận:

- manifest đếm được file Python
- summary render đúng tiêu đề và có command/tool surface

### 3.2. CLI inventory

Test chạy thật các lệnh:

- `summary`
- `parity-audit`
- `commands`
- `tools`
- `manifest`
- `command-graph`
- `tool-pool`
- `bootstrap-graph`

Điều này khá tốt vì:

- không chỉ test function-level
- còn test wiring của `main.py`

### 3.3. Routing và bootstrap

Test kiểm tra:

- `route` có trả match
- `bootstrap` in ra `Runtime Session`
- session bootstrap có matched tools và usage

### 3.4. Execution shim

Test có xác nhận:

- `exec-command` trả về chuỗi “Mirrored command ...”
- `exec-tool` trả về chuỗi “Mirrored tool ...”
- execution registry build được đủ số entry

### 3.5. Session và transcript

Test cover:

- `load-session`
- `flush-transcript`
- `turn-loop`

Tức là lớp stateful cơ bản đã được đụng tới.

### 3.6. Mode branching và setup

Test có chạy:

- `remote-mode`
- `ssh-mode`
- `teleport-mode`
- `direct-connect-mode`
- `deep-link-mode`
- `setup-report`

Nghĩa là surface branching được bảo vệ ở mức smoke test.

## 4. Test chưa cover tốt những gì?

Đây là phần quan trọng hơn cả.

### 4.1. Không có test bắt bug double-submit

`bootstrap_session()` hiện double-submit prompt, nhưng test vẫn pass.

Lý do:

- test chỉ kiểm tra có matched tools
- có `Prompt:` trong output
- usage lớn hơn hoặc bằng 1

Test không kiểm tra:

- số message thực lưu trong session
- usage bị cộng một lần hay hai lần
- session file chứa prompt bao nhiêu lần

### 4.2. Không có test import cho `task.py`

`src/task.py` hiện tự import:

```python
from .task import PortingTask
```

Đây là self-import sai và dẫn tới lỗi import.

Nhưng test suite hiện không import `src.task` hay `src.tasks` theo đường này, nên issue bị lọt.

### 4.3. Không test JSON lỗi hoặc file session hỏng

Ví dụ chưa có test cho:

- snapshot JSON bị corrupt
- session JSON bị thiếu field
- file không tồn tại

Điều này khiến robustness ở lớp IO chưa được chứng minh.

### 4.4. Không test false-positive của routing

Routing đang dùng match substring rất đơn giản.
Ví dụ prompt `review MCP tool` từng match command `UltrareviewOverageDialog`.

Đây là false-positive khá điển hình, nhưng chưa có test nào bắt chất lượng route.

## 5. Các issue kỹ thuật quan trọng đang thấy

### 5.1. Issue 1: `task.py` bị lỗi import vòng lặp

Hiện trạng:

- file `src/task.py` chỉ có `from .task import PortingTask`
- vì import chính nó, module không thể load đúng
- `src/tasks.py` cũng phụ thuộc vào `src.task`, nên chuỗi này bị gãy

Mức độ ảnh hưởng:

- chưa ảnh hưởng tới hầu hết CLI hiện tại
- nhưng làm hỏng một phần surface parity
- tạo cảm giác code “có file nhưng không dùng được”

Khuyến nghị:

- hoặc tạo dataclass `PortingTask` thật sự trong `task.py`
- hoặc đổi import sang module đúng nếu có file đích khác

### 5.2. Issue 2: `bootstrap_session()` mutate state hai lần

Hiện trạng:

- `stream_submit_message()` đã gọi `submit_message()`
- `bootstrap_session()` lại gọi `submit_message()` lần nữa

Ảnh hưởng:

- prompt bị lưu hai lần
- usage bị cộng hai lần
- persisted session sai lệch với kỳ vọng của người đọc report

Khuyến nghị:

- chọn một trong hai:
- hoặc stream chỉ phát event và không mutate
- hoặc bootstrap chỉ dùng kết quả từ stream, không submit lần hai

### 5.3. Issue 3: session persistence quá nghèo dữ liệu

Hiện lưu:

- `session_id`
- `messages`
- `input_tokens`
- `output_tokens`

Chưa lưu:

- output từng turn
- routed matches từng turn
- denial từng turn
- stream event
- timestamp
- mode/setup/context

Ảnh hưởng:

- khó replay
- khó debug hậu kiểm
- khó dùng làm audit trail

### 5.4. Issue 4: routing heuristic dễ nhiễu

Hiện route dựa vào:

- token xuất hiện trong `name`
- hoặc trong `source_hint`
- hoặc trong `responsibility`

Ưu điểm:

- siêu rẻ
- dễ hiểu

Nhược điểm:

- không semantic
- dễ dính substring noise
- ranking không đủ giàu để đại diện intent thật

### 5.5. Issue 5: nhiều package mới là placeholder metadata

Điều này không sai.
Nhưng nếu không ghi chú rõ, người mới rất dễ hiểu nhầm rằng:

- `assistant`
- `services`
- `components`
- `skills`

đã được port logic đáng kể, trong khi phần lớn mới là metadata package.

## 6. Best practice nên giữ khi tiếp tục port Python

### 6.1. Tách rõ “mirror surface” và “runtime implementation”

Nên giữ hai vùng trách nhiệm tách biệt:

- vùng inventory/snapshot/report
- vùng runtime thật

Lý do:

- tránh Python port nửa audit nửa production khiến boundary mờ
- dễ onboarding hơn

### 6.2. Ưu tiên dataclass và model nhỏ

Điểm mạnh hiện tại là model gọn và nhất quán.
Khi mở rộng, nên giữ phong cách:

- field ít nhưng rõ nghĩa
- immutability ở nơi phù hợp
- state mutation gom vào ít điểm

### 6.3. Mọi side effect phải dễ thấy

Bug double-submit xuất hiện vì API streaming cũng mutate state.

Best practice tốt hơn:

- tên hàm phải phản ánh side effect
- hoặc tách read-only stream builder khỏi state mutation

### 6.4. Dùng snapshot như source of truth có version

Nếu tiếp tục dựa nhiều vào snapshot, nên có:

- script regenerate snapshot
- version hoặc timestamp
- checksum hoặc commit id tham chiếu archive

Như vậy parity audit mới đáng tin hơn theo thời gian.

### 6.5. Test importability cho mọi module public

Một lớp Python port kiểu mirror rất dễ có file “tồn tại nhưng import hỏng”.

Nên có smoke test kiểu:

- import toàn bộ module top-level
- đảm bảo không vỡ do circular import hoặc stub sai

## 7. Performance tips thực tế

### 7.1. Caching snapshot là đúng hướng

`lru_cache(maxsize=1)` trong loader là hợp lý vì:

- JSON snapshot tương đối tĩnh
- process CLI ngắn
- tránh parse lại cùng file nhiều lần

### 7.2. Lookup theo tên có thể tối ưu thêm

Hiện `get_command()` và `get_tool()` scan tuyến tính toàn bộ tuple.

Với 207 command và 184 tool thì vẫn ổn.
Nhưng nếu tăng quy mô, nên cân nhắc:

- build `dict[str, PortingModule]` lower-case
- giữ tuple cho iteration, dict cho lookup

### 7.3. Search query hiện là O(n)

`find_commands()` và `find_tools()` đều scan toàn bộ danh sách.

Chấp nhận được cho inventory hiện tại.
Nếu sau này cần:

- fuzzy search
- semantic search
- ranking tốt hơn

thì nên tách sang index riêng thay vì vá trực tiếp vào loop hiện tại.

### 7.4. Session file nên có schema rõ ràng trước khi mở rộng

Nếu team định thêm:

- event log
- outputs
- timestamps

thì nên thiết kế schema versioned ngay từ đầu, tránh migration đau về sau.

## 8. Roadmap kỹ thuật đề xuất

### 8.1. Mức ưu tiên cao

- sửa `task.py`
- sửa double-submit trong `bootstrap_session()`
- thêm test bắt đúng hai issue trên

### 8.2. Mức ưu tiên trung bình

- làm giàu schema session persistence
- thêm smoke test import toàn bộ module top-level
- thêm error handling cho JSON/session file lỗi

### 8.3. Mức ưu tiên thấp nhưng đáng giá

- thêm index lookup cho command/tool
- tách route scoring thành module riêng
- thêm report giải thích false-positive / confidence

## 9. Checklist làm việc an toàn cho người mới

- luôn nhớ command/tool hiện tại đa số là shim
- khi thấy package có `__init__.py`, kiểm tra nó là metadata package hay runtime package
- khi thay session logic, kiểm tra side effect với `stream_submit_message()`
- khi đổi snapshot, chạy lại toàn bộ CLI smoke test
- khi thêm module mới, bổ sung test import và report path

## 10. Kết luận

Chất lượng nền của Python port là khá ổn cho mục tiêu audit và onboarding:

- code ngắn
- dễ đọc
- test smoke khá rộng

Nhưng để trở thành nền port chắc chắn hơn, cần xử lý sớm các điểm sau:

- import parity bị gãy ở `task.py`
- state mutation bị lặp ở bootstrap
- session persistence quá mỏng
- routing heuristic còn nhiều nhiễu
