# ADR-001 — Lựa chọn chiến lược công bố file

- **Trạng thái:** Proposed (chưa chấp nhận)
- **Phạm vi:** Project 01 — Linux Data Processing Server
- **Liên kết:** [Kiến thức các phương án](../01-knowledge/concurrency/file-publication-options.md) · [Thiết kế](../02-design/safe-file-publication.md)

## 1. Bối cảnh

OmniCommerce nhận nhiều file CSV từ nhiều producer. Upload có thể kéo dài, producer có thể crash, và nhiều lần gửi có thể trùng tên. Consumer chỉ được xử lý file đã sẵn sàng; không được vô tình overwrite file của lần gửi khác.

Script demo hiện tại dùng một tên temp `orders.csv.part` và tên đích `orders.csv`, nên **chưa an toàn khi nhiều producer chạy đồng thời**.

## 2. Các phương án xem xét

| Lựa chọn | Điểm mạnh | Chi phí / rủi ro |
|---|---|---|
| A — Unique destination | Tách biệt từng lần tiếp nhận, ít shared state | Phải quản lý ID, vẫn cần dedup |
| B — File locking (`flock`) | Điều phối các producer cùng tuân thủ khóa | Advisory; cần thiết kế critical section |
| C — Atomic no-overwrite (`renameat2`) | Ngăn overwrite atomically nếu hỗ trợ | Phụ thuộc syscall/filesystem; cần fallback |

## 3. Quyết định đề xuất cho v1

- Tên file tạm được tạo riêng một cách an toàn.
- Destination name chứa ingestion ID để giảm xung đột.
- Consumer chỉ nhận file đã publish; không đọc `.part`.
- Không sử dụng `if ! -e ...; mv ...` làm cơ chế bảo vệ duy nhất.
- Nếu yêu cầu đặt một tên destination cố định: nghiên cứu `flock` có kiểm tra trong critical section hoặc `RENAME_NOREPLACE` với support tests.
- SHA-256 phục vụ duplicate candidate + audit, không tự xóa.

Đây là **đề xuất**, không khẳng định hệ thống đã triển khai hay đã qua concurrency test.

## 4. Vì sao đề xuất phương án này?

Tên destination riêng giảm mức độ cần phối hợp giữa các producer, dễ hiểu cho người mới học Linux và tạo cơ sở để nghiên cứu dedup/recovery một cách có kiểm soát.

## 5. Trade-offs và hệ quả

- Cần ingestion ID và quản lý vòng đời file `.part`.
- Cần quy tắc xử lý retry và process bị kill.
- Cần cách lưu metadata để audit mọi lần tiếp nhận.
- Atomic rename không đồng nghĩa fsync/durability.
- Rename và cập nhật metadata không tự động thuộc cùng một giao dịch.
- Consumer idempotency cần được thiết kế độc lập.

## 6. Tiêu chí chuyển Proposed → Accepted

- [ ] Test concurrent producers cùng tên đích.
- [ ] Test destination đã tồn tại.
- [ ] Test crash trước và sau publish.
- [ ] Test nội dung trùng và khác thứ tự dòng.
- [ ] Ghi lại giới hạn và môi trường kiểm thử.
- [ ] Review lại trade-offs và cập nhật kết quả trong evidence.

**Chưa có evidence ⇒ không được chuyển sang Accepted.**
