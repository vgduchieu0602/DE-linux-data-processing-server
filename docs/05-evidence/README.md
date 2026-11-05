# Evidence — Bằng chứng kỹ thuật

**Trạng thái:** Chưa có kết quả kiểm thử được ghi nhận trong thư mục này.

## Mục đích

Chứng minh từng quyết định thiết kế bằng thao tác chạy thật, không chỉ khẳng định bằng lời. Test failures cũng là chứng cứ cần giữ và phân tích.

## Mẫu file cho mỗi thử nghiệm

```markdown
# EXP-001 — Kiểm tra publication khi có hai producer

- Ngày:
- Hệ điều hành/kernel:
- Filesystem / mount:
- Script / commit SHA:
- Giả thuyết:
- Điều kiện đầu vào:
- Các lệnh chạy:
- Kết quả mong đợi:
- Kết quả thực tế:
- Exit code:
- Kết luận:
- Giới hạn chưa kiểm chứng:
```

## Danh sách thực nghiệm ưu tiên

1. `mktemp` tạo temp riêng giữa hai producer.
2. Tình huống TOCTOU và khả năng ghi đè `mv -T`.
3. Atomic rename cùng filesystem.
4. Producer bị kill trước publication.
5. Hai file khác tên, cùng SHA-256.
6. Hai CSV cùng tập bản ghi nhưng khác thứ tự.
7. Retry sau khi output đã ghi nhưng metadata chưa cập nhật (khi có implementation).

**Không đánh dấu “Passed” nếu chưa chạy và ghi lại bằng chứng.**
