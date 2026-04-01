# Setup, Bootstrap Và Mode Branching

## 1. Chủ đề này giải thích cái gì?

File này zoom vào phần “khởi động hệ thống” trong Python port:

- `setup.py`
- `bootstrap_graph.py`
- `system_init.py`
- `remote_runtime.py`
- `direct_modes.py`

Đây là nhóm file nói lên một điều rất quan trọng:

- Python port đang cố mirror trình tự khởi động của hệ thống gốc
- nhưng mới mirror ở mức hình dạng flow, chưa phải side effect production

```text
bootstrap path
  CLI -> runtime.bootstrap_session()
      -> context + setup
      -> route_prompt()
      -> registry shims
      -> query engine
      -> session report
```

```text
setup.py
  |
  +--> prefetch stubs
  +--> project scan
  +--> deferred init
  |
  v
bootstrap_graph intent
  |
  v
mode branching
  +--> report path
  +--> runtime simulation path
  +--> audit path
```

## 2. `setup.py` đang làm gì thật sự?

`run_setup()` tạo ra `SetupReport`.
Nó không bootstrap một runtime thật, mà tạo một báo cáo startup có cấu trúc.

Trình tự cơ bản:

1. xác định root hiện tại
2. gọi prefetch giả lập
3. chạy deferred init giả lập
4. gom tất cả thành `SetupReport`

### 2.1. Ba prefetch đang có

- `start_mdm_raw_read()`
- `start_keychain_prefetch()`
- `start_project_scan(root)`

Điểm cần hiểu đúng:

- đây chủ yếu là shape-preserving stubs
- chúng tồn tại để kể lại startup intent
- không nên đọc như integration production hoàn chỉnh

### 2.2. Deferred init

`run_deferred_init(trusted=...)` cho thấy hệ thống muốn giữ khái niệm:

- có bước khởi tạo chỉ chạy sau trust gate
- plugin/tooling có thể được bật theo điều kiện

Đây là pattern rất phổ biến trong hệ agent hoặc CLI lớn:

- prefetch nhanh ở đầu
- init tốn kém hoặc nhạy cảm được đẩy về sau

## 3. `bootstrap_graph.py` có giá trị gì?

Đây không phải file “điều khiển bootstrap”.
Đây là file mô tả các stage của bootstrap graph.

Giá trị của nó nằm ở chỗ:

- nói ra kiến trúc mong muốn
- gom lại các phase theo ngôn ngữ dễ onboarding
- giúp người mới biết nên tìm logic ở đâu

Các stage được mirror:

1. top-level prefetch side effects
2. warning handler và environment guards
3. CLI parser và trust gate
4. setup + load command/agents
5. deferred init sau trust
6. mode routing
7. query engine submit loop

Đây là một trong những file “đáng đọc dù không chạy nhiều”.

## 4. `system_init.py`: vì sao tồn tại?

`build_system_init_message(trusted=True)` ghép các thông tin kiểu:

- trusted hay không
- built-in command names count
- tổng số command entries
- tổng số tool entries
- startup steps

Nó giúp report `bootstrap` có cảm giác giống một runtime đang tự mô tả trạng thái khởi động.

Nói ngắn:

- đây là lớp kể chuyện hệ thống
- không phải lớp thực thi nghiệp vụ

## 5. Flow bootstrap trong `runtime.py`

Khi gọi `PortRuntime.bootstrap_session(prompt)`:

1. build context
2. run setup
3. tạo history log
4. tạo query engine
5. route prompt
6. build execution registry
7. tạo command/tool execution messages
8. stream submit
9. submit turn
10. persist session
11. dựng `RuntimeSession`

Điều hay:

- report cuối rất giàu thông tin
- onboarding cực dễ vì mọi thứ nằm trong một output

Điều dở:

- có bug double-submit ở bước 8 và 9

## 6. Mode branching đang được giữ ở mức nào?

Hiện có các mode:

- remote
- ssh
- teleport
- direct-connect
- deep-link

Nhìn từ CLI, tưởng đây là các nhánh runtime rõ ràng.
Nhưng đọc code sẽ thấy:

- chúng chủ yếu trả report text
- chưa có transport layer hoặc protocol handling thực sự sâu

Ý nghĩa của các mode này trong Python port là:

- giữ surface parity
- giữ vocabulary kiến trúc
- giúp người đọc biết hệ thống gốc từng có các nhánh kết nối nào

## 7. Tại sao giữ mode branching dù chưa có runtime thật vẫn là quyết định tốt?

Với code porting, có 2 kiểu mất mát rất hay xảy ra:

1. mất logic
2. mất bản đồ khái niệm

Python port hiện chưa có đầy đủ logic, nhưng cố giữ lại bản đồ khái niệm.
Đó là lý do mode branching vẫn đáng tồn tại.

Lợi ích:

- onboarding dễ hơn
- parity audit dễ hơn
- sau này port tiếp sẽ có “móc treo” rõ ràng

## 8. Những gì bootstrap hiện chưa làm

- chưa gọi model thật
- chưa có trust gate an ninh chặt chẽ
- chưa có prefetch backend thật
- chưa có plugin loading thật
- chưa có remote session thật
- chưa có network handshake thật

Nếu không nhấn mạnh điều này, người mới rất dễ đánh giá quá cao độ hoàn thiện của lớp bootstrap.

## 9. Best practice khi đọc nhóm file này

- luôn xem `setup.py` là startup simulation, không phải startup kernel
- xem `bootstrap_graph.py` như architectural note
- khi gặp mode branch, kiểm tra output có phải text report không
- khi đọc `RuntimeSession`, phân biệt dữ liệu thật với dữ liệu mô phỏng

## 10. Chốt lại

Nhóm setup/bootstrap/mode branching là nơi Python port giữ “ý đồ khởi động” của hệ thống gốc.
Nó chưa chạy thế giới thật, nhưng rất hữu ích để người mới hiểu:

- hệ thống khởi động theo pha nào
- niềm tin/trust gate nằm ở đâu
- các mode vận hành lớn được phân nhánh thế nào
