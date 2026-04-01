# Query Engine, Transcript Và Session Persistence

## 1. Vì sao file này quan trọng?

Nếu `main.py` là cửa vào CLI, thì `query_engine.py` là nơi giữ phần stateful nhất của Python port.

Đây là chỗ mô phỏng:

- vòng đời một turn
- lưu prompt đã gửi
- cộng dồn usage
- ghi transcript
- persist session ra file JSON
- phát stream event kiểu runtime

Muốn hiểu “Python port này chạy như thế nào khi nhận prompt”, gần như bắt buộc phải hiểu file này.

## 2. Mô hình dữ liệu chính trong `query_engine.py`

### 2.1. `QueryEngineConfig`

Config này định nghĩa giới hạn vận hành của engine:

| Field | Ý nghĩa | Giá trị mặc định |
|---|---|---|
| `max_turns` | số prompt tối đa được nhận vào `mutable_messages` | `8` |
| `max_budget_tokens` | ngưỡng tổng `input_tokens + output_tokens` | `2000` |
| `compact_after_turns` | số message/transcript tối đa được giữ lại sau khi compact | `12` |
| `structured_output` | có render JSON output hay không | `False` |
| `structured_retry_limit` | số lần thử render structured output | `2` |

Điểm cần lưu ý:

- đây là config của lớp mô phỏng, không phải token budget thật từ model vendor
- budget được ước lượng bằng dataclass `UsageSummary`, không phải tokenizer production

### 2.2. `TurnResult`

Đây là “kết quả cuối” của một turn:

- `prompt`
- `output`
- `matched_commands`
- `matched_tools`
- `permission_denials`
- `usage`
- `stop_reason`

Ý nghĩa thiết kế:

- tách state mutation ra khỏi dữ liệu trả về cho caller
- cho phép `runtime.py` và CLI in report khá dễ

### 2.3. `QueryEnginePort`

Đây là object stateful chính. Nó giữ:

- `manifest`
- `config`
- `session_id`
- `mutable_messages`
- `permission_denials`
- `total_usage`
- `transcript_store`

Hiểu ngắn gọn:

- `mutable_messages` là “lịch sử prompt đang được giữ để session tiếp tục”
- `transcript_store` là buffer hỗ trợ replay/flush
- `total_usage` là số liệu cộng dồn toàn session

## 3. Hai cách khởi tạo engine

### 3.1. `from_workspace()`

Tạo một engine mới:

- đọc manifest hiện tại bằng `build_port_manifest()`
- sinh `session_id` mới
- bắt đầu với state rỗng

Use case:

- chạy `summary`
- chạy `flush-transcript`
- bootstrap một session mới
- turn loop mô phỏng

### 3.2. `from_saved_session(session_id)`

Load session từ file JSON qua `load_session()`:

- đọc file `.port_sessions/<session_id>.json`
- đưa `messages` cũ vào `mutable_messages`
- tạo `TranscriptStore(entries=list(stored.messages), flushed=True)`
- khôi phục `UsageSummary`

Điểm hay:

- load lại session rất rẻ
- không cần restore object phức tạp

Điểm hạn chế:

- chỉ restore được prompt history và token totals
- không restore được matched commands/tools từng turn
- không restore full stream events hay output text

## 4. Luồng xử lý của `submit_message()`

Đây là hàm quan trọng nhất.

### 4.1. Guard đầu vào

Nếu số lượng `mutable_messages` đã đạt `max_turns`, engine không mutate thêm state mà trả `TurnResult` với:

- `output = "Max turns reached..."`
- `stop_reason = "max_turns_reached"`

Ý nghĩa:

- bảo vệ session khỏi chạy vô hạn
- đơn giản, dễ test

### 4.2. Sinh output tóm tắt

Engine không gọi model thật.
Nó chỉ dựng các dòng summary:

- prompt là gì
- matched commands là gì
- matched tools là gì
- có bao nhiêu permission denials

Sau đó:

- nếu `structured_output=False`, nối các dòng bằng `\n`
- nếu `structured_output=True`, render JSON bằng `_render_structured_output()`

### 4.3. Tính usage

Engine gọi `self.total_usage.add_turn(prompt, output)`.

Ý nghĩa:

- usage không đến từ tokenizer thật
- đây chỉ là heuristic accounting để mô phỏng budget pressure

### 4.4. Cập nhật state

Nếu turn được xử lý:

- append `prompt` vào `mutable_messages`
- append `prompt` vào `transcript_store`
- nối thêm `denied_tools` vào `permission_denials`
- cập nhật `total_usage`
- gọi `compact_messages_if_needed()`

Tức là state mutation thực sự diễn ra ở đây, không nằm ở `runtime.py`.

## 5. Structured output hoạt động ra sao?

Nếu bật `--structured-output` trong `turn-loop`, output mỗi turn sẽ là JSON dạng:

```json
{
  "summary": [
    "Prompt: ...",
    "Matched commands: ...",
    "Matched tools: ..."
  ],
  "session_id": "..."
}
```

Điểm đáng chú ý:

- retry loop trong `_render_structured_output()` gần như chỉ là defensive branch
- payload hiện tại rất đơn giản nên gần như không có rủi ro serialize thất bại
- mục đích chính là mô phỏng “hệ thống có structured mode”

## 6. `stream_submit_message()`: streaming nhưng vẫn mutate state

Hàm này yield lần lượt:

