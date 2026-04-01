# Tổng Quan Python Port

## 1. Phần Python này thực sự là gì?

Trong repo `claw-code`, thư mục `src/` phía Python không phải là một bản runtime agent hoàn chỉnh ngang với hệ thống gốc.
Nó là một lớp **porting workspace** có 4 nhiệm vụ chính:

1. Mirror bề mặt dự án gốc theo kiểu sạch và an toàn.
2. Lưu snapshot command/tool/subsystem để người đọc hoặc script có thể truy vấn.
3. Mô phỏng một số flow bootstrap, routing, session, remote mode, tool pool.
4. Tạo báo cáo, summary, parity audit và dữ liệu học kiến trúc cho người phát triển.

Nói ngắn gọn:

- Python ở đây thiên về `catalog + mirror + audit + simulation`.
- Rust mới là hướng runtime thực chiến.

```text
strongest today
  snapshots + reports + parity + inventory mirror

medium depth
  route_prompt + bootstrap simulation + query engine + light session store

weak / placeholder
  deep provider runtime
  rich tool execution
  production-grade permission model
  full structured conversation runtime
```

## 2. Python giải quyết vấn đề gì?

Nếu chỉ nhìn vào `src/main.py`, có thể tưởng đây là một CLI agent mini.
Thực tế, lớp Python đang giải quyết các vấn đề sau:

### 2.1. Đóng gói tri thức bề mặt của codebase gốc

Các snapshot JSON trong `src/reference_data/` chứa:

- danh sách command mirror
- danh sách tool mirror
- metadata các subsystem lớn từ archive gốc
- số lượng file bề mặt archive

Nhờ đó, Python có thể trả lời các câu hỏi như:

- Dự án gốc có bao nhiêu command?
- Có những tool nào liên quan đến MCP?
- Subsystem `utils`, `services`, `components` lớn đến mức nào?
- Mức parity hiện tại giữa Python workspace và bề mặt archive là bao nhiêu?

### 2.2. Cho phép mô phỏng flow runtime để học kiến trúc

Python không gọi model thật, nhưng nó mô phỏng được:

- route prompt sang command/tool mirror
- dựng bootstrap session report
- ghi transcript
- persist session
- streaming event giả lập
- tính usage rất đơn giản

Mục đích là để người học hiểu luồng hệ thống mà không cần runtime đầy đủ.

### 2.3. Tạo một lớp kiểm kê và audit

Ví dụ:

- `manifest`: kiểm kê file Python hiện có
- `parity-audit`: so bề mặt hiện tại với snapshot archive
- `commands`, `tools`: liệt kê inventory mirror
- `command-graph`, `tool-pool`, `bootstrap-graph`: trình bày cấu trúc logic

## 3. Python hiện đang có quy mô ra sao?

Khi chạy trực tiếp CLI của Python trong workspace hiện tại:

- Tổng số file Python: `66`
- Command entries mirror: `207`
- Tool entries mirror: `184`
- Command graph:
  - builtins: `185`
  - plugin-like commands: `20`
  - skill-like commands: `2`

Parity snapshot cũng cho biết archive tham chiếu từng có:

- `1902` file TS-like
- `207` command entries
- `184` tool entries

Điều này cho thấy Python đang mirror rất mạnh ở lớp metadata/surface, nhưng không mirror đầy đủ ở lớp thực thi.

## 4. Tư duy đúng khi đọc phần Python

Đây là cách hiểu đúng nhất:

- `src/main.py` là cửa vào CLI của lớp mirror.
- `commands.py` và `tools.py` không thực thi command/tool thật; chúng đọc snapshot rồi dựng đối tượng metadata.
- `runtime.py` và `query_engine.py` chủ yếu dựng report, route prompt, mô phỏng turn loop và session.
- Các package như `assistant`, `bridge`, `services`, `skills`, `utils` bên dưới `src/` phần lớn chỉ là placeholder package đọc metadata JSON.

Nói cách khác:

- Python giúp **hiểu hệ thống**.
- Nó chưa phải nơi **chạy hệ thống thật**.

## 5. Những use case rất hợp với lớp Python này

### 5.1. Dành cho fresher

- học vocabulary của dự án
- biết subsystem nào tồn tại
- thấy command/tool surface rộng thế nào
- làm quen với flow bootstrap, routing, session

### 5.2. Dành cho người maintain repo

- giữ parity surface với archive
- kiểm tra snapshot command/tool còn khớp không
- tạo báo cáo nhanh cho onboarding

### 5.3. Dành cho người nghiên cứu kiến trúc agent harness

- quan sát cách một runtime lớn có thể được mirror thành lớp audit/simulation
- đọc cấu trúc command/tool mà không cần mở toàn bộ runtime production

## 6. Những việc Python không làm tốt hoặc chưa làm

- không phải tool executor thật của hệ thống gốc
- không có assistant loop production-grade
- không có network/service layer hoàn chỉnh
- không có plugin runtime thật
- không có MCP runtime thật
- không có session message model đầy đủ như hệ thống agent production

Một số phần rõ ràng là placeholder hoặc stub:

- `prefetch.py`
- `deferred_init.py`
- `remote_runtime.py`
- `direct_modes.py`
- nhiều package `__init__.py` chỉ expose metadata

## 7. Sơ đồ định vị nhanh

```text
CLI surface
  main.py
    |
    +--> mirror layer       -> commands.py / tools.py
    +--> runtime layer      -> runtime.py / query_engine.py
    +--> persistence layer  -> transcript.py / session_store.py
    +--> audit layer        -> manifest / parity / graphs
    +--> reference data     -> snapshots + subsystem metadata
```

Ảnh trên là bản đồ nhanh của toàn bộ Python port:

- `main.py` là cửa vào CLI
- `commands.py` và `tools.py` lấy dữ liệu từ snapshot JSON
- `runtime.py` điều phối luồng mô phỏng
- `query_engine.py` giữ state turn/session
- `transcript.py` và `session_store.py` phụ trách lưu vết
- các package placeholder đọc metadata từ `reference_data/subsystems/*.json`

## 8. Kết luận ngắn

Nếu phải tóm tắt chỉ trong 1 câu:

> Phần Python là một lớp học kiến trúc và kiểm kê parity rất hữu ích, nhưng không nên nhầm nó với runtime thực thi đầy đủ của Claw.
