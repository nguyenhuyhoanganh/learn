# Reference Data, Placeholder Subsystem Và Parity Audit

## 1. Triết lý snapshot-first của Python port

Một trong những quyết định kiến trúc quan trọng nhất của phần Python là:

- không cố port mọi logic trước
- port bề mặt và tri thức kiến trúc trước

Muốn làm vậy, dự án dựa rất nhiều vào `reference_data`.

Các nhóm file cốt lõi:

- `commands_snapshot.json`
- `tools_snapshot.json`
- `archive_surface_snapshot.json`
- `subsystems/*.json`

```text
frozen reference data
   |
   +--> command snapshot
   +--> tool snapshot
   +--> archive surface snapshot
   +--> subsystem metadata
   |
   v
parity_audit.py
   |
   v
coverage, inventory ratio, subsystem visibility
```

## 2. `archive_surface_snapshot.json` nói gì?

Snapshot này chứa các số liệu nền:

- tổng số file TS-like
- tổng số command entry
- tổng số tool entry

Trong workspace hiện tại:

- archive tham chiếu từng có `1902` file TS-like
- command entry count là `207`
- tool entry count là `184`

Các con số này cho phép Python port trả lời nhanh:

- quy mô archive gốc lớn đến đâu
- command/tool surface đã mirror đủ chưa
- Python implementation depth đang lệch bao nhiêu so với bề mặt archive

## 3. Placeholder subsystem package là gì?

Nhiều package trong `src/` hiện không có nhiều logic thật.
Thay vào đó, chúng dùng `__init__.py` để:

- đọc metadata từ `reference_data/subsystems/*.json`
- expose các hằng số mô tả subsystem

Thông thường sẽ có:

- `ARCHIVE_NAME`
- `MODULE_COUNT`
- `SAMPLE_FILES`
- `PORTING_NOTE`

### 3.1. Vì sao cách này đáng giá?

Vì nó giúp tránh 2 kiểu mất dấu:

- mất tên subsystem
- mất cảm giác về quy mô subsystem

Người mới nhìn vào `src/utils/__init__.py` sẽ biết:

- subsystem `utils` tồn tại
- nó lớn
- nó đến từ archive gốc

## 4. `parity_audit.py` đang đo gì?

Đây là file rất dễ bị đọc lướt nhưng thực ra rất quan trọng.
Nó đo 5 thứ:

- `root_file_coverage`
- `directory_coverage`
- `total_file_ratio`
- `command_entry_ratio`
- `tool_entry_ratio`

### 4.1. Root file coverage

Đo xem các file root-level quan trọng từ archive đã có target Python chưa.

Ví dụ:

- `QueryEngine.ts` -> `QueryEngine.py`
- `setup.ts` -> `setup.py`
- `tasks.ts` -> `tasks.py`

### 4.2. Directory coverage

Đo xem các subsystem top-level đã có tên tương ứng trong Python workspace chưa.

Ví dụ:

- `assistant`
- `bridge`
- `services`
- `skills`
- `remote`

### 4.3. Total file ratio

Đo số file Python hiện có so với số file TS-like của snapshot archive.

Đây là chỉ số rất dễ hiểu nhầm.
Nó không nói:

- logic đã tương đương

Nó chỉ nói:

- độ sâu implementation toàn repo còn cách xa archive gốc

### 4.4. Command/tool entry ratio

Đây là nơi Python port có parity tốt nhất.

Vì command/tool được mirror bằng snapshot, tỉ lệ ở lớp surface gần như khớp rất cao.

## 5. Vì sao parity audit hiện báo archive unavailable?

Trên máy hiện tại, local archive không có mặt ở path kỳ vọng.
Nên `run_parity_audit()` báo:

- local archive unavailable

Điều này không làm file vô dụng, vì:

- mapping logic vẫn còn nguyên
- snapshot reference vẫn còn
- định nghĩa parity vẫn được bảo tồn

Nói cách khác:

- module vừa là checker
- vừa là tài liệu sống về “parity nên được hiểu như thế nào”

## 6. Các subsystem lớn nhất nói gì về kiến trúc gốc?

Từ snapshot subsystem:

- `utils`: `564`
- `components`: `389`
- `services`: `130`
- `hooks`: `104`
- `bridge`: `31`
- `constants`: `21`
- `skills`: `20`
- `cli`: `19`

Diễn giải đúng:

- hệ thống gốc có utility layer rất lớn
- component/service/hook cũng là trụ cột
- Python port hiện mới chủ yếu dựng được bản đồ các vùng đó

## 7. Best practice khi làm việc với snapshot và parity

- luôn nhớ snapshot có thể stale nếu archive đổi mà không refresh
- khi thêm mirror module mới, cân nhắc parity mapping cùng lúc
- khi update snapshot count, chạy lại CLI smoke test
- nếu có thể, lưu thêm timestamp hoặc commit id cho snapshot

## 8. Nếu phát triển tiếp phần này thì nên ưu tiên gì?

- tạo script regenerate snapshot rõ ràng
- version hóa snapshot schema
- thêm validation khi JSON bị lỗi
- ghi thêm metadata nguồn sinh snapshot
- tách parity audit report cho command/tool và subsystem rõ hơn

## 9. Chốt lại

Reference data và parity audit là “bộ nhớ kiến trúc” của Python port.
Chúng cho phép dự án giữ được:

- bề mặt hệ thống gốc
- vocabulary của subsystem
- tín hiệu coverage để đo tiến độ port

Đó là lý do phần này quan trọng dù bản thân nó không chạy runtime thật.
