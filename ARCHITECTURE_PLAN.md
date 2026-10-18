# HỆ THỐNG DẪN ĐƯỜNG CARPLAY & CẢNH BÁO GIAO THÔNG (NAUMAP)
## Master Technical Plan v2.1 (Production & HIG Compliant)

---

### 1. Kiến Trúc Phân Tầng NAUMAP Core v2.1

Kiến trúc tuân thủ nghiêm ngặt nguyên tắc **Inversion of Control** và **Dependency Boundaries**:
* **NAUMAP Core (Swift Package)**: Hoàn toàn thuần Swift (không import UIKit, không import MapLibre, không import CarPlay). Có thể chạy unit test độc lập trên macOS/iOS CLI.
* **UI & Presentation Layer**: Đóng vai trò là consumer đăng ký lắng nghe dữ liệu từ Core thông qua `AsyncStream`.

```
+---------------------------------------------------------------------------------------+
|                               UI & HARDWARE ADAPTERS                                  |
+---------------------------------------------------------------------------------------+
|  [CarPlay Target]                                      [iPhone Target (Optional)]     |
|  - CPTemplateApplicationSceneDelegate                  - UIWindowSceneDelegate        |
|  - CPMapTemplate (HUD, Maneuvers, Alerts)              - Single Map Strategy (Default)|
|  - CPWindow (Base Map Canvas - Touch Pass-through)                                    |
|  - Audio Ducking Service (AVAudioSession VoicePrompt)                                 |
+---------------------------------------------------------------------------------------+
                                           |
                                           | Subscribes to Events
                                           v
+---------------------------------------------------------------------------------------+
|                               NAUMAP CORE (SWIFT PACKAGE)                             |
|                           (Pure Swift · Concurrency Actors)                           |
+---------------------------------------------------------------------------------------+
|                                                                                       |
|  +---------------------------------------------------------------------------------+  |
|  | Navigation State Machine (Actor)                                                |  |
|  | States: .idle | .freeDrive(headingConfidence) | .navigating(routeProgress)      |  |
|  +---------------------------------------------------------------------------------+  |
|                                           ^                                           |
|                                           |                                           |
|  +---------------------------------------------------------------------------------+  |
|  | Spatial Alert Engine                                                            |  |
|  | - Query R-Tree bbox corridor -> Lọc Bearing góc mở ±30°                        |  |
|  | - Dynamic Lookahead Time (8s - 15s) dựa trên vận tốc                            |  |
|  | - FreeDrive Alert Mode: Bật cờ cảnh báo rủi ro đường song song khi không có Route|  |
|  | - Anti-Spam State Machine: Key (point_id, bearing_bucket, epoch_id)             |  |
|  +---------------------------------------------------------------------------------+  |
|                                           ^                                           |
|                                           |                                           |
|  +---------------------------------------------------------------------------------+  |
|  | Route & Progress Engine (Chỉ kích hoạt khi Navigating)                          |  |
|  | - Polyline Snapping & Map-Matching (Phân tách tầng cao độ Altitude)            |  |
|  | - Off-route Detection (> 30m trong 3s) -> Phát sự kiện .needsReroute           |  |
|  +---------------------------------------------------------------------------------+  |
|                                           ^                                           |
|                                           |                                           |
|  +---------------------------------------------------------------------------------+  |
|  | Location & Dead-Reckoning Engine                                                |  |
|  | - CoreLocation Adapter (kCLLocationAccuracyBestForNavigation)                   |  |
|  | - Quality Check: Bỏ qua tọa độ có horizontalAccuracy > 20m                      |  |
|  | - Tunnel Dead-Reckoning: Ước lượng dọc Polyline (V_last * dt * decay)           |  |
|  | - Confidence Timeout: Hạ confidence sau 15s mất GPS, ngừng dự phóng sau 45s    |  |
|  +---------------------------------------------------------------------------------+  |
|                                                                                       |
+---------------------------------------------------------------------------------------+
                                           ^
                                           | Repository Protocols
                                           v
+---------------------------------------------------------------------------------------+
|                               DATA & STORAGE LAYER                                    |
+---------------------------------------------------------------------------------------+
|  - Spatial Cache: GRDB.swift DatabasePool (SQLite WAL Mode, R*Tree Index)             |
|  - Routing Provider Protocol: Vietmap Routing / Local Valhalla Engine                |
|  - Incremental Sync: Tải và áp dụng Delta Sync gói dữ liệu giao thông                |
+---------------------------------------------------------------------------------------+
```

