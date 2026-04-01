# Routing Và Execution Shim

## 1. Chủ đề này tập trung vào đâu?

File này chỉ tập trung vào hai câu hỏi:

1. Prompt được route như thế nào?
2. Sau khi route xong, “thực thi” trong Python port thực chất là gì?

Đây là chỗ rất dễ bị hiểu sai khi mới đọc repo.

![Sơ đồ data flow runtime](assets/python-runtime-dataflow.png)

## 2. `route_prompt()` trong `runtime.py`

`PortRuntime.route_prompt()` là hàm quyết định:

- prompt nào match command nào
- prompt nào match tool nào
- top result nào sẽ được đưa vào báo cáo bootstrap

### 2.1. Cách tokenize

Hàm này không dùng tokenizer phức tạp.
Nó làm rất thẳng tay:

- thay `/` bằng dấu cách
- thay `-` bằng dấu cách
- split theo whitespace
- lower-case toàn bộ

Điều này cho thấy rõ mục tiêu:

- route nhanh
- route rẻ
- route đủ tốt để demo

chứ không phải:

- semantic routing production-grade

### 2.2. Cách score

Mỗi token được đem so với 3 “haystack”:

- `module.name`
- `module.source_hint`
- `module.responsibility`

Nếu token xuất hiện ở bất kỳ haystack nào, score tăng.

Ý nghĩa:

- trọng tâm của route là lexical overlap
- snapshot metadata quyết định mạnh chất lượng route

### 2.3. Cách chọn kết quả

Thuật toán chọn kết quả theo tinh thần:

- lấy một command đầu bảng nếu có
- lấy một tool đầu bảng nếu có
- phần còn lại mới lấp bằng leftovers score cao

Đây là một chi tiết thiết kế hay:

- nó ép báo cáo đầu ra thường có cả command và tool
- giúp output cân bằng hơn cho mục tiêu onboarding

## 3. Ưu điểm và nhược điểm của routing hiện tại

### 3.1. Ưu điểm

- cực dễ hiểu
- gần như không có chi phí vận hành
- không phụ thuộc model
- rất dễ test
- rất hợp với inventory mirror

### 3.2. Nhược điểm

- không hiểu intent sâu
- dễ dính false-positive
- phụ thuộc naming của snapshot
- không có confidence score giàu ý nghĩa

Ví dụ điển hình:

prompt `review MCP tool` có thể route ra command `UltrareviewOverageDialog`.
Phần `MCP` match tool khá tốt, nhưng phần command lại cho thấy nhược điểm lexical match.

## 4. `ExecutionRegistry` thực ra là gì?

`execution_registry.py` là cầu nối giữa:

- kết quả route
- execution shim

Registry build ra hai loại object:

- `MirroredCommand`
- `MirroredTool`

Mỗi object chỉ có:

- `name`
- `source_hint`
- `execute(...)`

Quan trọng nhất:

- `execute()` không chạy business logic thật
- nó chỉ gọi `execute_command()` hoặc `execute_tool()` ở lớp mirror

## 5. Vì sao gọi là execution shim?

“Shim” ở đây nghĩa là:

- lớp mỏng
- mô phỏng interface
- không mang đầy đủ hành vi thật

Ví dụ output hiện tại chỉ là câu kiểu:

- mirrored command X from Y would handle prompt Z
- mirrored tool A from B would handle payload C

Nó tồn tại để:

- giải thích mapping
- hỗ trợ bootstrap report
- giúp test wiring

chứ không tồn tại để:

- chạy nghiệp vụ
- gọi API thật
- thao tác file/hệ thống như runtime production

## 6. Cách `bootstrap_session()` dùng routing và registry

Flow hiện tại:

1. route prompt
2. lấy `matches`
3. build registry
4. với từng match command, gọi `registry.command(match.name).execute(prompt)`
5. với từng match tool, gọi `registry.tool(match.name).execute(prompt)`

Điểm hay:

- command execution message và tool execution message được tách riêng
- report dễ đọc
- người mới thấy được “nếu route vào đây thì hệ thống sẽ nghĩ gì”

Điểm dở:

- vì đây chỉ là shim, output dễ tạo ảo giác “hệ thống đã chạy”

## 7. `exec-command` và `exec-tool` ở CLI nên được hiểu thế nào?

Đừng hiểu là:

- chạy command thật
- chạy tool thật

Hãy hiểu là:

- yêu cầu lớp mirror giải thích xem entry nào sẽ nhận request này

Đây là công cụ học kiến trúc, không phải công cụ vận hành.

## 8. Nếu muốn nâng cấp routing thì nên nâng cấp ở đâu?

Có 3 hướng:

### 8.1. Nâng cấp lexical layer

- thêm weight khác nhau cho `name`, `source_hint`, `responsibility`
- phạt false-positive substring
- ưu tiên exact match hơn partial match

### 8.2. Nâng cấp metadata

- enrich `source_hint`
- thêm tags hoặc capability labels
- tách domain rõ hơn trong snapshot

### 8.3. Tách route engine riêng

- đưa scoring sang module riêng
- trả thêm confidence
- log vì sao một match được chọn

## 9. Best practice khi đọc kết quả route

- luôn xem `source_hint`
- đừng chỉ nhìn tên command/tool
- nếu kết quả “trông sai nhưng vẫn dính”, hãy nhớ đây là lexical score
- nếu cần xác minh, dùng tiếp `show-command` hoặc `show-tool`

## 10. Chốt lại

Routing trong Python port là lexical router phục vụ mục tiêu học kiến trúc.
Execution trong Python port là shim phục vụ mục tiêu giải thích mapping.

Hiểu đúng hai ý này sẽ giúp bạn không kỳ vọng sai vào phần runtime mô phỏng.
