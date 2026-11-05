# File Deduplication Policy v1

**Loại:** Thiết kế chính sách · **Trạng thái:** Proposed  
**Đọc trước:** [Ba cấp độ identity](../01-knowledge/data/three-levels-of-identity.md)

## 1. Mục tiêu

Nhận diện file có khả năng trùng byte nhưng **không làm mất lịch sử tiếp nhận** hoặc tự suy diễn về bản ghi nghiệp vụ.

## 2. Định nghĩa

- **File ID / ingestion ID:** duy nhất cho mỗi lần tiếp nhận.
- **Filename:** nhãn từ producer; có thể trùng hoặc thay đổi.
- **SHA-256:** fingerprint của byte file, dùng phát hiện duplicate candidate.
- **Business key:** do hệ thống nguồn và nghiệp vụ xác định; nằm ngoài phạm vi dedup hoàn chỉnh của Project 01.

## 3. Quy tắc đề xuất

| Trường hợp | Hành động | Giải thích |
|---|---|---|
| Tên khác, hash khác | Tiếp nhận | Chưa đủ chứng minh bản ghi nghiệp vụ khác |
| Tên khác, hash giống | Ghi duplicate candidate; giữ audit | Chỉ bỏ qua xử lý khi policy cho phép |
| Tên giống, hash khác | Name collision; không ghi đè | Có thể là file cập nhật hay gửi nhầm |
| File đang xử lý | Không giao trùng nếu chưa có ownership/recovery protocol | Tránh hai worker cùng xử lý |
| CSV lỗi schema hoặc bị hỏng | Quarantine kèm lý do | Cần chứng cứ xác định lỗi dữ liệu |
| Job bị kill / disk full | Recovery/retry có kiểm soát | Không mặc định coi file dữ liệu sai |

## 4. Phạm vi v1

Project 01 tập trung vào file-level metadata, hash SHA-256 và audit policy. Record-level dedup và idempotent writes sẽ được phát triển sâu ở các dự án ETL và Warehouse.

## 5. Metadata đề xuất

`file_id`, `source_id`, `original_filename`, `sha256`, `status`, `received_at`, `attempt_count`, `error_code` (nếu có).

Chưa quyết định nơi lưu metadata. Không tuyên bố bất kỳ thao tác file + database nào là một transaction chung.

## 6. Test cases cần bổ sung

- [ ] Hai file byte giống nhau tên khác nhau.
- [ ] Hai CSV chứa cùng bản ghi nhưng thứ tự khác nhau.
- [ ] Hai file cùng tên nhưng byte khác nhau.
- [ ] Gửi lại file đã COMPLETED.
- [ ] Cùng `order_id` nhưng `amount` khác: không tự coi là duplicate.
- [ ] Hash giống nhưng ingestion ID khác: tạo hai audit records.

## 7. Quy tắc không được vi phạm

Không xóa file chỉ vì hash giống. Không coi file-level hash là bảo đảm tính doanh thu đúng một lần. Chỉ đánh dấu thiết kế là hoàn thành khi có bằng chứng thực nghiệm.