---

### 2. Các Điểm Kỹ Thuật Trọng Yếu Cần Khóa (Locked P0 & P1)

#### 🛑 P0: CarPlay Window & Giới Hạn Apple HIG
* **Nguyên tắc Base View**: `CPWindow.rootViewController.view` trong CarPlay Navigation App đóng vai trò là khung canvas chuyên dụng để vẽ bản đồ (`MLNMapView`). 
* **Cơ chế tương tác**: Hệ thống CarPlay **không chuyển phát sự kiện cảm ứng thông thường** (pan, pinch, tap tự do) lên view này. Mọi thao tác zoom, di chuyển camera (pan) và tương tác đều phải thông qua cụm nút điều khiển của `CPMapTemplate` (`mapButtons`, `panInterfaceVisible`).
* **Hiển thị thông tin chuẩn HIG**:
  - Không tùy tiện nhồi nhét custom view phức tạp lên `CPWindow` dễ dẫn đến vi phạm Apple App Review Guideline.
  - Sử dụng đúng API CarPlay chính thống:
    - Bảng thông tin dẫn đường: `CPManeuver`, `CPTravelEstimates`.
    - Biển cảnh báo ngắn hạn: `CPNavigationAlert`.
    - Các nút chức năng: `CPMapButton`.
  - Đối với biểu tượng Biển tốc độ giới hạn (Speed Limit Badge): Hiển thị dưới dạng một overlay nhỏ gọn nằm trong Safe Area Insets của `CPWindow`, không chặn bất kỳ nút điều hướng nào của Head Unit.

#### 🛑 P0: Cổng Kiểm Soát Entitlement
* Quyền `com.apple.developer.carplay-maps` là điều kiện tiên quyết để chạy trên thiết bị thật.
* Phân định 2 môi trường:
  - **Môi trường Simulator**: Cho phép chạy kiểm thử CarPlay UI với entitlement giả lập trong file `.entitlements` của target.
  - **Môi trường Thiết bị thật**: Chỉ kích hoạt được khi Provisioning Profile được cấp từ tài khoản Apple Developer đã được phê duyệt đơn xin CarPlay.

#### ⚠️ P1: Chiến Lược Single Map View (Bảo Toàn RAM & Tránh Jetsam)
* **Quyết định kiến trúc**: Mặc định **chỉ khởi tạo DUY NHẤT một instance `MLNMapView`** trên màn hình CarPlay.
* Khi người dùng mở app trên iPhone trong lúc xe đang kết nối CarPlay: Giao diện iPhone sẽ hiển thị dưới dạng **Companion Dashboard** (danh sách tóm tắt tuyến đường, điều khiển âm thanh, thông tin chuyến đi) thay vì render một map thứ hai.
* Chỉ xem xét kích hoạt map thứ hai trên iPhone khi có số liệu profiling chứng minh tổng memory footprint an toàn tuyệt đối (< 70MB trên các dòng iPhone cũ).

