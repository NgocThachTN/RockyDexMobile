# RockyDex Hướng Dẫn Cấu Trúc Mã Nguồn (Code Structure Guide)

Tài liệu này giải thích cấu trúc thư mục, triết lý thiết kế và quy tắc chia nhỏ tệp tin trong ứng dụng **RockyDexMobile** (Flutter). Mục tiêu giúp bất kỳ lập trình viên nào mới tham gia dự án đều có thể dễ dàng hiểu, bảo trì và phát triển tiếp mà không làm phá vỡ tính đồng nhất của hệ thống.

---

## 1. Triết Lý Thiết Kế: Feature-First & Clean Architecture

Ứng dụng được tổ chức theo từng **Tính năng (Feature-First)** kết hợp với **Kiến trúc sạch (Clean Architecture)**. 

### Tại sao lại chia theo Tính năng?
Thay vì gom tất cả màn hình vào một thư mục `screens/`, tất cả logic vào thư mục `blocs/`, chúng ta nhóm mọi thứ thuộc về một tính năng (ví dụ: `auth`, `comic`, `reader`) vào cùng một chỗ. Điều này giúp khi cần sửa một tính năng, bạn chỉ cần làm việc trong duy nhất thư mục tính năng đó.

### Sơ đồ 3 tầng logic trong mỗi Tính năng:
Mỗi thư mục tính năng (trong `lib/features/...`) được chia làm 3 tầng độc lập:

```text
📁 tên_tính_năng/
├── 📁 domain/          # 1. TẦNG NGHIỆP VỤ: Định nghĩa dữ liệu cốt lõi & Interface
│   └── comic_model.dart
├── 📁 data/            # 2. TẦNG DỮ LIỆU: Gọi API, Đọc/ghi DB, Map dữ liệu
│   └── comic_repository.dart
└── 📁 presentation/    # 3. TẦNG GIAO DIỆN: Vẽ UI & Quản lý trạng thái màn hình
    ├── 📁 screens/     # Chỉ chứa các màn hình chính (Scaffold, Router gọi tới)
    ├── 📁 widgets/     # Chứa các mảnh ghép nhỏ cấu thành nên màn hình chính
    └── home_notifier.dart
```

---

## 2. Quy Tắc Chia Nhỏ Tệp Tin (The Rule of Small Files)

> 💡 **Quy tắc vàng:** Một tệp tin Dart không nên vượt quá **250 dòng**. Nếu một màn hình lớn hoặc một lớp logic bắt đầu dài ra, hãy tìm cách tách nhỏ nó thành các tệp tin độc lập có logic rõ ràng.

