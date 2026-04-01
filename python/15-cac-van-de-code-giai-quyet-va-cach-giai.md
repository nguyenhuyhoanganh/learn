# Các Vấn Đề Mà Python Port Đang Giải Quyết, Cách Giải, Luồng Giải Quyết Và Công Cụ Sử Dụng

## 1. Mục tiêu của file này

Phần lớn các file trước giải thích theo module hoặc theo luồng code.
File này đi theo hướng khác:

- bài toán là gì
- vì sao bài toán đó tồn tại
- Python port đang giải bài toán đó bằng cách nào
- luồng xử lý cụ thể ra sao
- dùng những module, dữ liệu và kỹ thuật gì

Đây là file rất phù hợp cho:

- fresher muốn hiểu “tại sao dự án này tồn tại”
- người review muốn thấy kiến trúc ở mức problem-solution
- người chuẩn bị port tiếp muốn biết đâu là chiến lược hiện tại

```text
problem → solution style in Python port
├─ inventory visibility
│  └─ snapshots + cached metadata loaders
├─ routing simulation
│  └─ simple matching + registry bridge
├─ state demonstration
│  └─ QueryEnginePort + transcript/session store
├─ parity measurement
│  └─ reference data + audit reports
└─ deep runtime execution
   └─ mostly not solved here; simulated lightly
```

## 2. Kết luận ngắn nhất trước khi đi vào chi tiết

Python port hiện không cố giải bài toán:

- chạy agent production hoàn chỉnh

Nó đang giải 5 bài toán lớn hơn, thực tế hơn cho giai đoạn port:

1. giữ lại tri thức bề mặt của hệ thống gốc
2. giúp người mới hiểu dự án nhanh
3. mô phỏng một số luồng runtime đủ để học kiến trúc
4. lưu session state ở mức tối giản để demo/debug
5. đo mức parity giữa Python workspace và archive tham chiếu

## 3. Bài toán số 1: Làm sao giữ được bề mặt của hệ thống gốc mà chưa cần port hết runtime?

### 3.1. Vấn đề thực tế

Hệ thống gốc lớn.
Nếu đợi port xong toàn bộ logic rồi mới bắt đầu học hoặc audit, team sẽ gặp 3 rủi ro:

- mất dấu command/tool/subsystem quan trọng
- người mới không nhìn thấy bản đồ hệ thống
- không có cách đo tiến độ port một cách rẻ

### 3.2. Python port giải bằng cách nào?

Nó chọn chiến lược:

- mirror surface trước
- implementation sâu tính sau

Cụ thể, nó dùng:

- `reference_data/commands_snapshot.json`
- `reference_data/tools_snapshot.json`
- `reference_data/archive_surface_snapshot.json`
- `reference_data/subsystems/*.json`

Sau đó dùng các module Python để đọc snapshot và dựng inventory:

- `commands.py`
- `tools.py`
- `port_manifest.py`
- `parity_audit.py`

### 3.3. Luồng giải quyết

Luồng đơn giản nhất là:

1. archive hoặc dữ liệu tham chiếu được snapshot hoá
2. Python đọc snapshot
3. Python dựng `PortingModule` và metadata object
4. CLI render ra report, index, lookup, graph

### 3.4. Dùng gì để giải?

- JSON snapshot
- dataclass (`PortingModule`, `PortingBacklog`, ...)
- `lru_cache(maxsize=1)` để tránh load lặp
- CLI `argparse` để expose inventory

### 3.5. Giá trị nhận được

- giữ được vocabulary của dự án
- giữ được command/tool surface
- giữ được tên subsystem lớn
- có nền để tiếp tục port sau này

## 4. Bài toán số 2: Làm sao cho fresher hiểu dự án nhanh mà không cần đọc toàn bộ code gốc?

### 4.1. Vấn đề thực tế

Codebase lớn thường làm người mới bị ngợp vì:

- nhiều folder
- nhiều tên command/tool
- khó biết file nào là xương sống
- khó biết đâu là runtime thật, đâu là stub

### 4.2. Python port giải bằng cách nào?

Python port dựng một lớp CLI + report để “kể lại” dự án:

- `summary`
- `manifest`
- `setup-report`
- `command-graph`
- `tool-pool`
- `bootstrap-graph`
- `subsystems`
- `bootstrap`

Điểm rất hay là:

- cùng một source dữ liệu snapshot
- nhưng có nhiều góc nhìn khác nhau cho người đọc

### 4.3. Luồng giải quyết

1. người đọc chạy CLI
2. CLI gọi module tương ứng
3. module đọc inventory hoặc state mô phỏng
4. report markdown/text được in ra
5. người đọc có cái nhìn tổng quan mà không phải lội toàn bộ code gốc

### 4.4. Dùng gì để giải?

- `main.py`
- `argparse`
- `render_summary()`
- `to_markdown()`
- `RuntimeSession.as_markdown()`

