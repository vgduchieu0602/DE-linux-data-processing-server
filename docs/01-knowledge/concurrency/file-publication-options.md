# Ba phương án công bố file an toàn

**Loại tài liệu:** Knowledge · **Ngôn ngữ:** Tiếng Việt  
**Chủ đề:** Concurrency, race condition, safe file publication

## 1. Bài toán cần giải quyết

Hai producer tạo `orders-A.part` và `orders-B.part` riêng biệt nhưng cùng muốn công bố vào `incoming/orders.csv`. Tên file tạm riêng loại bỏ tranh chấp ở giai đoạn ghi file tạm, **không giải quyết** tranh chấp khi publish.

Nếu cả hai làm `if destination chưa tồn tại → mv`, chúng có thể cùng kiểm tra thấy đích trống rồi cùng ghi. Đây là **TOCTOU (time-of-check to time-of-use)**.

## 2. Phương án A — Unique Destination Filename

**Nguyên lý:** Mỗi lần tiếp nhận có một `ingestion_id`, ví dụ `incoming/orders-01HX...csv`. Nhờ đó producer không cần cạnh tranh cho một tên đích cố định.

**Ưu điểm**
- Giảm shared mutable state và tránh phần lớn va chạm tên.
- Dễ lưu lại lịch sử từng lần gửi (audit).
- Consumer có thể xử lý nhiều file độc lập.

**Giới hạn**
- Tên khác nhau **không đồng nghĩa** nội dung khác nhau; vẫn cần deduplication.
- ID phải được cấp đủ an toàn; không coi timestamp độ phân giải thấp là duy nhất.
- Nếu publish vào một tên đã tồn tại do trùng ID hoặc lỗi, phải xử lý rõ ràng; unique naming không tự biến thao tác ghi đè thành an toàn.

**Khi dùng:** Dữ liệu mang tính append/ingestion, cho phép nhiều tên file và muốn theo dõi mỗi lần gửi.

## 3. Phương án B — File Locking

**Nguyên lý:** Các producer cùng lấy khóa trước khi thao tác trên tài nguyên chung.

```text
Producer A: lấy lock → kiểm tra đích → publish → nhả lock
Producer B: đợi lock → kiểm tra đích → xử lý xung đột → nhả lock
```

Trên Linux, có thể học `flock`. **Advisory lock** chỉ có tác dụng khi tất cả chương trình liên quan đều tuân thủ quy ước khóa.

**Ưu điểm:** Tuần tự hóa đoạn code quan trọng (*critical section*) và cho phép ghép nhiều bước kiểm tra với thao tác publish.

**Hạn chế:**
- Lock **không tự động** ngăn `mv` thay thế file; logic trong critical section vẫn phải kiểm tra và xử lý.
- Process bỏ qua lock vẫn có thể truy cập file.
- Phải xác định phạm vi khóa, timeout, tình huống crash và mức độ hỗ trợ filesystem.

**Khi dùng:** Cần bảo vệ tài nguyên cố định, và mình kiểm soát được các producer.

## 4. Phương án C — Atomic No-Overwrite Publication

**Nguyên lý:** Một thao tác hệ thống công bố tên đích **chỉ khi tên đó chưa tồn tại**, tránh khoảng hở giữa kiểm tra và thực thi.

Trên Linux, `renameat2(..., RENAME_NOREPLACE)` có thể đáp ứng trên filesystem hỗ trợ. Nếu đích đã tồn tại, thao tác thất bại (thường với `EEXIST`) thay vì thay thế file.

**Ưu điểm:** Đẩy kiểm tra xung đột và công bố vào một thao tác nguyên tử; bảo vệ trước TOCTOU trong phạm vi thao tác.

**Hạn chế:**
- Phụ thuộc Linux kernel, filesystem và cách truy cập syscall.
- Rename giữa các filesystem thường không hoạt động như rename nguyên tử (ví dụ lỗi `EXDEV`).
- Atomic rename **không đồng nghĩa** durability sau mất điện; cần nghiên cứu `fsync` và thư mục.
- Không tự giải quyết business duplicate hoặc exactly-once effects.

**Khi dùng:** Tên đích phải được tạo một lần, tuyệt đối không thay thế ngoài ý muốn.

## 5. Những cách dễ sai

```bash
if [[ ! -e "$dest" ]]; then
  mv "$src" "$dest"
fi
```

Đoạn code này **không chống TOCTOU**.

- `mv -T`: coi đích là file thay vì thư mục; **không** có nghĩa là no-overwrite.
- `mv -n`: hành vi và tính nguyên tử phải được kiểm chứng với phiên bản coreutils/filesystem; không mặc định coi là primitive portable no-overwrite.
- `mktemp`: tạo file tạm với tên riêng an toàn; **không** giải quyết race ở tên đích.

## 6. So sánh

| Tiêu chí | Unique destination | Locking | Atomic no-overwrite |
|---|---|---|---|
| Tránh hai producer ghi chung file tạm | Cần temp riêng | Không mặc định | Không mặc định |
| Giảm xung đột tên đích | Có | Tuần tự hóa | Từ chối ghi đè |
| Cần producer hợp tác | Quy ước tên/ID | Có | Không cho thao tác cùng tên đích được hỗ trợ |
| Tự phát hiện trùng nội dung | Không | Không | Không |
| Bảo đảm dữ liệu bền vững sau crash | Không | Không | Không |

## 7. Bài thực hành cần kiểm chứng

1. Hai producer cùng tên tạm: quan sát nguy cơ ghi chồng.
2. Hai producer tên tạm riêng nhưng cùng đích: kiểm tra overwrite.
3. Hai producer tên đích riêng: chứng minh cả hai được công bố.
4. Thử một destination đã có sẵn, ghi lại exit code và nội dung trước/sau.
5. Thử producer bị kill trước publication; đánh giá file còn lại.
6. Kiểm tra `stat -f` / mount và thử rename khác filesystem trên môi trường thử nghiệm.

**Ghi nhớ:** Safe file publication, deduplication, crash durability và consumer idempotency là các vấn đề **khác nhau**. Không đánh đồng.
