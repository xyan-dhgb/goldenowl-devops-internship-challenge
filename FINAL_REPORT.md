# BÁO CÁO TỔNG KẾT BÀI TEST VÒNG 2 CỦA GOLDENOWL DEVOPS INTERNSHIP CHALLENGE

## Công cụ sử dụng

- **Nền tảng cloud:** Google Cloud Platform (GCP)
- **Infrastructure as Code (IaC):** Terraform
- **CI/CD:** GitHub Actions
- **Docker Image Security Scan:** Trivy
- **Infrastructure as Code (IaC) Security Scan:** Checkov

## Lý do lựa chọn GCP

Trong bối cảnh bài kiểm tra, GCP được chọn làm nền tảng triển khai thay vì AWS hay Azure vì những ưu điểm vượt trội sau:

- **Hệ sinh thái Serverless (Cloud Run):** Cloud Run cho phép chạy trực tiếp Docker container một cách mượt mà, tự động scale về 0 để tiết kiệm 100% chi phí khi không có traffic.
- **Hạ tầng mạng toàn cầu xuất sắc (Global Load Balancer):** Tận dụng mạng lưới cáp quang toàn cầu của Google (Anycast IP), Load Balancer của GCP giúp định tuyến người dùng ở mọi quốc gia đến máy chủ nhanh nhất chỉ với một IP duy nhất.
- **Container Registry:** Lưu Docker image bằng Artifact Registry.

## Kiến trúc hệ thống

Hệ thống được thiết kế theo tiêu chuẩn của một kiến trúc Cloud-Native hiện đại, bảo mật và hoàn toàn tự động hóa.

### Thành phần Hạ tầng (GCP Infrastructure)

![Kiến trúc Hạ tầng GPC](/assets/image/gcp-infrastructure-overview.png)

- **Google Cloud Run:** Dịch vụ Serverless đóng vai trò làm môi trường chạy Container cho mã nguồn Node.js Backend API. Tự động mở rộng (Auto-scaling) từ 0 lên N instances tùy theo lượng truy cập.
- **Global External Application Load Balancer:** Bộ cân bằng tải toàn cầu của GCP. Đóng vai trò là "cửa ngõ" duy nhất (entry point) tiếp nhận mọi traffic từ Internet. Nó giao tiếp với Cloud Run thông qua một **Serverless NEG** (Network Endpoint Group). Kiến trúc này ép buộc người dùng phải đi qua Load Balancer (giúp chống DDoS và dễ gắn WAF) thay vì truy cập thẳng vào link nội bộ của Cloud Run.
- **Artifact Registry:** Kho lưu trữ nội bộ và bảo mật dành cho các Docker Image được Build ra từ mã nguồn.
- **Identity and Access Management (IAM):** Thiết lập Service Account chuyên dụng và phân quyền chặt chẽ theo nguyên tắc đặc quyền tối thiểu (Least Privilege). Sử dụng JSON Key lưu trong GitHub Secrets để tự động hóa.

### CI/CD Pipelines (GitHub Actions)

Hệ thống được chia làm 2 nhánh Pipeline rõ rệt:

1. **DevSecOps Pipeline (dành cho mã nguồn Node.js):**
   - Nằm trong thư mục `.github/workflows/`
   - Gồm các file: - [code-ci](./.github/workflows/code-ci.yaml): Tự động chạy **Lint**, **Unit Tests**, **Build Docker Image**, **Security Scan bằng Trivy** và **Push lên Artifact Registry**. - [code-cd](./.github/workflows/code-cd.yaml): Tự động cập nhật **Cloud Run**.

![cicd-for-be-source-code](/assets/image/cicd-for-be-source-code.png)

2. **Infrastructure Pipeline (Dành cho Hạ tầng Terraform):**
   - Nằm trong thư mục `.github/workflows/`
   - Gồm các file:
     - [infra-ci](./.github/workflows/infra-ci.yaml): Tự động format (`fmt`), kiểm tra cú pháp (`validate`), xuất bản nháp (`plan`) và kiểm tra bảo mật bằng **Checkov**.
     - [infra-cd-apply](./.github/workflows/infra-cd-apply.yaml): Tự động apply hạ tầng lên **GCP**.
     - [infra-cd-destroy](./.github/workflows/infra-cd-destroy.yaml): Tự động dọn dẹp hạ tầng trên **GCP**.
   - Báo cáo kết quả trực tiếp lên GitHub PR Comment và màn hình Summary.

![infrastructure-management-pipeline](/assets/image/infrastructure-management-pipeline.png)

## Cấu trúc dự án

- Dự án được tổ chức rất gọn gàng theo mô hình Module, phân tách rõ ràng giữa Application Code và Infrastructure Code:

```text
goldenowl-devops-internship-challenge/
├── .github/
│   └── workflows/
│       ├── code-ci.yaml         (CI cho mã nguồn: Test, Trivy, Build, Push)
│       ├── code-cd.yaml         (CD cho mã nguồn: Cập nhật Cloud Run)
│       ├── infra-ci.yaml        (CI cho Terraform: Fmt, Validate, Plan, Checkov)
│       ├── infra-cd-apply.yaml  (CD cho Terraform: Tự động Apply hạ tầng)
│       └── infra-cd-destroy.yaml(Dọn dẹp hạ tầng tự động)
│
├── infrastructure/
│   └── terraform/
│       ├── main.tf              (File gốc, gọi các module và cấu hình GCS backend)
│       ├── variables.tf         (Khai báo các biến đầu vào)
│       ├── outputs.tf           (Cấu hình đầu ra như IP, Email SA)
│       ├── apis.tf           (File khai báo APIs của GCP cần bật)
│       ├── backend.tf           (File khai báo remote backend sử dụng GCS)
│       └── modules/             (Kiến trúc Module Terraform tái sử dụng)
│           ├── artifact_registry/
│           ├── cloud_run/
│           ├── iam/
│           └── load_balancer/
│
├── src/
│   ├── Dockerfile               (File chỉ dẫn đóng gói ứng dụng)
│   ├── package.json             (Quản lý thư viện Node.js)
│   ├── routes/                  (Logic API Backend)
│   ├── server/                  (Khởi tạo Server)
│   └── tests/                   (Các file Unit Test)
│
└── FINAL_REPORT.md              (Báo cáo tổng kết dự án này)
```

## Deployment và link truy câp

- Vì cấu trúc hạ tầng hiện tại của chúng ta sử dụng Cloud Run đứng đằng sau một Global Load Balancer (và đã chặn truy cập trực tiếp vào Cloud Run qua biến `ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"`), cách duy nhất để kiểm tra là truy cập thông qua IP công cộng của Load Balancer.

- Lên Google Cloud Console, tìm kiếm trang Load balancing nhìn vào mục Frontends (Giao diện người dùng) sẽ thấy IP được cấp phát.

![load-balancer-public-ip](/assets/image/load-balancer-public-ip.png)

- Copy địa chỉ IP đó và dán lên trình duyệt (http://8.233.168.235/)

![response-from-be](/assets/image/response-from-be.png)
