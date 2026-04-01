# Playbook Thực Hành Cho Fresher

## 1. Mục tiêu của playbook

File này không giải thích kiến trúc mới từ đầu.
Nó hướng dẫn cách **tự tay đi qua code Python** để hiểu dự án nhanh nhất.

Nếu là người mới, hãy đọc theo thứ tự:

1. `01-tong-quan-python-port.md`
2. `02-kien-truc-thanh-phan.md`
3. `03-cli-bootstrap-routing.md`
4. file playbook này

## 2. Bản đồ học nhanh trong 60-90 phút

### Bước 1. Nhìn toàn cảnh

Chạy:

```bash
python -m src.main summary
python -m src.main setup-report
```

Mục tiêu:

- biết workspace có bao nhiêu file Python
- biết command/tool surface lớn cỡ nào
- biết startup flow Python đang mirror những phase nào

### Bước 2. Nhìn inventory bề mặt

Chạy:

```bash
python -m src.main commands --limit 20
python -m src.main tools --limit 20
python -m src.main command-graph
python -m src.main tool-pool
```

Mục tiêu:

- hiểu command và tool ở đây là snapshot mirror
- thấy được command builtins/plugin-like/skill-like
- thấy tool pool được filter như thế nào

### Bước 3. Xem routing

Chạy:

```bash
python -m src.main route "review MCP tool" --limit 5
python -m src.main show-command review
python -m src.main show-tool MCPTool
```

Mục tiêu:

- thấy prompt được match kiểu heuristic
- thấy `source_hint` quan trọng thế nào
- hiểu vì sao match có thể đúng một phần và nhiễu một phần

### Bước 4. Xem bootstrap session đầy đủ

Chạy:

```bash
python -m src.main bootstrap "review MCP tool" --limit 5
```

Mục tiêu:

- nhìn một báo cáo end-to-end
- thấy context, setup, routing, execution shim, stream events, session history nằm cùng một nơi

### Bước 5. Xem persistence

Chạy:

```bash
python -m src.main flush-transcript "review MCP tool"
python -m src.main load-session <session_id>
```

Sau đó mở thư mục:

- `.port_sessions/`

Mục tiêu:

- thấy session file thật đang lưu gì
- phân biệt transcript buffer với persisted session

## 3. Nên đọc source file theo thứ tự nào?

Thứ tự hiệu quả nhất cho người mới:

1. `src/main.py`
2. `src/runtime.py`
3. `src/query_engine.py`
4. `src/session_store.py`
5. `src/transcript.py`
6. `src/commands.py`
7. `src/tools.py`
8. `src/execution_registry.py`
9. `src/parity_audit.py`
10. `src/setup.py`
11. `src/bootstrap_graph.py`
12. `src/reference_data/*`

Lý do:

- đi từ entrypoint đến orchestration
- rồi tới stateful core
- rồi tới inventory source
- cuối cùng mới đọc reference data

Đây là thứ tự dễ hiểu hơn nhiều so với đọc ngẫu nhiên theo tên file.

## 4. Cách đặt câu hỏi đúng khi đọc code

Khi đọc từng file, hãy tự hỏi:

- file này đang thực thi logic thật hay chỉ mirror metadata?
- state được mutate ở đâu?
- dữ liệu đầu vào đến từ code hay từ snapshot?
- object nào chỉ dùng để report?
- object nào được persist?
- chỗ nào là placeholder để giữ parity?

Nếu hỏi đúng 6 câu này, bạn sẽ ít bị lạc hơn rất nhiều.

## 5. Mini bài tập để hiểu dự án chắc hơn

### Bài tập 1. Tự giải thích route prompt

Làm:

- đọc `PortRuntime.route_prompt()`
- tự viết lại bằng lời cách score được tính

Nếu bạn giải thích được:

- vì sao token được lower-case
- vì sao `/` và `-` bị thay thành space
- vì sao kết quả có thể false-positive

thì bạn đã hiểu phần routing cơ bản.

