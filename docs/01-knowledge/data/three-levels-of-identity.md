# Ba cấp độ nhận diện dữ liệu

**Loại tài liệu:** Knowledge · **Mục tiêu:** Phân biệt định danh lần tiếp nhận với nội dung và thực thể nghiệp vụ

## 1. File Identity — Định danh file/lần tiếp nhận

Mỗi lần producer gửi file được gắn `file_id` hoặc `ingestion_id` riêng.

Ví dụ hai lần gửi đều có tên `orders.csv`, nhưng có `file_id = recv-001` và `recv-002`.

**Tại sao cần?** Theo dõi thời điểm nhận, nguồn gửi, trạng thái, số lần retry, audit. Tên file do bên gửi đặt không đủ để biểu diễn danh tính duy nhất.

## 2. Content Identity — Định danh theo nội dung

Sử dụng SHA-256 để tính fingerprint từ **toàn bộ byte theo đúng thứ tự** trong file.

```bash
sha256sum tests/fixtures/orders-a.csv
```

Hai CSV chứa cùng dòng nhưng khác thứ tự; khác khoảng trắng, mã hóa hoặc xuống dòng LF/CRLF thường tạo hash khác. Hai file có cùng SHA-256 là bằng chứng rất mạnh rằng nội dung giống nhau, **không phải chứng minh tuyệt đối** vì về lý thuyết hash collision tồn tại.

**Không được suy ra:** Cùng hash ⇒ được xóa một lần tiếp nhận, hoặc khác hash ⇒ đơn hàng nghiệp vụ khác nhau.

## 3. Business Identity — Định danh theo quy tắc nghiệp vụ

Dùng khóa phù hợp mô hình dữ liệu:
- Đơn hàng dạng current state: có thể dùng `order_id` và chính sách cập nhật.
- Order events bất biến: có thể dùng `event_id` hoặc `(order_id, event_type, version)` nếu nghiệp vụ quy định.

Cùng `order_id` nhưng khác `amount` có thể là update hợp lệ, hoặc conflict cần điều tra. **Không tự chọn bản mới nhất khi chưa có quy tắc.**

## 4. Ví dụ so sánh

| Tình huống | File identity | Content identity | Business identity |
|---|---|---|---|
| Gửi cùng byte hai lần | Khác | Giống | Có thể giống |
| Đảo thứ tự các dòng CSV | Khác | Thường khác | Có thể giống |
| Tên file giống, nội dung thay đổi | Khác nếu nhận lại | Khác | Cần xem version/rules |
| Một order xuất hiện trong hai batch | Khác | Khác | Có thể trùng bản ghi |

## 5. Deduplication không đồng nghĩa với idempotency

- **Deduplication:** Nhận diện dữ liệu có thể lặp.
- **Idempotency:** Thực thi lại một thao tác không làm phát sinh thêm tác động không mong muốn.
- **Transaction:** Giúp bảo đảm tính nhất quán trong phạm vi tài nguyên có transaction, nhưng không tự bao trùm filesystem + database.

File hashing không chứng minh exactly-once effects. Một output đã ghi nhưng metadata chưa cập nhật có thể dẫn đến retry và tạo output lần nữa nếu thiết kế không an toàn.

## 6. Metadata tối thiểu đề xuất

```json
{
  "file_id": "recv-001",
  "source_id": "omnicommerce-export",
  "original_filename": "orders.csv",
  "sha256": "<digest-hex-thuc-te>",
  "status": "RECEIVED",
  "received_at": "2026-11-05T10:00:00Z",
  "attempt_count": 0
}
```

Đây là **schema ví dụ**, chưa quyết định lưu metadata dưới dạng JSON/SQLite/PostgreSQL. Mỗi lần nhận cần được audit riêng, dù nội dung có thể trùng.

## 7. Cách tự kiểm tra đã hiểu

1. Vì sao rename file không thay đổi content hash?
2. Vì sao hai file có hash khác nhau vẫn có thể chứa cùng đơn hàng?
3. Vì sao không thể dùng `sha256` làm khóa duy nhất cho mỗi lần gửi?
4. Khi nào `order_id` không đủ để làm idempotency key?
