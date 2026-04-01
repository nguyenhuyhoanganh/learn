# Runtime Conversation, Session Và Compaction

## 1. Tim thật của agent nằm ở đâu

Nếu phải chọn một file quan trọng nhất của Rust runtime, đó là:

- `claw-code/rust/crates/runtime/src/conversation.rs`

File này chứa `ConversationRuntime<C, T>` với hai dependency abstraction chính:

- `ApiClient`
- `ToolExecutor`

Ý nghĩa:

- runtime không bị khóa cứng vào một provider cụ thể
- runtime cũng không bị khóa cứng vào một loại tool executor cụ thể

Đây là thiết kế tốt vì agent loop và hạ tầng tích hợp được tách ra.

## 2. Agent loop giải bài toán gì

Bài toán thực tế:

- nhận user message
- gửi message history cho model
- đọc event stream
- ghép thành assistant message
- phát hiện tool use
- xin quyền hoặc chặn
- chạy tool
- append tool result
- lặp lại cho đến khi assistant dừng

Rust encode bài toán này thành một loop rõ ràng, không cần dựa vào quá nhiều side effect ngầm.

## 3. Luồng `run_turn()` từng bước

```text
user text
└─ push user message into Session
   └─ build ApiRequest(system prompt + history)
      └─ ApiClient.stream()
         └─ AssistantEvent(s)
            └─ assistant message + usage
               ├─ no tool use
               │  └─ finish turn
               └─ tool use(s)
                  └─ PermissionPolicy
                     └─ pre-hook
                        └─ ToolExecutor
                           └─ post-hook
                              └─ tool result
                                 └─ push to Session
                                    └─ loop again
```

Luồng ở mức khái niệm:

1. nhận text từ user
2. push message user vào session
3. build `ApiRequest { system_prompt, messages }`
4. gọi `api_client.stream(request)`
5. nhận về `AssistantEvent`
6. dựng assistant message từ text delta + tool use
7. record usage vào `UsageTracker`
8. push assistant message vào session
9. extract danh sách pending tool uses
10. với mỗi tool use:
11. check `PermissionPolicy`
12. chạy pre-hook
13. nếu được phép thì `tool_executor.execute()`
14. chạy post-hook
15. push tool result vào session
16. nếu có tool use thì lặp thêm một iteration
17. nếu không còn tool use thì kết thúc turn

## 4. Vì sao thiết kế này tốt

### 4.1. Tách abstraction đúng chỗ

`ApiClient` và `ToolExecutor` là đúng hai chỗ nên được tách.

Nhờ vậy:

- có thể đổi provider mà không đụng loop
- có thể đổi tool backend mà không đụng loop
- test loop end-to-end dễ hơn

### 4.2. Permission và hook nằm đúng giữa model và execution

Đây là điểm cực kỳ quan trọng.

Tool call không đi thẳng từ model sang execution.
Nó đi qua:

- permission policy
- pre-hook
- post-hook

Nghĩa là hệ thống có “trust gate” ở chỗ nhạy cảm nhất.

## 5. Session model giàu hơn Python rất nhiều

`runtime/src/session.rs` định nghĩa:

- `MessageRole`
- `ContentBlock`
- `ConversationMessage`
- `Session`

### `MessageRole`

Gồm:

- `System`
- `User`
- `Assistant`
- `Tool`

### `ContentBlock`

Gồm:

- `Text`
- `ToolUse`
- `ToolResult`

### `ConversationMessage`

Một message có:

- role
- danh sách content block
- usage tùy chọn

### Ý nghĩa

Session đã đủ giàu để:

- lưu multi-block response
- replay tool call history
- track usage theo message
- resume tốt hơn
- compact có ngữ nghĩa hơn

## 6. Usage tracking vận hành thế nào

`runtime/src/usage.rs` giải bài toán:

- tính latest turn usage
- tính cumulative usage
- estimate cost theo model pricing

Điểm đáng chú ý:

- có pricing khác nhau cho haiku, sonnet, opus
- có cả token cache write và cache read
- tracker có thể dựng lại từ session cũ

Đây là một thiết kế thực dụng vì session persistence và cost tracking không bị rời nhau.

## 7. Compaction không phải chỉ là cắt bớt message

```text
new turn data
└─ Session(messages + blocks + usage)
   ├─ UsageTracker
   │  ├─ latest
   │  ├─ cumulative
   │  └─ cost estimate
   └─ token estimate
      ├─ small enough
      │  └─ keep raw history
      └─ too large
         └─ compact old part
            └─ continuation summary
               └─ keep recent messages + continue
```

`runtime/src/compact.rs` làm nhiều hơn việc xóa lịch sử cũ.

Nó:

- ước lượng token của session
- quyết định khi nào nên compact
- giữ lại phần recent messages
- tổng hợp phần cũ thành summary có cấu trúc
- trộn với compact summary trước đó nếu đã compact rồi
- inject một `System` message làm continuation context

Tức là compaction ở đây mang ý nghĩa:

- nén lịch sử
- nhưng vẫn bảo toàn ý định công việc
- và hướng dẫn agent tiếp tục đúng mạch

## 8. Một compact summary tốt đang chứa gì

Code cố giữ các loại thông tin như:

- scope công việc
- tools đã dùng
- request gần đây của user
- pending work
- file quan trọng
- timeline hiện tại

Đây là lý do compaction của Rust có giá trị thật, không chỉ là tiết kiệm token.

## 9. Hook runtime hoạt động ra sao

`runtime/src/hooks.rs` cho phép khai báo shell hook ở hai thời điểm:

- `PreToolUse`
- `PostToolUse`

Quy ước exit code:

- `0` -> cho phép
- `2` -> deny
- non-zero khác -> warning nhưng vẫn tiếp tục

Payload được đưa vào qua stdin và env var như:

- `HOOK_EVENT`
- `HOOK_TOOL_NAME`

Thiết kế này giúp chèn policy hoặc audit logic bên ngoài mà không phải sửa runtime core.

## 10. Dừng vòng lặp bằng gì

Hai nhóm stop condition chính:

- không còn tool use cần chạy
- chạm `max_iterations`

Điều này tránh agent loop vô hạn khi model cứ liên tục yêu cầu tool.

## 11. Test coverage của runtime loop nói gì

Source test cho thấy đã có kiểm tra các case như:

- user -> tool -> assistant
- tool bị deny
- pre-hook deny
- post-hook feedback
- restore usage từ session cũ
- compaction

Điều này tăng độ tin cậy của lõi runtime hơn rất nhiều so với việc chỉ có unit test từng hàm nhỏ.

## 12. Góc nhìn senior

### Điểm tốt

- loop rõ, ít ma thuật
- typed session model tốt
- compaction có intent rõ
- permission/hook nằm đúng vị trí
- usage tracking gắn chặt với session

### Điểm cần cảnh giác

- nếu thêm tool mới mà quên map permission hoặc output block đúng cách, loop có thể lệch hành vi
- nếu compact summary không đủ tốt, agent resume sẽ “mất ngữ cảnh mềm”
- nếu hook bên ngoài có latency cao, turn time sẽ tăng rất rõ

## 13. Kết luận

`ConversationRuntime` là phần cần hiểu sâu nhất trong toàn bộ Rust workspace.

Mọi người mới vào dự án nên nhớ:

- CLI chỉ đưa prompt vào hệ thống
- nhưng chính runtime loop mới biến prompt thành một agent có tool, permission, hooks, session và compaction