#### ⚠️ P1: Dead-Reckoning Hầm & Giới Hạn Tin Cậy (Confidence Decay)
* Không mặc định mọi Head Unit đều truyền được dữ liệu cảm biến xe (Wheel speed/Odometer).
* **Mô hình Dead-Reckoning an toàn**:
  - Khi xe mất GPS trong hầm (GPS horizontalAccuracy chuyển sang âm hoặc không có update > 2s):
  - Dự phóng khoảng cách theo công thức suy giảm: $S = V_{\text{last}} \times \Delta t \times \alpha^{\Delta t}$ (với hệ số suy giảm $\alpha = 0.98$).
  - **Giới hạn thời gian (Timeout)**:
    - $0 - 15\text{s}$: Trạng thái `.highConfidence` (vẫn tính toán tiến trình tuyến).
    - $15 - 45\text{s}$: Trạng thái `.lowConfidence` (hiển thị giao diện "Đang ước lượng vị trí trong hầm").
    - Sau $45\text{s}$: Ngừng dự phóng, chuyển sang trạng thái `.signalLost` để tránh đưa ra cảnh báo sai lệch nghiêm trọng.

#### ⚠️ P1: Hai Chế Độ Hoạt Động (FreeDrive vs Navigating)
* **Chế độ Navigating (Có lộ trình dẫn đường)**:
  - Map-matching được kích hoạt: Khóa tọa độ vào Polyline, độ tin cậy cảnh báo là 100%. Lọc chính xác cầu vượt/gầm cầu và đường gom.
* **Chế độ FreeDrive (Lái xe tự do / Không dẫn đường)**:
  - Không có Polyline để snap.
  - Cảnh báo hoạt động dựa trên: Tọa độ GPS + Vận tốc tức thời + Góc di chuyển (Course/Bearing ±30°).
  - Gắn nhãn cảnh báo với cờ `isAmbiguousRoute = true` nếu trong bán kính 25m có đường song song, hạ mức âm lượng cảnh báo để không làm phiền tài xế.

#### ⚠️ P1: Định Nghĩa Đo Lường KPI Thực Tế
* **Sai số thời gian cảnh báo**: Đo độ lệch giữa thời điểm âm thanh cảnh báo phát ra và mốc thời gian lý thuyết dự kiến xe chạm vào điểm đặt camera ($t_{\text{alert}} - (t_{\text{camera}} - t_{\text{lookahead}})$). Tiêu chuẩn chấp nhận được là trong khoảng $\pm 1.5\text{s}$.
* **Định mức RAM**: Đo tổng Dirty Memory của iOS Process bằng Xcode Memory Graph / Instruments trên thiết bị vật lý. Tiêu chuẩn: duy trì dưới 80MB khi đang chạy dẫn đường CarPlay.

---

### 3. Lộ Trình 5 Chặng Triển Khai (Milestones)

| Chặng | Tên Chặng | Đầu Ra Kỹ Thuật Cần Đạt (Deliverables) |
| :--- | :--- | :--- |
| **M1** | **CarPlay Skeleton & Foundation** | - Cấu hình Scene Manifest (`CPTemplateApplicationSceneDelegate` & `UIWindowSceneDelegate`).<br>- Khởi tạo `CPWindow` & tích hợp placeholder `MLNMapView`.<br>- Tách ranh giới: Target App và Swift Package Core. |
| **M2** | **Location & Route Engine** | - CoreLocation Pipeline với bộ lọc sai số GPS.<br>- Cơ chế Dead-Reckoning hầm với Confidence Decay.<br>- Route Progress, Polyline Snapping (Map-matching) và Off-route Detection. |
| **M3** | **Spatial Cache & Candidate Query** | - Khởi tạo GRDB.swift `DatabasePool` với SQLite R*Tree.<br>- Bounding box Lookahead corridor query.<br>- Bộ lọc Bearing và State Machine chống spam âm thanh. |
| **M4** | **CarPlay UI & Audio Subsystem** | - Trình diễn HUD/Alerts theo đúng chuẩn Apple HIG.<br>- Cấu hình `AVAudioSession` `.playback` + `.voicePrompt` + `.duckOthers`.<br>- Tích hợp TTS Tiếng Việt (`AVSpeechSynthesizer`). |
| **M5** | **Sync Pipeline & Thực Địa (Field Test)** | - Vietmap Delta Sync (hoặc Mock Data Pipeline).<br>- Bộ kịch bản GPX tái lập: Hầm Thủ Thiêm, Cầu vượt Hàng Xanh, Đường gom Thăng Long.<br>- Profiling RAM, CPU, Thermal trên xe thực tế. |

