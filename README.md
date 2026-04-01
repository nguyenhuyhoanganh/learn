# Wiki Dự Án Claw-Code

Bộ tài liệu này đang được viết theo từng pha.

Pha hiện tại tập trung vào phần Python trong `claw-code/src/`.
Đây là lớp `porting workspace` dùng để mirror bề mặt dự án gốc, kiểm kê command/tool, mô phỏng một số flow bootstrap/runtime, chạy parity audit, và tạo báo cáo học kiến trúc.
Nó không phải runtime agent production đầy đủ như phần Rust.

## Mục lục hiện có

- `python/01-tong-quan-python-port.md`
- `python/02-kien-truc-thanh-phan.md`
- `python/03-cli-bootstrap-routing.md`
- `python/04-query-engine-session-persistence.md`
- `python/05-command-tool-parity-reference-data.md`
- `python/06-tests-khoang-trong-best-practice.md`
- `python/07-playbook-thuc-hanh-cho-fresher.md`

## Cách đọc đề xuất cho fresher

1. Đọc `01-tong-quan-python-port.md` để hiểu Python đang giải quyết bài toán gì.
2. Đọc `02-kien-truc-thanh-phan.md` để nắm bản đồ module.
3. Đọc `03-cli-bootstrap-routing.md` để thấy flow chạy từ CLI.
4. Đọc `04-query-engine-session-persistence.md` để hiểu state, session, transcript.
5. Đọc `05-command-tool-parity-reference-data.md` để hiểu snapshot mirror và placeholder subsystem.
6. Đọc `06-tests-khoang-trong-best-practice.md` để biết giới hạn, issue và cách làm việc an toàn.
7. Đọc `07-playbook-thuc-hanh-cho-fresher.md` để tự thực hành và tự kiểm tra mức hiểu.

## Ghi chú quan trọng

- Tài liệu này phản ánh code đang có trong workspace tại thời điểm đọc.
- Phần Rust được tạm dừng theo yêu cầu để ưu tiên tài liệu Python trước.
