# Config, Prompt, Permission Và Sandbox

## 1. Vì sao cụm này quan trọng

Nhiều người mới đọc code agent chỉ nhìn vào model call và tool execution.
Điều đó là thiếu.

Trong hệ thống này, chất lượng hành vi của agent phụ thuộc rất mạnh vào 4 lớp nền:

- config
- prompt
- permission
- sandbox

Nếu 4 lớp này không hiểu rõ, bạn sẽ sửa feature trong khi không biết agent thực ra đang được dẫn dắt và giới hạn bởi cái gì.

```text
config files
└─ ConfigLoader merge
   ├─ typed RuntimeConfig
   │  ├─ model
   │  ├─ oauth
   │  ├─ plugins
   │  ├─ hooks
   │  ├─ mcp
   │  └─ sandbox
   └─ ProjectContext + instruction files + git state
      └─ SystemPromptBuilder
         └─ Permission gate
            └─ Sandbox capability check
               └─ final runtime behavior before tool execution
```

## 2. Config được nạp từ đâu

`runtime/src/config.rs` dùng `ConfigLoader` để discover config theo thứ tự:

1. user legacy: `~/.claw.json`
2. user settings: `~/.claw/settings.json`
3. project legacy: `<cwd>/.claw.json`
4. project settings: `<cwd>/.claw/settings.json`
5. local settings: `<cwd>/.claw/settings.local.json`

Ý nghĩa:

- user config cho global default
- project config cho repo chung
- local settings cho override riêng máy hoặc riêng workspace

## 3. Merge strategy

Loader:

- đọc từng file nếu tồn tại
- deep merge object
- giữ danh sách file đã load
- parse typed feature config từ merged object

Những phần được parse typed gồm:

- hooks
- plugins
- mcp
- oauth
- model
- permission mode
- sandbox

Đây là một bước trưởng thành quan trọng của codebase:

- config raw vẫn còn
- nhưng phần runtime cần dùng được bóc thành kiểu rõ ràng

## 4. Permission mode được resolve thế nào

`ResolvedPermissionMode` ở lớp config có các mode:

- `ReadOnly`
- `WorkspaceWrite`
- `DangerFullAccess`

Code còn support alias mềm:

- `default`, `plan`, `read-only` -> `ReadOnly`
- `acceptEdits`, `auto`, `workspace-write` -> `WorkspaceWrite`
- `dontAsk`, `danger-full-access` -> `DangerFullAccess`

Điểm này quan trọng vì CLI UX và config UX chấp nhận nhiều cách gọi khác nhau.

## 5. Prompt được dựng từ đâu

`runtime/src/prompt.rs` giải bài toán tạo system prompt theo ngữ cảnh thực tế.

Nó không hard-code một string duy nhất.

Prompt builder có thể ghép từ:

- intro chung
- output style
- system section
- doing tasks section
- actions section
- environment section
- project context
- instruction files
- runtime config section
- append sections bổ sung
- LSP context

Có một marker rõ:

- `SYSTEM_PROMPT_DYNAMIC_BOUNDARY`

Marker này giúp phân tách phần prompt tĩnh và phần prompt động.

## 6. Project context được phát hiện như thế nào

`ProjectContext::discover_with_git()` sẽ:

- đi ngược cây thư mục từ `cwd`
- tìm các file hướng dẫn như:
- `CLAW.md`
- `CLAW.local.md`
- `.claw/CLAW.md`
- `.claw/instructions.md`
- đọc `git status`
- đọc `git diff`

Điểm hay:

- prompt có thể phản ánh luật dự án
- prompt có thể biết repo đang bẩn hay sạch
- prompt có thể biết thay đổi hiện tại trong workspace

## 7. Dedupe và budget cho instruction files

Code không nhét vô hạn instruction file vào prompt.

Nó có:

- dedupe theo content hash
- giới hạn ký tự cho từng file
- giới hạn tổng ký tự

Đây là best practice rõ ràng:

- giữ prompt đủ giàu
- nhưng không để context nổ kích thước

## 8. Permission ở runtime khác gì config permission

Config permission nói “chế độ mặc định hiện tại là gì”.

`runtime/src/permissions.rs` mới là nơi quyết định một tool call có được phép chạy hay không.

Các mode ở runtime:

- `ReadOnly`
- `WorkspaceWrite`
- `DangerFullAccess`
- `Prompt`
- `Allow`

Logic `authorize()` cơ bản:

- nếu mode hiện tại đủ quyền thì cho qua
- nếu cần escalated quyền, có thể yêu cầu prompt/escalation
- nếu không thì deny với lý do rõ

Điểm này tốt hơn rất nhiều so với kiểu deny-list đơn giản.

## 9. Permission policy map tool theo requirement

`PermissionPolicy` giữ mapping:

- tool name -> required permission

Nhờ đó:

- tool spec và security gate nối được với nhau
- agent loop có thể chặn chính xác tại lúc tool call phát sinh

## 10. Sandbox giải bài toán gì

`runtime/src/sandbox.rs` giải bài toán:

- runtime muốn chạy command trong môi trường hạn chế hơn
- nhưng năng lực sandbox thực tế phụ thuộc OS và môi trường chứa

Nó mô hình hóa:

- filesystem isolation
- namespace restriction
- network isolation
- allowed mounts
- container detection

## 11. Các mode filesystem isolation

Code hiện có:

- `Off`
- `WorkspaceOnly`
- `AllowList`

`AllowList` cho phép chỉ định mount được phép truy cập.

Đây là một abstraction tốt để sau này gắn với backend sandbox thật mạnh hơn.

## 12. Sandbox status được resolve ra sao

Code đọc:

- env
- marker file container
- `/proc/1/cgroup`
- sự tồn tại của `unshare`

Sau đó build `SandboxStatus` gồm:

- enabled hay không
- supported hay không
- active hay không
- namespace active hay không
- network active hay không
- filesystem mode
- fallback reason nếu không đáp ứng được

Điểm hay:

- không giả vờ rằng sandbox luôn chạy
- luôn tách “requested” với “actually active”

## 13. Linux sandbox command

Khi đủ điều kiện, code có thể build command dựa trên `unshare` với:

- user namespace
- mount
- ipc
- pid
- uts
- fork
- network nếu bật

Nó còn set env như:

- `HOME`
- `TMPDIR`
- `CLAW_SANDBOX_FILESYSTEM_MODE`
- `CLAW_SANDBOX_ALLOWED_MOUNTS`

## 14. Góc nhìn senior

### Điểm tốt

- config hierarchy rõ
- prompt builder có chiều sâu
- permission model hợp lý
- sandbox không nói quá khả năng

### Điểm cần chú ý

- config nhiều tầng rất dễ gây “override surprise”
- nếu prompt builder thêm quá nhiều section, latency và token cost sẽ tăng
- sandbox hiện thiên về Linux capability, nên cross-platform behavior cần tài liệu hóa cẩn thận

## 15. Kết luận

Muốn hiểu agent hành xử vì sao như hiện tại, đừng chỉ nhìn tool và model.
Hãy nhìn:

- config nào được load
- prompt nào được dựng
- permission mode nào đang active
- sandbox nào thực sự khả dụng

Đó mới là 4 lớp nền quyết định tính cách vận hành của runtime.