- `message_start`
- `command_match`
- `tool_match`
- `permission_denial`
- `message_delta`
- `message_stop`

Nhưng quan trọng hơn:

- ngay giữa stream, nó gọi `self.submit_message(...)`
- nghĩa là stream không chỉ “phát sự kiện”
- stream cũng là nơi mutate session state

Đây là điểm rất dễ bị gọi sai ở lớp orchestration phía trên.

## 7. `TranscriptStore` và `SessionStore` khác nhau thế nào?

### 7.1. `TranscriptStore`

`transcript.py` rất nhỏ, chỉ có:

- `append(entry)`
- `compact(keep_last)`
- `replay()`
- `flush()`

Đặc điểm:

- in-memory
- chỉ giữ list string
- `flush()` chỉ đổi cờ `flushed=True`
- không tự ghi ra file

Nói cách khác:

- transcript store là buffer logic
- không phải persistence backend

### 7.2. `SessionStore`

`session_store.py` mới là nơi ghi file.

Schema lưu hiện tại:

```json
{
  "session_id": "...",
  "messages": ["prompt 1", "prompt 2"],
  "input_tokens": 123,
  "output_tokens": 456
}
```

Từ đây có thể rút ra:

- session persistence đang rất tối giản
- đây là persistence của prompt history, không phải conversation log đầy đủ

## 8. Vòng đời persist session

`persist_session()` trong `QueryEnginePort` làm 2 việc:

1. gọi `flush_transcript()`
2. gọi `save_session(...)`

Lưu ý rất quan trọng:

- `flush_transcript()` chỉ set `TranscriptStore.flushed=True`
- nó không xóa entries
- file được lưu từ `mutable_messages`, không phải từ `transcript_store.entries`

Vì thế:

- `transcript` và `session file` có liên quan nhưng không đồng nhất hoàn toàn
- dev mới rất dễ tưởng `flush()` là “đẩy transcript ra đĩa”, nhưng thực tế không phải

## 9. Sơ đồ trạng thái của một session

```text
┌──────────────┐    ┌──────────────────────────┐    ┌──────────────────────────┐
│  new engine  │───►│ ready state              │───►│ submit_message()         │
└──────────────┘    ├──────────────────────────┤    ├──────────────────────────┤
                    │ ├─ session_id            │    │ ├─ completed             │
                    │ ├─ mutable_messages      │    │ ├─ max_budget_reached    │
                    │ └─ usage                 │    │ ├─ max_turns_reached     │
                    └──────────────────────────┘    │ └─ flush + save_session  │
                                                    └──────────────────────────┘
```

Ảnh trên giúp phân biệt rõ:

- engine mới được tạo như thế nào
- state chuyển sang `Processing` lúc nào
- các điều kiện dừng ở đâu
- transcript buffer khác persisted session file ra sao

## 10. Điểm mạnh của thiết kế hiện tại

- state model ngắn, dễ đọc
- không phụ thuộc external service
- dễ test bằng unit test
- rất hợp để mô phỏng turn loop cho onboarding
- serialization JSON đơn giản nên ít lỗi vận hành

## 11. Điểm yếu và bẫy kỹ thuật

### 11.1. Bug double-submit trong `runtime.py`

Trong `PortRuntime.bootstrap_session()` hiện tại:

- gọi `engine.stream_submit_message(...)`
- mà `stream_submit_message()` nội bộ đã gọi `submit_message(...)`
- sau đó `bootstrap_session()` lại gọi `engine.submit_message(...)` thêm một lần nữa

Hệ quả:

- cùng một prompt bị append hai lần vào session
- usage bị cộng hai lần
- session file sau bootstrap không phản ánh “1 prompt = 1 turn”

Đây là issue kiến trúc rõ ràng nhất của flow hiện tại.

### 11.2. Session model quá mỏng

Session file chưa lưu:

- assistant output từng turn
- matched commands/tools từng turn
- denials từng turn
- timestamp
- mode/context/setup metadata

Nghĩa là:

- đủ để demo
- chưa đủ để replay/debug sâu

### 11.3. `flush()` dễ gây hiểu lầm

Tên `flush_transcript()` nghe giống “ghi transcript ra storage”.
Nhưng code hiện tại chỉ đổi cờ trạng thái.

Nếu team phát triển tiếp, nên đặt tên rõ hơn như:

- `mark_transcript_flushed()`
- hoặc bổ sung backend flush thật

## 12. Fresher nên nhớ gì ở phần này?

Có 4 ý cần nhớ:

1. `QueryEnginePort` là state holder chính của Python port.
2. `submit_message()` mới là nơi mutate turn state.
3. `stream_submit_message()` không thuần read-only; nó cũng mutate state.
4. Session persistence hiện tại là prompt history tối giản, chưa phải full conversation persistence.

## 13. Gợi ý cải tiến nếu tiếp tục phát triển

- tách hẳn `prepare_turn_result()` và `apply_turn_result()` để tránh side effect mơ hồ
- sửa `bootstrap_session()` để chỉ có đúng một lần submit
- lưu session theo schema giàu hơn, có `turns[]`
- thêm timestamp và mode/context metadata
- phân biệt rõ transcript buffer và persisted conversation log

## 14. Kết luận

`query_engine.py` là trái tim của lớp mô phỏng state trong Python port.
Nó được viết theo hướng cực gọn, dễ học, dễ test, nhưng đang ưu tiên “minh hoạ kiến trúc” hơn là “mô phỏng runtime trung thực”.