---

### 4. Quy Trình & Flow Các Bước Triển Khai Code Chi Tiết (Code Implementation Flow)

Để đảm bảo dự án vận hành mượt mà, không phụ thuộc vào thiết bị thật hay môi trường CarPlay phức tạp ngay từ đầu, quá trình code tuân theo nguyên tắc: **"Core-First, Test-Driven trên macOS/Host CLI -> Tích hợp CarPlay Adapter sau cùng"**.

#### 4.1. Runtime Data Flow Pipeline (Luồng Dữ Liệu Thời Gian Thực)

```
[ GPS CoreLocation / GPX Simulator ]
                 |
                 v (CLLocation update)
  +-------------------------------------------------------+
  | Bước A: Location Quality Gate & Dead-Reckoning         |
  | - Lọc horizontalAccuracy > 20m                        |
  | - Nếu mất GPS -> Dự phóng vị trí dọc Polyline (Decay)  |
  +-------------------------------------------------------+
                 |
                 v (Processed Location & Confidence)
  +-------------------------------------------------------+
  | Bước B: Route Snapping & State Machine                 |
  | - Mode = .navigating -> Snap to Polyline, tính ETE/ETA|
  |   Kiểm tra Off-route (>30m/3s) -> Phát .needsReroute   |
  | - Mode = .freeDrive -> Giữ raw heading & velocity     |
  +-------------------------------------------------------+
                 |
                 v (Corridor & Heading Vector)
  +-------------------------------------------------------+
  | Bước C: Spatial Alert Engine (SQLite R*Tree)          |
  | - Truy vấn Bounding Box hành lang dự phóng (8-15s)   |
  | - Lọc Bearing mở rộng ±30°                           |
  | - Kiểm tra Anti-Spam State Machine (cooldown/epoch)   |
  +-------------------------------------------------------+
                 |
                 v (AsyncStream<NavigationEvent>)
  +-------------------------------------------------------------------------+
  | Bước D: Presentation & Hardware Adapters (CarPlay / Audio)              |
  | 1. Audio Session: Ducking nhạc xe -> Phát cảnh báo / TTS Tiếng Việt    |
  | 2. CPMapTemplate: Update CPManeuver, CPTravelEstimates, CPNavigationAlert|
  | 3. CPWindow: Di chuyển MLNMapView camera mượt mà, cập nhật Speed Badge |
  +-------------------------------------------------------------------------+
```

---

#### 4.2. Chi Tiết 8 Bước Triển Khai Code (Step-by-Step Implementation Roadmap)

```
[BƯỚC 1: Package Skeleton] ──> [BƯỚC 2: Location & Dead-Reckoning]
                                              │
                                              ▼
[BƯỚC 4: Spatial Alert DB] <── [BƯỚC 3: Route Progress & Snapping]
          │
          ▼
[BƯỚC 5: Audio Ducking & TTS] ──> [BƯỚC 6: CarPlay Adapter]
                                              │
                                              ▼
[BƯỚC 8: E2E Profiling] <────── [BƯỚC 7: MapLibre Base Canvas]
```

##### 🟢 Bước 1: Khởi Tạo Cấu Trúc Swift Package & Target Boundary
* **Mục tiêu**: Tách biệt hoàn toàn business logic khỏi UI framework.
* **Các file code triển khai**:
  - `Package.swift`: Định nghĩa `NaumapCore` (Pure Swift) với dependency nhẹ: `GRDB.swift` (hoặc `SQLite.swift`).
  - `NaumapCore/Models/`: `Coordinate`, `GeoCorridor`, `TrafficPoint`, `ManeuverStep`, `AlertEvent`.
  - `NaumapCore/Protocols/`: `LocationProviderProtocol`, `RoutingProviderProtocol`, `AlertRepositoryProtocol`.
