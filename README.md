# Wiki Dự Án Claw-Code

Bộ tài liệu này đang được viết theo từng pha.

Pha hiện tại tập trung vào phần Python trong `claw-code/src/`.
Đây là lớp `porting workspace` dùng để mirror bề mặt dự án gốc, kiểm kê command/tool, mô phỏng một số flow bootstrap/runtime, chạy parity audit, và tạo báo cáo học kiến trúc.
Nó không phải runtime agent production đầy đủ như phần Rust.

## Mục lục hiện có

### Tầng 1: Overview

- `python/00-lo-trinh-doc-python.md`
- `python/01-tong-quan-python-port.md`
- `python/02-kien-truc-thanh-phan.md`
- `python/03-cli-bootstrap-routing.md`
- `python/04-query-engine-session-persistence.md`
- `python/05-command-tool-parity-reference-data.md`
- `python/06-tests-khoang-trong-best-practice.md`
- `python/07-playbook-thuc-hanh-cho-fresher.md`

### Tầng 2: Deep Dive

- `python/08-main-parser-va-subcommand.md`
- `python/09-setup-bootstrap-va-mode-branching.md`
- `python/10-routing-va-execution-shim.md`
- `python/11-query-engine-core.md`
- `python/12-transcript-session-store-va-persistence.md`
- `python/13-command-tool-layer-va-permission.md`
- `python/14-reference-data-subsystem-va-parity.md`

### Ảnh minh hoạ

- `python/assets/python-module-map.png`
- `python/assets/python-runtime-dataflow.png`
- `python/assets/python-bootstrap-sequence.png`
- `python/assets/python-session-lifecycle.png`
- `python/assets/python-snapshot-parity-map.png`

Script dựng lại ảnh:

- `python/_scripts/render_diagrams.ps1`

## Cách đọc đề xuất cho fresher

1. Đọc `00-lo-trinh-doc-python.md` để chọn đúng nhánh đọc.
2. Đọc `01-tong-quan-python-port.md` để hiểu Python đang giải quyết bài toán gì.
3. Đọc `02-kien-truc-thanh-phan.md` để nắm bản đồ module.
4. Đọc `03-cli-bootstrap-routing.md` để thấy flow chạy từ CLI.
5. Đọc `04-query-engine-session-persistence.md` để hiểu state, session, transcript.
6. Đọc `05-command-tool-parity-reference-data.md` để hiểu snapshot mirror và placeholder subsystem.
7. Đọc `06-tests-khoang-trong-best-practice.md` để biết giới hạn, issue và cách làm việc an toàn.
8. Đọc `07-playbook-thuc-hanh-cho-fresher.md` để tự thực hành và tự kiểm tra mức hiểu.
9. Khi cần đào sâu, đi tiếp các file `08` đến `14` theo đúng chuyên đề.

## Ghi chú quan trọng

- Tài liệu này phản ánh code đang có trong workspace tại thời điểm đọc.
- Phần Rust được tạm dừng theo yêu cầu để ưu tiên tài liệu Python trước.
- Các sơ đồ Mermaid đã được thay bằng ảnh PNG thật để đọc ổn định hơn trong markdown viewer.