### Bài tập 2. Tự mô tả vòng đời session

Làm:

- đọc `submit_message()`
- đọc `stream_submit_message()`
- đọc `persist_session()`

Sau đó tự trả lời:

- prompt được lưu ở đâu
- transcript được lưu ở đâu
- file JSON được tạo ở đâu
- bug double-submit phát sinh vì sao

### Bài tập 3. Tự đọc snapshot subsystem

Làm:

- mở `src/reference_data/subsystems/utils.json`
- mở `src/utils/__init__.py`

Mục tiêu:

- hiểu placeholder package pattern
- hiểu vì sao package tồn tại dù chưa có logic runtime thật

## 6. Mapping nhanh: câu hỏi nào nên mở file nào?

| Câu hỏi | File nên mở đầu tiên |
|---|---|
| CLI này có những lệnh gì? | `src/main.py` |
| Prompt được route thế nào? | `src/runtime.py` |
| Session lưu ở đâu? | `src/query_engine.py`, `src/session_store.py` |
| Transcript là gì? | `src/transcript.py` |
| Tool nào bị chặn? | `src/permissions.py`, `src/tools.py` |
| Command/tool được lấy từ đâu? | `src/commands.py`, `src/tools.py` |
| Dự án mirror archive tới mức nào? | `src/parity_audit.py` |
| Setup/bootstrap đang mô phỏng gì? | `src/setup.py`, `src/bootstrap_graph.py` |
| Các package `assistant`, `services`, `utils` có thật sự port xong chưa? | `src/<package>/__init__.py`, `src/reference_data/subsystems/*.json` |

## 7. Những hiểu lầm fresher rất dễ mắc

### Hiểu lầm 1. “Có command/tool nghĩa là đã chạy thật”

Sai.

Đa số command/tool ở Python chỉ là mirror entry + execution shim.

### Hiểu lầm 2. “Có package `services` nghĩa là service layer đã được port”

Sai trong phần lớn trường hợp.

Nhiều package mới chỉ expose metadata từ snapshot subsystem.

### Hiểu lầm 3. “Flush transcript nghĩa là đã ghi transcript đầy đủ”

Sai.

Hiện `flush()` chỉ đánh dấu trạng thái, còn file session chỉ lưu prompt history tối giản.

### Hiểu lầm 4. “Parity cao nghĩa là runtime gần hoàn chỉnh”

Không đúng.

Parity command/tool surface có thể cao, nhưng parity implementation/runtime behavior vẫn thấp.

## 8. Cách viết note cá nhân khi onboarding

Nên tự tách note thành 4 cột:

- Tên module
- Vai trò thật
- Dữ liệu nó đọc
- Dữ liệu nó trả ra

Ví dụ:

| Module | Vai trò thật | Đọc từ đâu | Trả ra gì |
|---|---|---|---|
| `commands.py` | mirror inventory command | `commands_snapshot.json` | `PortingModule`, index, shim execution |
| `runtime.py` | orchestration mô phỏng | commands/tools/query engine | `RoutedMatch`, `RuntimeSession` |
| `query_engine.py` | stateful turn/session core | manifest, store, transcript | `TurnResult`, session file |

Viết note kiểu này giúp bạn giữ được ranh giới trách nhiệm giữa các module.

## 9. Lộ trình hiểu sâu hơn sau khi đã quen

Sau khi nắm chắc Python layer, bạn nên đào sâu theo thứ tự:

1. cách snapshot được sinh ra từ archive
2. chỗ nào là placeholder cần port tiếp
3. sự khác nhau giữa Python mirror layer và runtime thực ở ngôn ngữ còn lại
4. cách chuyển từ inventory-based route sang runtime execution thật

## 10. Kết luận

Nếu dùng đúng playbook, một fresher có thể hiểu Python port rất nhanh:

- biết đâu là code thật
- đâu là metadata
- đâu là stateful core
- đâu là limitation

Đó là nền rất tốt trước khi đụng tới phần runtime sâu hơn của toàn dự án.
