# `query_engine.py`: Stateful Core Của Python Port

## 1. Vì sao `query_engine.py` là file quan trọng nhất?

Nếu cần chọn một file duy nhất đại diện cho “runtime behavior” của Python port, đó là `query_engine.py`.

Lý do:

- nó giữ state của session
- nó xử lý một turn
- nó cộng dồn usage
- nó ghi transcript
- nó persist session
- nó phát stream event mô phỏng

Nhiều file khác chủ yếu là:

- inventory
- report
- glue code

Nhưng `query_engine.py` là nơi state thực sự thay đổi.

## 2. Ba lớp dữ liệu cốt lõi

### 2.1. `QueryEngineConfig`

Config này định nghĩa giới hạn hoạt động:

- `max_turns`
- `max_budget_tokens`
- `compact_after_turns`
- `structured_output`
- `structured_retry_limit`

Ý nghĩa:

- đây là policy layer rất mỏng
- config ít nhưng đánh dấu đủ các concern quan trọng: turn limit, budget limit, output mode

### 2.2. `TurnResult`

Đây là object đầu ra của một turn.
Nó tách biệt khá rõ với state bên trong engine.

Field của nó nói lên engine đang quan tâm gì:

- prompt nào vừa xử lý
- output gì được sinh ra
- command/tool nào match
- denial nào bị chặn
- usage tích luỹ đang là bao nhiêu
- vì sao turn dừng

### 2.3. `QueryEnginePort`

Đây là object stateful thật sự.
Nó giữ:

- `manifest`
- `config`
- `session_id`
- `mutable_messages`
- `permission_denials`
- `total_usage`
- `transcript_store`

Mental model tốt nhất:

- `QueryEnginePort` là một state machine nhỏ
- mỗi lần `submit_message()` là một lần state machine tiến một bước

```text
user prompt
  |
  v
submit_message()
  |
  +--> append to mutable_messages
  +--> append to transcript
  +--> update token counters
  +--> decide stop_reason
  |
  v
return TurnResult
```

## 3. `from_workspace()` và `from_saved_session()`

### 3.1. `from_workspace()`

Dùng khi muốn bắt đầu session mới.

Nó:

- dựng manifest mới
- sinh `session_id`
- tạo state rỗng

Phù hợp cho:

- `summary`
- `flush-transcript`
- `turn-loop`
- bootstrap session mới

### 3.2. `from_saved_session(session_id)`

Dùng khi cần load lại session cũ.

Nó:

- đọc file JSON
- restore `mutable_messages`
- restore `UsageSummary`
- tạo `TranscriptStore` từ messages cũ

Điểm hay:

- rất đơn giản
- dễ hiểu
- ít rủi ro restore hỏng object graph

Điểm dở:

- restore được rất ít ngữ cảnh

## 4. `submit_message()` là nơi state mutate

Đây là điểm phải nhớ kỹ nhất trong toàn bộ Python port.

`submit_message()`:

- kiểm tra turn limit
- dựng output text
- tính projected usage
- append prompt vào message history
- append prompt vào transcript
- nối denial
- cập nhật usage
- compact nếu cần

Tức là:

- mọi side effect chính của turn đều tập trung ở đây

Đây là một quyết định thiết kế tốt vì:

- state mutation không bị rải quá nhiều nơi
- dễ test hơn
- dễ audit hơn

## 5. `stream_submit_message()` không chỉ stream

Tên hàm dễ khiến người đọc nghĩ:

- nó chỉ phát event

Nhưng thực tế:

- nó còn gọi `submit_message()` bên trong

Trình tự:

1. yield `message_start`
2. yield `command_match` nếu có
3. yield `tool_match` nếu có
4. yield `permission_denial` nếu có
5. gọi `submit_message()`
6. yield `message_delta`
7. yield `message_stop`

Điểm này cực kỳ quan trọng vì:

- ai dùng hàm này phải biết nó có side effect
- nếu caller lại gọi `submit_message()` thêm lần nữa thì state sẽ bị nhân đôi

## 6. Output được tạo như thế nào?

Output hiện không đến từ model.
Nó chỉ là phần tóm tắt do engine tự dựng.

Các dòng cơ bản:

- prompt
- matched commands
- matched tools
- permission denials count

Sau đó:

- nếu không bật structured mode, nối thành text nhiều dòng
- nếu bật structured mode, serialize thành JSON

Điều này cho thấy:

- lớp Python đang mô phỏng giao diện turn result
- chưa mô phỏng generation behavior thật

## 7. `UsageSummary` ở đây nên hiểu ra sao?

Usage trong Python port là heuristic, không phải usage token thật từ model backend.

Điều đó có 2 hệ quả:

- rất phù hợp cho demo budget concept
- không phù hợp nếu ai đó muốn đo chi phí hay context window thật

Khi onboarding, nên dặn rõ:

- `max_budget_tokens` trong Python port là budget mô phỏng

## 8. Compact message có ý nghĩa gì?

`compact_messages_if_needed()`:

- cắt `mutable_messages` về tối đa `compact_after_turns`
- gọi `transcript_store.compact(...)`

Mục tiêu:

- giữ session không phình vô hạn
- mô phỏng ý tưởng compact history

Nhưng đây chưa phải “conversation summarization” thật.
Nó chỉ là trim list.

## 9. Structured output có giá trị gì?

Structured output ở đây tuy đơn giản nhưng vẫn hữu ích vì:

- nó cho thấy system đã tính tới nhu cầu output machine-readable
- test có thể cover nhánh khác nhau của output mode
- sau này muốn mở rộng schema sẽ có điểm móc sẵn

Nhưng hiện tại schema còn rất mỏng:

- chỉ có `summary`
- chỉ có `session_id`

## 10. Những điểm thiết kế tốt trong file này

- dataclass rõ ràng
- state mutation gom vào ít chỗ
- API constructor tách rõ new session và load session
- structured output có defensive retry
- transcript và persistence được gọi qua abstraction riêng

## 11. Những điểm yếu cần chú ý

### 11.1. `stream_submit_message()` có side effect nhưng tên chưa nói rõ

Đây là nguồn gốc của bug orchestration hiện tại.

### 11.2. `mutable_messages` chỉ giữ prompt

Không có:

- assistant output history
- tool output history
- role metadata
- timestamp

### 11.3. Session model còn nghèo

Vì state được lưu nghèo, khả năng replay/debug cũng nghèo theo.

## 12. Nếu tiếp tục phát triển file này thì nên đi hướng nào?

- tách rõ “prepare turn” và “apply turn”
- phân biệt stream builder với mutation path
- lưu `turns[]` thay vì chỉ lưu `messages[]`
- bổ sung timestamp và role
- nếu cần, thêm summarization thật thay cho trim đơn thuần

## 13. Chốt lại

`query_engine.py` là lõi stateful thật sự của Python port.
Hiểu file này là điều kiện bắt buộc để hiểu:

- vì sao session hoạt động như hiện tại
- vì sao bootstrap có bug double-submit
- vì sao persistence hiện vẫn mang tính mô phỏng hơn là production
