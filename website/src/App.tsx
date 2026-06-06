import { useState, useEffect } from 'react';

interface ReleaseData {
  tag_name: string;
  name: string;
  body: string;
  published_at: string;
  assets: Array<{
    name: string;
    browser_download_url: string;
    size: number;
    download_count: number;
  }>;
}

function App() {
  const [release, setRelease] = useState<ReleaseData | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    fetch('https://api.github.com/repos/NgocThachTN/RockyDexMobile/releases/latest')
      .then((res) => {
        if (!res.ok) throw new Error('Failed to fetch latest release');
        return res.json();
      })
      .then((data: ReleaseData) => {
        setRelease(data);
        setIsLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setIsLoading(false);
      });
  }, []);

  const fallbackVersion = 'v1.0.11';
  const fallbackDownloadUrl = 'https://github.com/NgocThachTN/RockyDexMobile/releases/download/v1.0.11/rockydex-v1.0.11.apk';

  const currentVersion = release ? release.tag_name : fallbackVersion;
  const downloadUrl = release && release.assets.length > 0 
    ? release.assets[0].browser_download_url 
    : fallbackDownloadUrl;

  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString('vi-VN', { year: 'numeric', month: 'long', day: 'numeric' });
    } catch {
      return '';
    }
  };

  const formatSize = (bytes: number) => {
    if (!bytes) return '54.1 MB';
    const k = 1024;
    const dm = 1;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  };

  const cleanMarkdownText = (text: string) => {
    return text
      .replace(/\*\*/g, '')
      .replace(/\*/g, '')
      .replace(/`/g, '')
      .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1');
  };

  const renderChangelog = (body: string) => {
    if (!body) return null;
    
    const lines = body.split('\n').filter(line => line.trim().length > 0);
    return (
      <div className="changelog-content">
        {lines.map((line, idx) => {
          const cleanLine = cleanMarkdownText(line);
          if (cleanLine.startsWith('##') || cleanLine.startsWith('###')) {
            return (
              <h3 
                key={idx} 
                style={{ 
                  fontSize: '0.9rem', 
                  fontWeight: '700', 
                  margin: '16px 0 8px', 
                  color: '#f8fafc',
                  borderBottom: '1px solid #334155',
                  paddingBottom: '4px'
                }}
              >
                {cleanLine.replace(/#+\s*/, '')}
              </h3>
            );
          }
          if (cleanLine.startsWith('-') || cleanLine.startsWith('+')) {
            return (
              <li key={idx} style={{ marginLeft: '16px', marginBottom: '6px', listStyleType: 'square' }}>
                {cleanLine.replace(/^[-+]\s*/, '')}
              </li>
            );
          }
          return <p key={idx} style={{ marginBottom: '8px', fontSize: '0.875rem' }}>{cleanLine}</p>;
        })}
      </div>
    );
  };

  return (
    <div className="container">
      <div className="main-layout">
        
        {/* Left Column: Sticky App info */}
        <aside className="left-panel">
          <img 
            src="/app_icon.png" 
            alt="RockyDex Logo" 
            className="app-logo" 
          />
          <h1>RockyDex</h1>
          <p className="tagline">
            Ứng dụng đọc truyện tranh tối giản, nhanh chóng và mượt mà cho người dùng Việt Nam. Dữ liệu lưu offline hoàn toàn.
          </p>
          
          <div className="version-badge">
            <span className="pulse-dot"></span>
            <span>Bản mới nhất: {currentVersion}</span>
          </div>

          <div className="download-action">
            <a href={downloadUrl} download style={{ width: '100%' }}>
              <button className="btn-primary" type="button">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                  <polyline points="7 10 12 15 17 10" />
                  <line x1="12" y1="15" x2="12" y2="3" />
                </svg>
                Tải Xuống APK Ngay
              </button>
            </a>
            
            <a href="https://github.com/NgocThachTN/RockyDexMobile" target="_blank" rel="noopener noreferrer" style={{ width: '100%' }}>
              <button className="btn-secondary" type="button">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
                  <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" />
                </svg>
                Xem Trên GitHub
              </button>
            </a>
          </div>
        </aside>

        {/* Right Column: Content Cards */}
        <main className="right-panel">
          {/* Step-by-step installation guide */}
          <section className="card">
            <h2>Hướng Dẫn Tải & Cài Đặt</h2>
            <div className="steps-list">
              <div className="step-item">
                <div className="step-num">1</div>
                <div className="step-content">
                  <div className="step-title">Tải tệp tin APK</div>
                  <div className="step-desc">
                    Nhấp vào nút "Tải Xuống APK Ngay" ở cột bên trái để tải tệp cài đặt định dạng `.apk` trực tiếp về thiết bị Android.
                  </div>
                </div>
              </div>

              <div className="step-item">
                <div className="step-num">2</div>
                <div className="step-content">
                  <div className="step-title">Cho phép nguồn không xác định</div>
                  <div className="step-desc">
                    Điện thoại Android sẽ hỏi xác nhận khi cài đặt file APK từ bên ngoài. Hãy mở phần Cài đặt hệ thống của bạn và chọn "Cho phép cài đặt từ nguồn này".
                  </div>
                </div>
              </div>

              <div className="step-item">
                <div className="step-num">3</div>
                <div className="step-content">
                  <div className="step-title">Hoàn tất cài đặt</div>
                  <div className="step-desc">
                    Mở tệp cài đặt `.apk` đã tải xuống và chọn "Cài đặt". Sau khi chạy xong, biểu tượng RockyDex sẽ xuất hiện trên màn hình chính của bạn.
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* Feature Cards */}
          <section className="card">
            <h2>Tính Năng Nổi Bật</h2>
            <div className="features-grid">
              <div className="feature-item">
                <div className="feature-title">Đọc Truyện Offline</div>
                <div className="feature-desc">Toàn bộ danh sách yêu thích và lịch sử đọc truyện được lưu trữ offline hoàn toàn trên thiết bị của bạn.</div>
              </div>
              <div className="feature-item">
                <div className="feature-title">Bộ Lọc Cuộn Ngang</div>
                <div className="feature-desc">Thanh phân loại dạng chip cuộn ngang mượt mà. Lọc nhanh theo thể loại, quốc gia, năm phát hành chỉ với 1 chạm.</div>
              </div>
              <div className="feature-item">
                <div className="feature-title">Giao Diện Màn Hình 16:9</div>
                <div className="feature-desc">Tự động tối ưu hóa cỡ chữ, khoảng cách và các nút bấm phù hợp hoàn hảo với điện thoại màn hình 16:9 nhỏ gọn.</div>
              </div>
              <div className="feature-item">
                <div className="feature-title">Tự Động Kiểm Tra Cập Nhật</div>
                <div className="feature-desc">Tự động phát hiện phiên bản mới từ GitHub Release và gửi thông báo trực tiếp bên trong ứng dụng.</div>
              </div>
            </div>
          </section>

          {/* Dynamic Changelog from GitHub Release */}
          <section className="card">
            <h2>Nhật Ký Phiên Bản ({currentVersion})</h2>
            {isLoading ? (
              <div style={{ textAlign: 'center', padding: '20px', color: '#94a3b8' }}>Đang tải nhật ký cập nhật...</div>
            ) : release ? (
              <div>
                <div className="changelog-meta">
                  <span>Ngày phát hành: {formatDate(release.published_at)}</span>
                  <span>Dung lượng: {formatSize(release.assets[0]?.size)}</span>
                  <span>Lượt tải: {release.assets[0]?.download_count || 0} lần</span>
                </div>
                {renderChangelog(release.body)}
              </div>
            ) : (
              <div>
                <div className="changelog-meta">
                  <span>Tên file: rockydex-v1.0.11.apk</span>
                  <span>Dung lượng: 54.2 MB</span>
                </div>
                <p style={{ marginBottom: '8px' }}>Không thể tải nhật ký cập nhật trực tiếp. Dưới đây là các thay đổi chính trong v1.0.11:</p>
                <li style={{ marginLeft: '16px', marginBottom: '6px', listStyleType: 'square' }}>Tích hợp máy chủ truyện tranh MangaDex mới với hàng nghìn truyện quốc tế.</li>
                <li style={{ marginLeft: '16px', marginBottom: '6px', listStyleType: 'square' }}>Thêm menu thả xuống (dropdown) tại tiêu đề trang chủ để chọn máy chủ nguồn (OTruyen / MangaDex).</li>
                <li style={{ marginLeft: '16px', marginBottom: '6px', listStyleType: 'square' }}>Tự động phân nhóm và hỗ trợ đọc cả chương tiếng Việt và tiếng Anh trên MangaDex.</li>
              </div>
            )}
          </section>
        </main>
      </div>

      <footer className="footer">
        <p>&copy; {new Date().getFullYear()} RockyDex. Dự án mã nguồn mở phát hành dưới giấy phép MIT.</p>
        <p style={{ marginTop: '4px', fontSize: '0.75rem' }}>Được xây dựng bằng React, TypeScript và Vite.</p>
      </footer>
    </div>
  );
}

export default App;