### A. Tách Nhỏ Giao Diện (Presentation/UI)
*   **Screens (Màn hình chính):** Chỉ đóng vai trò là "khung xương" quản lý vòng đời (InitState, Dispose), khởi tạo `ScrollController` và lắp ghép các widget con lại với nhau. Không viết trực tiếp các widget thẻ, nút bấm phức tạp hoặc hộp thoại trực tiếp trong file Screen.
*   **Widgets (Mảnh ghép giao diện):** Mỗi khối giao diện riêng biệt có thể tái sử dụng hoặc có logic hiển thị phức tạp phải được tách thành một file riêng nằm trong thư mục `widgets/`.
    *   *Ví dụ:* Thẻ truyện [ComicGridCard](file:///e:/Coding/RockyDexMobile/mobile/lib/features/home/presentation/widgets/comic_grid_card.dart) được tách riêng để cả trang chủ (`HomeScreen`) và trang tìm kiếm (`SearchScreen`) đều dùng chung được, tránh viết trùng lặp code.
    *   *Ví dụ:* Khối lọc tag [HomeFilterSection](file:///e:/Coding/RockyDexMobile/mobile/lib/features/home/presentation/widgets/home_filter_section.dart) và khung chọn thể loại [CategoryGridSheet](file:///e:/Coding/RockyDexMobile/mobile/lib/features/home/presentation/widgets/category_grid_sheet.dart) được tách riêng để trang chủ gọn gàng và dễ đọc.

### B. Tách Nhỏ Logic Trạng Thái (State Management)
*   Không bao giờ viết logic xử lý dữ liệu (gọi mạng, tính toán) trực tiếp trong file giao diện.
*   Mỗi màn hình sẽ được liên kết với một `Notifier` chuyên biệt kế thừa `StateNotifier` (sử dụng Riverpod). 
*   `State` (Dữ liệu của màn hình) và `Notifier` (Hành động xử lý dữ liệu) được viết chung hoặc tách riêng nhưng phải tách độc lập khỏi tệp tin giao diện UI.

---

## 3. Bản Đồ Thư Mục Thực Tế (Directory Map)

Dưới đây là sơ đồ thư mục tổng thể của dự án Flutter dưới `mobile/lib/`:

*   [core/](file:///e:/Coding/RockyDexMobile/mobile/lib/core/) - Những thành phần dùng chung toàn bộ ứng dụng (Theme, Router, Network, LocalStorage).
    *   [constants/](file:///e:/Coding/RockyDexMobile/mobile/lib/core/constants/) - Lưu hằng số API (`api_constants.dart`), hằng số màu sắc (`colors.dart`).
    *   [network/](file:///e:/Coding/RockyDexMobile/mobile/lib/core/network/) - Cấu hình Dio Client, tự động đính kèm Token JWT khi gọi API.
    *   [storage/](file:///e:/Coding/RockyDexMobile/mobile/lib/core/storage/) - Cơ sở dữ liệu SQLite cục bộ (`LocalStorage`) lưu lịch sử và yêu thích offline.
    *   [router/](file:///e:/Coding/RockyDexMobile/mobile/lib/core/router/) - Bộ điều hướng toàn trang (`app_router.dart`) sử dụng GoRouter.
*   [features/](file:///e:/Coding/RockyDexMobile/mobile/lib/features/) - Các tính năng của ứng dụng:
    *   `auth/` - Đăng nhập, Đăng ký.
    *   `home/` - Trang chủ hiển thị danh sách dạng lưới 2 cột và các tag lọc thể loại.
    *   `search/` - Tìm kiếm truyện theo từ khóa dạng lưới 2 cột.
    *   `comic/` - Chi tiết truyện tranh, danh sách chương, nút yêu thích.
    *   `reader/` - Trình đọc truyện tranh cuộn dọc mượt mà.
    *   `library/` - Quản lý tủ sách yêu thích & lịch sử đã đọc.
    *   `profile/` - Thông tin cá nhân & đồ thị thống kê số chương đã đọc.
    *   `settings/` - Cài đặt giao diện đọc, cài đặt màu chủ đạo.

---

## 4. Hướng Dẫn Từng Bước: Cách Thêm Một Tính Năng Mới

Khi bạn muốn thêm một tính năng mới (ví dụ: Tính năng bình luận truyện `comment`), hãy làm theo các bước chuẩn mực sau:

### Bước 1: Tạo cấu trúc thư mục
Tạo thư mục tính năng mới trong `lib/features/`:
```text
lib/features/comment/
├── data/
├── domain/
└── presentation/
    ├── screens/
    └── widgets/
```

### Bước 2: Tạo Dữ Liệu Cốt Lõi (Domain Model)
Tạo tệp `comment_model.dart` trong thư mục `domain/` để định nghĩa dữ liệu bình luận:
```dart
class CommentModel {
  final String id;
  final String userName;
  final String content;
  final DateTime createdAt;

  CommentModel({required this.id, required this.userName, required this.content, required this.createdAt});

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userName: json['user_name'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

### Bước 3: Tạo Repository để gọi dữ liệu (Data Layer)
Tạo tệp `comment_repository.dart` trong thư mục `data/` để gọi API lấy bình luận:
```dart
import 'package:dio/dio.dart';
import 'comment_model.dart';

class CommentRepository {
  final Dio _dio;
  CommentRepository(this._dio);

  Future<List<CommentModel>> getComments(String comicSlug) async {
    final response = await _dio.get('/comments/$comicSlug');
    final list = response.data as List;
    return list.map((item) => CommentModel.fromJson(item)).toList();
  }
}
```

### Bước 4: Tạo Quản Lý Trạng Thái (Presentation State Notifier)
Tạo tệp `comment_notifier.dart` trong thư mục `presentation/` để quản lý trạng thái tải bình luận:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'comment_model.dart';
import 'comment_repository.dart';

class CommentState {
  final List<CommentModel> comments;
  final bool isLoading;
  CommentState({this.comments = const [], this.isLoading = false});
}

// Định nghĩa provider
// ...
```

### Bước 5: Viết Giao Diện và Chia Nhỏ Component (UI)
1. Tạo tệp màn hình chính `comment_screen.dart` trong `presentation/screens/`.
2. Nếu có thẻ hiển thị từng bình luận riêng biệt, tạo tệp `comment_tile.dart` trong `presentation/widgets/` và gọi nó từ màn hình chính.

---

## 5. Các Lệnh Tiêu Chuẩn Thường Dùng

Để đảm bảo mã nguồn sạch sẽ và không chứa lỗi cú pháp trước khi commit, hãy luôn chạy các lệnh sau trong thư mục `mobile/`:

*   **Tải thư viện:** `flutter pub get`
*   **Kiểm tra lỗi mã nguồn (Lint):** `flutter analyze`
*   **Tự động sửa định dạng code:** `dart format .`

---
> 💡 *Hãy luôn nhớ rằng: Mã nguồn được viết ra cho con người đọc trước, sau đó mới cho máy tính thực thi. Hãy viết mã nguồn thật đơn giản và tường minh!*