* **Kiểm thử nghiệm thu**: `swift test` chạy pass trên terminal macOS.

##### 🟢 Bước 2: Location Pipeline, Mock Provider & Dead-Reckoning Engine
* **Mục tiêu**: Xử lý tọa độ GPS và thuật toán duy trì vị trí khi xe vào hầm mất tín hiệu.
* **Các file code triển khai**:
  - `NaumapCore/Location/LocationServiceActor.swift`: Nhận stream `CLLocation`, lọc nhiễu accuracy > 20m.
  - `NaumapCore/Location/DeadReckoningEngine.swift`: Triển khai công thức suy giảm $S = V_{\text{last}} \times \Delta t \times 0.98^{\Delta t}$, quản lý 3 mốc: `< 15s` (High), `15s - 45s` (Low), `> 45s` (Lost).
  - `NaumapCore/Testing/GPXPlaybackService.swift`: Parser đọc file `.gpx` xuất ra luồng stream giả lập tốc độ thực tế (1x, 2x, 5x) để test mà không cần lái xe ngoài đường.
* **Kiểm thử nghiệm thu**: Unit test mô phỏng mất GPS đột ngột trong 30s và kiểm tra vị trí ước lượng có khớp với hành lang hầm.

##### 🟢 Bước 3: Route Progress, Polyline Snapping & Off-Route Detection
* **Mục tiêu**: Theo dõi tiến trình hành trình và phát hiện khi tài xế đi lạc đường.
* **Các file code triển khai**:
  - `NaumapCore/Route/PolylineSnapper.swift`: Chiếu vuông góc vị trí xe lên phân đoạn polyline gần nhất; phân tách tầng độ cao (`altitude`) khi gặp cầu vượt.
  - `NaumapCore/Route/RouteProgressTracker.swift`: Tính toán khoảng cách còn lại, ETE, ETA đến điểm rẽ tiếp theo.
  - `NaumapCore/Route/OffRouteDetector.swift`: Bộ đếm thời gian thực; nếu sai lệch > 30m liên tục trong 3s thì phát sinh sự kiện `.needsReroute`.
* **Kiểm thử nghiệm thu**: Chạy bộ dữ liệu GPX rẽ nhầm nhánh cầu vượt -> trigger reroute event trong đúng 3 giây.

##### 🟢 Bước 4: Spatial SQLite R*Tree & Spatial Alert Engine
* **Mục tiêu**: Tìm kiếm và kích hoạt cảnh báo camera phạt nguội/biển báo tốc độ chính xác từng mili-giây.
* **Các file code triển khai**:
  - `NaumapCore/Database/SpatialDatabasePool.swift`: Setup GRDB SQLite WAL mode, bảng R*Tree `rtree_traffic_alerts(id, minX, maxX, minY, maxY)`.
  - `NaumapCore/Alert/SpatialAlertEngine.swift`: Tạo bounding box hành lang di chuyển phía trước ($V \times t_{\text{lookahead}}$), query R*Tree.
  - `NaumapCore/Alert/BearingFilter.swift`: Tính góc chênh lệch giữa hướng xe chạy và góc ghi nhận của camera ($\Delta \theta \le 30^\circ$).
  - `NaumapCore/Alert/AlertDeduplicator.swift`: State machine chống lặp âm thanh theo `(point_id, bearing_bucket, epoch_id)`.
* **Kiểm thử nghiệm thu**: Test 10,000 điểm camera trên toàn quốc; thời gian query R*Tree < 5ms trên CPU di động.

