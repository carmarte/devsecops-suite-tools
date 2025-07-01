FROM ubuntu@sha256:b59d21599a2b151e23eea5f6602f4af4d7d31c4e236d22bf0b62b86d2e386b8f

LABEL maintainer="DevSecOps Team" \
      description="DevSecOps Suite Tools for security testing and analysis" \
      version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Santo_Domingo \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TRIVY_INSECURE=false \
    TRiVY_DEBUG=true \
    TRIVY_CACHE=true \
    TRIVY_CACHE_DIR=/home/devsecops/.cache/trivy \
    TRIVY_NON_SSL=true \
    TRIVY_SKIP_DB_UPDATE=false \
    TRIVY_DB_REPOSITORY=docker.io/aquasecurity/trivy-db:latest \
    TRIVY_SEVERITY=HIGH,CRITICAL \
    TRIVY_IGNORE_UNFIXED=true \
    TRIVY_NO_PROGRESS=true \
    TRIVY_TIMEOUT=5s \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Install dependencies & packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget \
    git \
    jq \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    tar unzip \
    gnupg \
    ca-certificates \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a user for DevSecOps tools
RUN useradd -m -s /bin/bash devsecops \
    && echo "devsecops:devsecops" | chpasswd \
    && usermod -aG sudo devsecops
WORKDIR /home/devsecops
COPY . /home/devsecops/

# Install Trivy (SCA / Vulnerability Scanner)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Install Syft & Grype (SCA / Vulnerability Scanner)
RUN curl -sfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin \
    && curl -sfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install Gitleaks (Secret Scanner)
RUN curl -sfL https://github.com/gitleaks/gitleaks/releases/download/v8.27.2/gitleaks_8.27.2_linux_x64.tar.gz | tar -xz -C /usr/local/bin gitleaks \
    && chmod +x /usr/local/bin/gitleaks

# Install Semgrep (Code Analysis) 
RUN pip install --no-cache-dir semgrep --break-system-packages

RUN mkdir -p /home/devsecops/.cache/trivy \
    && chown -R devsecops:devsecops /home/devsecops

USER devsecops

CMD ["/bin/bash"]