### 4.5. Tác dụng thực tế

- onboarding nhanh
- review nhanh
- audit nhanh
- trình bày kiến trúc dễ hơn

## 5. Bài toán số 3: Làm sao mô phỏng được luồng runtime để học kiến trúc mà không cần LLM/runtime thật?

### 5.1. Vấn đề thực tế

Nếu chỉ có snapshot tĩnh, người đọc biết “có những gì” nhưng không biết:

- prompt đi vào đâu
- route thế nào
- command/tool được chọn thế nào
- session thay đổi ra sao

### 5.2. Python port giải bằng cách nào?

Nó tạo một runtime mô phỏng rất nhẹ:

- `runtime.py`
- `query_engine.py`
- `execution_registry.py`

Ý tưởng:

- route prompt theo lexical score
- chọn command/tool mirror phù hợp
- sinh execution message kiểu shim
- tạo turn result
- stream event mô phỏng

### 5.3. Luồng giải quyết

Luồng đầy đủ:

1. prompt đi vào `PortRuntime.route_prompt()`
2. token được tách và lower-case
3. từng command/tool được chấm điểm dựa trên:
   - `name`
   - `source_hint`
   - `responsibility`
4. match tốt nhất được chọn
5. `ExecutionRegistry` map match sang execution shim
6. `QueryEnginePort.submit_message()` mutate state turn
7. output text hoặc structured output được tạo ra

### 5.4. Dùng gì để giải?

- `runtime.py`
- `query_engine.py`
- `execution_registry.py`
- `commands.py`
- `tools.py`
- dataclass `TurnResult`

### 5.5. Vì sao cách giải này hợp lý?

Vì mục tiêu hiện tại là:

- hiểu luồng
- demo luồng
- test luồng

chứ chưa phải:

- chạy nghiệp vụ agent production

## 6. Bài toán số 4: Làm sao giữ được session state tối thiểu để debug/demo?

### 6.1. Vấn đề thực tế

Nếu mỗi lần chạy chỉ in output rồi mất hết state, người đọc sẽ khó hiểu:

- turn history nằm ở đâu
- usage cộng dồn thế nào
- session có thể load lại không

### 6.2. Python port giải bằng cách nào?

Nó dùng 3 lớp:

- `mutable_messages` trong `QueryEnginePort`
- `TranscriptStore`
- `SessionStore`

Mỗi lớp giữ một vai trò khác nhau:

- `mutable_messages`: prompt history sống trong engine
- `TranscriptStore`: buffer transcript trong memory
- `SessionStore`: lưu JSON tối giản ra đĩa

### 6.3. Luồng giải quyết

1. turn được submit
2. prompt được append vào state
3. transcript buffer nhận entry mới
4. usage được cập nhật
5. khi persist, session được ghi vào `.port_sessions/`

### 6.4. Dùng gì để giải?

- `query_engine.py`
- `transcript.py`
- `session_store.py`
- dataclass `StoredSession`
- JSON file trên filesystem

### 6.5. Cái giá phải trả

Persistence hiện khá tối giản:

- chỉ lưu prompt history
- chỉ lưu input/output token totals
- chưa lưu full turn replay

Nhưng với mục tiêu demo/onboarding, nó vẫn đủ hữu ích.

## 7. Bài toán số 5: Làm sao đo được mức độ parity của Python port với archive tham chiếu?

### 7.1. Vấn đề thực tế

Khi port dần dần, team cần biết:

- file root nào đã có bản Python
- subsystem nào đã có placeholder
- command/tool surface đã mirror tới đâu
- implementation depth còn cách xa bao nhiêu

### 7.2. Python port giải bằng cách nào?

Nó tạo `parity_audit.py` và một bộ mapping rõ ràng:

- root file mappings
- directory mappings
- archive surface counts

Sau đó tính:

- `root_file_coverage`
- `directory_coverage`
- `total_file_ratio`
- `command_entry_ratio`
- `tool_entry_ratio`

### 7.3. Luồng giải quyết

1. đọc snapshot reference
2. quét workspace Python hiện tại
3. so các target root file
4. so các target directory
5. so số lượng command/tool/file
6. render báo cáo parity

### 7.4. Dùng gì để giải?

- `parity_audit.py`
- `Path`
- JSON reference
- markdown report

### 7.5. Tác dụng thực tế

- có thước đo coverage
- có cơ sở để review tiến độ port
- có ngôn ngữ chung giữa người audit và người implement

## 8. Bài toán số 6: Làm sao giữ được tên và quy mô của các subsystem lớn dù chưa port logic thật?

### 8.1. Vấn đề thực tế

Một codebase lớn thường có các subsystem rất to như:

- `utils`
- `components`
- `services`
- `hooks`