##### 🟢 Bước 5: Audio Ducking & TTS Subsystem
* **Mục tiêu**: Giảm âm lượng nhạc xe (Spotify/Radio) mượt mà để giọng đọc cảnh báo vang lên rõ ràng.
* **Các file code triển khai**:
  - `NaumapApp/Audio/AudioDuckingService.swift`: Cấu hình `AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])`.
  - `NaumapApp/Audio/VoicePromptService.swift`: Hàng đợi ưu tiên phát âm thanh: Chime tone (ding ding) -> TTS tiếng Việt qua `AVSpeechSynthesizer` giọng miền Nam/Bắc (`vi-VN`).
* **Kiểm thử nghiệm thu**: Phát nhạc nền, trigger cảnh báo -> nhạc xe hạ âm lượng (ducking) xuống 30%, kết thúc câu nói nhạc tự động hồi phục về 100%.

##### 🟢 Bước 6: CarPlay Application Scene & Lifecycle Adapters
* **Mục tiêu**: Kết nối Core State Machine với vòng đời CarPlay chuẩn Apple HIG.
* **Các file code triển khai**:
  - `NaumapApp/CarPlay/CarPlaySceneDelegate.swift`: Kế thừa `CPTemplateApplicationSceneDelegate`.
  - `NaumapApp/CarPlay/CarPlayNavigationCoordinator.swift`:
    - Quản lý `CPMapTemplate`: gán `mapButtons` (Zoom, Pan, Compass, Route Overview).
    - Quản lý `CPNavigationSession`: gọi `showManeuvers()`, `updateTravelEstimates()`.
    - Quản lý `CPNavigationAlert`: hiển thị popup banner tốc độ chuẩn hệ thống CarPlay.
* **Kiểm thử nghiệm thu**: Chạy trên CarPlay Simulator, test kết nối/ngắt kết nối bất ngờ (plug/unplug cable) mà không crash app.

##### 🟢 Bước 7: MapLibre Base Canvas & Safe Area Overlay Binding
* **Mục tiêu**: Hiển thị bản đồ vector hiệu năng cao trên `CPWindow` với Single Map Strategy.
* **Các file code triển khai**:
  - `NaumapApp/Map/CarPlayMapViewController.swift`: Nhúng `MLNMapView` vào `CPWindow.rootViewController`.
  - `NaumapApp/Map/MapCameraController.swift`: Đồng bộ camera tracking: chế độ 3D bám đuôi xe (Course-up) khi dẫn đường, 2D North-up khi xem tổng thể.
  - `NaumapApp/UI/SpeedLimitBadgeOverlay.swift`: Widget hiển thị tốc độ giới hạn hiện tại, nằm gọn trong Safe Area insets của head unit, đổi màu đỏ rực khi quá tốc độ.
* **Kiểm thử nghiệm thu**: Giao diện không đè lên các phím chức năng của CarPlay UI; khung hình đạt ổn định 60fps khi xe rẽ liên tục.

##### 🟢 Bước 8: GPX Automated Scenarios & Real-car Profiling
* **Mục tiêu**: Đóng gói kịch bản kiểm thử tự động và đo đạc chỉ số RAM/Nhiệt độ.
* **Kịch bản kiểm thử cần pass**:
  1. `scenario_thu_thiem_tunnel.gpx`: Mất sóng 1.4km -> Kiểm tra Dead-reckoning không drift lệch sông Sài Gòn.
  2. `scenario_hang_xanh_flyover.gpx`: Xe đi trên cầu vượt -> Không cảnh báo camera phạt nguội đặt ở ngã tư gầm cầu phía dưới.
  3. `scenario_thang_long_parallel.gpx`: Lái ở cao tốc -> Không nhặt nhầm biển báo tốc độ 40km/h của đường gom song song (FreeDrive mode).
* **Đo lường hiệu năng**: Dùng Instruments Profiling đảm bảo:
  - RAM Dirty Memory < 75MB.
  - CPU Idle khi lái xe bình thường < 12%.

