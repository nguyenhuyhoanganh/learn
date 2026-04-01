# API, Provider, OAuth Và Streaming

## 1. Crate `api` giải bài toán gì

`claw-code/rust/crates/api` là lớp chuẩn hóa giao tiếp với model provider.

Nó phải giải đồng thời 4 việc:

- chọn provider đúng
- chuẩn hóa request/response
- hỗ trợ stream event
- xử lý auth đủ thực dụng

Đây là một lát cắt rất quan trọng vì nếu làm dở, runtime loop phía trên sẽ bị khóa vào từng vendor.

## 2. Mô hình abstraction của crate

```text
┌──────────────────────────┐
│ credentials / env / OAuth│
└──────┬───────────────────┘
       ▼
┌──────────────────────────┐
│ provider resolution      │
├──────────────────────────┤
│ ├─ Claw                  │
│ ├─ OpenAI                │
│ └─ xAI                   │
└──────┬───────────────────┘
       ▼
┌──────────────────────────┐
│ canonical request types  │
└──────┬───────────────────┘
       ▼
┌──────────────────────────┐
│ vendor translation       │
└──────┬───────────────────┘
       ▼
┌──────────────────────────┐
│ stream / retry / backoff │
└──────┬───────────────────┘
       ▼
┌──────────────────────────┐
│ normalized StreamEvent   │
└──────────────────────────┘
```

Các trục chính:

- `ProviderClient`
- provider modules
- canonical request/response types
- SSE parser

Kiến trúc này giúp các crate khác làm việc với một “ngôn ngữ nội bộ” chung thay vì nói trực tiếp bằng API shape của từng vendor.

## 3. Rust port không chỉ nói chuyện với một provider

Đây là điểm nhiều người dễ bỏ sót.

`ProviderClient` hiện có ít nhất các nhánh:

- `ClawApi`
- `OpenAi`
- `Xai`

Điều này có nghĩa:

- hệ thống không chỉ dành cho một backend duy nhất
- model/provider selection là một capability hạng nhất

## 4. Model và provider được chọn thế nào

Provider selection dựa trên:

- model family
- credential đang có
- env var

Ví dụ:

- model family của opus/sonnet/haiku đi theo nhánh Claw/Anthropic
- `OPENAI_API_KEY` mở đường cho provider OpenAI-compatible
- `XAI_API_KEY` mở đường cho xAI

Nếu không có tín hiệu mạnh, code có xu hướng mặc định về `ClawApi`.

## 5. Canonical type layer

`api/src/types.rs` định nghĩa các kiểu dùng chung như:

- `MessageRequest`
- `InputMessage`
- `InputContentBlock`
- `ToolDefinition`
- `ToolChoice`
- `MessageResponse`
- `OutputContentBlock`
- `StreamEvent`

Đây là bước rất đúng về kiến trúc:

- normalize inbound/outbound shape
- giảm coupling giữa runtime và vendor-specific format

## 6. Streaming được chuẩn hóa ra sao

Provider-specific stream sẽ được normalize thành các event nội bộ như:

- `MessageStart`
- `MessageDelta`
- `ContentBlockStart`
- `ContentBlockDelta`
- `ContentBlockStop`
- `MessageStop`

Nhờ đó runtime loop chỉ cần hiểu một loại stream protocol nội bộ.

## 7. `claw_provider.rs` thể hiện mức độ production của code

Những gì file này đang xử lý:

- API key auth
- bearer token auth
- saved OAuth credential
- token refresh
- base URL override
- retry
- exponential backoff
- SSE streaming
- request id header

Đây là dấu hiệu cho thấy Rust port đã chạm vào bài toán production engineering chứ không chỉ là API demo.

## 8. OpenAI-compatible adapter quan trọng ở chỗ nào

`openai_compat.rs` làm nhiệm vụ:

- dịch canonical message format sang chat-completions shape
- normalize tool calls về event nội bộ
- giữ cho runtime phía trên không phải quan tâm vendor-specific detail

Đây là phần kiến trúc rất đáng giá vì nó giữ lõi runtime sạch hơn.

## 9. OAuth nằm ở đâu trong toàn hệ thống

OAuth có mặt ở hai nơi:

- CLI login/logout flow
- runtime oauth storage và request builder

`runtime/src/oauth.rs` cung cấp:

- PKCE pair
- state generation
- authorization request builder
- token exchange request
- refresh request
- credential persistence

Điểm hay:

- CLI lo user interaction
- runtime lo protocol object và credential store

## 10. Upstream proxy và remote session context

`runtime/src/remote.rs` giải thêm bài toán môi trường remote:

- có remote session context hay không
- có upstream proxy hay không
- token path ở đâu
- CA bundle ở đâu
- no-proxy list là gì
- subprocess env cần bơm gì

Tức là code đã nghĩ tới trường hợp runtime không chỉ chạy đơn giản trên laptop local.

## 11. Performance và reliability pattern trong lớp API

Các pattern đáng chú ý:

- retry với backoff
- auth source resolution từ nhiều nguồn
- canonical stream event để giảm branching phía trên
- model-specific max token heuristics
- tách parser SSE riêng

Đây là các kỹ thuật nhỏ nhưng rất thực dụng.

## 12. Rủi ro cần chú ý

### Alias/model routing drift

Nếu danh sách model alias và mapping provider không cập nhật kịp, user sẽ thấy hành vi khó hiểu.

### Multi-provider complexity

Càng nhiều provider, nguy cơ:

- semantic mismatch của tool call
- streaming mismatch
- auth mismatch
- limit mismatch

### Remote/bootstrap environment drift

Proxy, CA bundle, token path và env kế thừa là nhóm lỗi rất khó debug nếu không log tốt.

## 13. Kết luận

Crate `api` là lớp “phiên dịch ngoại giao” của hệ thống.

Nó cho phép:

- runtime nói chuyện với nhiều backend
- vẫn giữ một conversation loop thống nhất
- vẫn giữ auth, retry, streaming và token flow đủ bài bản
