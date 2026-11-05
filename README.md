# Linux Data Processing Server

> **Module 01 · Project 01 — Engineering Foundations**  
> OmniCommerce — mô phỏng máy chủ Linux tiếp nhận, công bố và xử lý dữ liệu file CSV an toàn.

## Mục tiêu

Học Linux và tư duy Data Engineering qua các vấn đề thực tế: vòng đời file, atomic publication, concurrency, data identity, deduplication, retry/recovery, logging và kiểm chứng bằng test. Mỗi kỹ thuật đều được giải thích **vấn đề → nguyên lý → lựa chọn → quyết định → bằng chứng**.

**Trạng thái:** Đang học và thiết kế; các lựa chọn trong ADR hiện là **Proposed**, chưa được kiểm chứng để coi là production-ready.

## Bản đồ tài liệu

| Nhu cầu | Tài liệu |
|---|---|
| Hiểu ba phương án công bố file: tên đích riêng, locking, no-overwrite | [Ba phương án File Publication](docs/01-knowledge/concurrency/file-publication-options.md) |
| Phân biệt file identity, content identity, business identity | [Ba cấp độ nhận diện dữ liệu](docs/01-knowledge/data/three-levels-of-identity.md) |
| Hiểu luồng producer → staging → incoming, failure scenarios | [Safe File Publication v1](docs/02-design/safe-file-publication.md) |
| Quy tắc xử lý file trùng và xung đột | [File Deduplication Policy v1](docs/02-design/deduplication-policy.md) |
| Vì sao đề xuất lựa chọn kiến trúc này | [ADR-001 — File Publication](docs/03-decisions/ADR-001-file-publication.md) |
| Cách ghi kết quả kiểm thử thành chứng cứ kỹ thuật | [Hướng dẫn Evidence](docs/05-evidence/README.md) |

## Cấu trúc hiện có

```text
scripts/
  producer.sh    # Demo ghi file .part, sau đó mv sang incoming
  consumer.sh    # Demo polling incoming/orders.csv
docs/
  01-knowledge/  # Kiến thức độc lập với quyết định của dự án
  02-design/     # Luồng và chính sách được đề xuất
  03-decisions/  # Architecture Decision Records
  05-evidence/   # Kế hoạch/chứng cứ kiểm thử
```

## Chạy demo hiện có (chưa phải pipeline an toàn)

Từ thư mục gốc repository trong Ubuntu/WSL2, mở hai terminal:

```bash
# Terminal 1
bash scripts/consumer.sh

# Terminal 2 (khởi chạy ngay sau đó)
bash scripts/producer.sh
```

**Cảnh báo quan trọng:** `scripts/producer.sh` hiện ghi vào tên tạm cố định `orders.csv.part` và dùng `mv -T` vào đích cố định `orders.csv`. Demo **chưa** chống concurrent producers hoặc overwrite; `consumer.sh` cũng chưa có claim/locking, kiểm tra checksum, idempotency hay retry. Không dùng các script này với dữ liệu quan trọng. Trước khi thử lại, kiểm tra file đích cũ để tránh vô tình ghi đè.

## Cách học và ghi nhận tiến độ

1. Đọc tài liệu **Knowledge**, hiểu cơ chế trước khi copy lệnh.
2. Đọc **Design**, mô tả các trạng thái và tình huống lỗi.
3. Xem **ADR** để biết lựa chọn và trade-offs, chưa đồng nhất đề xuất với quyết định đã xác minh.
4. Thực hành trong `scripts/` và tạo test trong `tests/` khi đến checkpoint.
5. Ghi lệnh chạy, điều kiện, kết quả thật và hạn chế vào `docs/05-evidence/`.

Lưu ý: không commit dữ liệu runtime chứa dữ liệu nhạy cảm; dùng dữ liệu giả lập cho test.
