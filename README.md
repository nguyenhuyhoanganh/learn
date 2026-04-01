# Wiki Dự Án Claw-Code

Bộ tài liệu này được tách thành 2 nhánh lớn:

- `python/`: tài liệu cho Python port, thiên về mirror surface, mô phỏng runtime, parity audit và onboarding kiến trúc
- `rust/`: tài liệu cho Rust workspace, thiên về runtime thực thi, tool/plugin/provider/session/prompt/integration thực tế

## Cách đọc nhanh

Nếu bạn là fresher mới vào dự án:

1. đọc `python/00-lo-trinh-doc-python.md` để hiểu vì sao Python tồn tại
2. đọc `rust/00-lo-trinh-doc-rust.md` để hiểu vì sao Rust mới là runtime quan trọng
3. sau đó chọn một nhánh chính để đào sâu

## Phần Python

### Overview

- `python/00-lo-trinh-doc-python.md`
- `python/01-tong-quan-python-port.md`
- `python/02-kien-truc-thanh-phan.md`
- `python/03-cli-bootstrap-routing.md`
- `python/04-query-engine-session-persistence.md`
- `python/05-command-tool-parity-reference-data.md`
- `python/06-tests-khoang-trong-best-practice.md`
- `python/07-playbook-thuc-hanh-cho-fresher.md`

### Deep Dive

- `python/08-main-parser-va-subcommand.md`
- `python/09-setup-bootstrap-va-mode-branching.md`
- `python/10-routing-va-execution-shim.md`
- `python/11-query-engine-core.md`
- `python/12-transcript-session-store-va-persistence.md`
- `python/13-command-tool-layer-va-permission.md`
- `python/14-reference-data-subsystem-va-parity.md`
- `python/15-cac-van-de-code-giai-quyet-va-cach-giai.md`

### Sơ đồ minh hoạ

- Các sơ đồ Python hiện được nhúng trực tiếp trong từng file markdown dưới dạng ` ```text ` với box-drawing characters như `┌ ┐ └ ┘ │ ─ ├`.
- Không còn phụ thuộc ảnh để đọc luồng kiến trúc.

## Phần Rust

### Overview

- `rust/00-lo-trinh-doc-rust.md`
- `rust/01-tong-quan-rust-workspace.md`
- `rust/02-ban-do-workspace-va-crates.md`
- `rust/03-claw-cli-bootstrap-va-repl.md`
- `rust/04-runtime-conversation-session-va-compaction.md`
- `rust/05-config-prompt-permission-sandbox.md`
- `rust/06-api-provider-oauth-streaming.md`
- `rust/07-tools-commands-plugins.md`
- `rust/08-mcp-server-lsp-va-service-surface.md`
- `rust/09-tests-rui-ro-best-practice.md`
- `rust/10-cac-van-de-rust-giai-quyet-va-cach-giai.md`

### Sơ đồ minh hoạ

- Các sơ đồ Rust hiện được nhúng trực tiếp trong từng file markdown dưới dạng ` ```text ` với box-drawing characters như `┌ ┐ └ ┘ │ ─ ├`.
- Không còn phụ thuộc ảnh để đọc luồng kiến trúc.

## Gợi ý lộ trình cho fresher

### Nếu muốn hiểu toàn cảnh dự án

1. `python/01-tong-quan-python-port.md`
2. `rust/01-tong-quan-rust-workspace.md`
3. `python/02-kien-truc-thanh-phan.md`
4. `rust/02-ban-do-workspace-va-crates.md`
5. `rust/10-cac-van-de-rust-giai-quyet-va-cach-giai.md`

### Nếu muốn hiểu runtime chạy thật

1. `rust/03-claw-cli-bootstrap-va-repl.md`
2. `rust/04-runtime-conversation-session-va-compaction.md`
3. `rust/05-config-prompt-permission-sandbox.md`
4. `rust/06-api-provider-oauth-streaming.md`
5. `rust/07-tools-commands-plugins.md`
6. `rust/08-mcp-server-lsp-va-service-surface.md`

### Nếu muốn hiểu Python đang đóng vai trò gì

1. `python/03-cli-bootstrap-routing.md`
2. `python/04-query-engine-session-persistence.md`
3. `python/05-command-tool-parity-reference-data.md`
4. `python/15-cac-van-de-code-giai-quyet-va-cach-giai.md`

## Ghi chú quan trọng

- Tài liệu phản ánh code đang có trong workspace tại thời điểm đọc.
- Python và Rust không ở cùng mức độ hoàn thiện.
- Python phù hợp để hiểu bề mặt và intent kiến trúc.
- Rust phù hợp để hiểu runtime agent thực sự đang được xây như thế nào.
- Các sơ đồ Mermaid và ảnh nhúng đã được thay bằng sơ đồ khối trong ` ```text ` để đọc ổn định ngay trong markdown.
- Riêng phần Rust trong vòng tài liệu hiện tại được xác nhận bằng static code reading; môi trường local hiện không có `cargo` trong `PATH`, nên chưa chạy build/test lại trực tiếp từ máy này.