Nếu chưa port logic mà xoá mất dấu subsystem, người đọc sẽ mất luôn bản đồ kiến trúc.

### 8.2. Python port giải bằng cách nào?

Nó tạo placeholder package:

- `assistant`
- `bridge`
- `services`
- `skills`
- `utils`
- ...

Mỗi package:

1. đọc metadata JSON
2. expose hằng số mô tả subsystem

### 8.3. Luồng giải quyết

1. import package
2. package đọc `reference_data/subsystems/<name>.json`
3. package expose:
   - `ARCHIVE_NAME`
   - `MODULE_COUNT`
   - `SAMPLE_FILES`
   - `PORTING_NOTE`

### 8.4. Dùng gì để giải?

- `__init__.py` placeholder
- subsystem snapshot JSON
- importable metadata constants

### 8.5. Giá trị

- giữ được surface parity
- test có thể import subsystem
- fresher biết subsystem nào lớn, subsystem nào nhỏ

## 9. Bài toán số 7: Làm sao mô phỏng policy và mode vận hành mà không cần hạ tầng thật?

### 9.1. Vấn đề thực tế

Runtime thật thường có:

- permission policy
- tool gating
- nhiều mode như remote/ssh/teleport/direct-connect

Nếu Python port bỏ hết những khái niệm này, kiến trúc sẽ bị cụt.

### 9.2. Python port giải bằng cách nào?

Nó giữ:

- `ToolPermissionContext`
- filter tool theo deny name/prefix
- mode report cho remote/ssh/teleport/direct-connect/deep-link

### 9.3. Luồng giải quyết

1. user chọn mode hoặc deny rule qua CLI
2. tool pool được filter
3. mode branch trả report tương ứng
4. người đọc vẫn thấy được shape của kiến trúc vận hành

### 9.4. Dùng gì để giải?

- `permissions.py`
- `tool_pool.py`
- `remote_runtime.py`
- `direct_modes.py`

### 9.5. Điểm quan trọng

Đây là:

- policy mô phỏng
- mode mô phỏng

chứ chưa phải:

- security layer production
- transport/runtime production

## 10. Tóm tắt toàn bộ dưới dạng bảng

| Bài toán | Python port giải bằng gì | Luồng chính | Kỹ thuật/công cụ |
|---|---|---|---|
| Giữ bề mặt hệ thống gốc | snapshot + inventory loader | snapshot -> dataclass -> report | JSON, dataclass, `lru_cache` |
| Onboarding nhanh | CLI report | user -> CLI -> report | `argparse`, markdown/text render |
| Mô phỏng runtime | routing + query engine + registry | prompt -> route -> shim -> turn result | lexical scoring, dataclass |
| Lưu state tối thiểu | transcript + session store | submit -> append -> persist | in-memory buffer, JSON file |
| Đo parity | parity audit | scan workspace -> compare -> report | `Path`, JSON, markdown |
| Giữ bản đồ subsystem | placeholder package | import -> load subsystem metadata | `__init__.py`, JSON metadata |
| Giữ policy/mode shape | permission filter + mode stubs | CLI arg -> filtered tool pool / mode report | policy object, stub runtime |

## 11. Những kỹ thuật chính mà Python port đang dùng

Nếu bỏ qua tên file cụ thể, các kỹ thuật chủ đạo là:

- snapshot-driven design
- dataclass-centric modeling
- CLI-first observability
- report-first onboarding
- lightweight runtime simulation
- minimal JSON persistence
- placeholder package strategy
- parity audit bằng mapping rõ ràng

## 12. Những gì Python port cố tình chưa giải

Đây là phần rất quan trọng.

Python port hiện chưa cố giải các bài toán sau:

- chạy model thật
- thực thi tool thật ở mức production
- remote runtime thật
- plugin runtime thật
- MCP runtime thật
- persistence conversation đầy đủ
- bảo mật/chính sách production-grade

Lý do không phải vì code yếu, mà vì chiến lược hiện tại là:

- giữ kiến trúc trước
- giữ bề mặt trước
- giữ khả năng học dự án trước

## 13. Cách đọc file này như một senior engineer

Khi đánh giá Python port, đừng hỏi ngay:

- “sao chưa làm runtime thật?”

Hãy hỏi đúng hơn:

- “ở giai đoạn port này, bài toán nào cần giải trước để team học được hệ thống?”

Theo góc nhìn đó, Python port đang làm khá đúng:

- khóa tri thức bề mặt
- tạo ngôn ngữ chung cho team
- cho phép audit và onboarding sớm
- tạo nền để port sâu hơn về sau

## 14. Kết luận

Nếu phải tóm tắt bằng một câu:

> Python port đang giải bài toán bảo tồn tri thức kiến trúc, mô phỏng luồng cốt lõi, và đo parity một cách rẻ, rõ, dễ học, trước khi tiến tới runtime đầy đủ.
