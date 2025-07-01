#!/bin/bash

# This script is used to run the tools in the devsecops-suite-tools directory.
# It will run each tool in the tools directory and output the results to a file.
# Usage: ./run_tools.sh [tool_name]

# Check if a tool name is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 [tool_name]"
  echo -e "
    ✅Available tools:
      - Trivy
      - Sfyt & Grype
      - Gitleaks
      - Semgrep
      "
  exit 1
fi

TOOL_NAME=$1
TEMPLATE_DIR="/home/devsecops/templates"
IMAGE_NAME="${IMAGE_NAME:-/home/devsecops/images/ubuntu:latest}"
SRC_DIR="${SRC_DIR:-/home/devsecops/src}"
REPORTS_DIR="${REPORTS_DIR:-/home/devsecops/reports}"

if [ ! -d "$REPORTS_DIR" ]; then
  mkdir -p "$REPORTS_DIR"
  echo -e "\n📂 Created reports directory: $REPORTS_DIR"
else
  echo -e "\n📁 Reports directory already exists: $REPORTS_DIR"
fi

# Function to run Trivy
run_trivy() {
    echo -e "\n🔍 Running Trivy scan..."

    trivy image --download-db-only

    if [[ ! -f "$TEMPLATE_DIR/trivy-html.tpl" ]]; then
      echo -e "\n❌ Trivy report template not found at $TEMPLATE_DIR/trivy-html.tpl"
    else 
        echo -e "\n✅ Using Trivy HTML report template at $TEMPLATE_DIR/trivy-html.tpl"
        trivy image --exit-code 0 \
          --severity CRITICAL,HIGH \
          --ignore-unfixed \
          --format template \
          --template "@$TEMPLATE_DIR/trivy-html.tpl" \
          --output "$REPORTS_DIR/trivy_report.html"\
          "$IMAGE_NAME"

        trivy image --exit-code 0 \
          --severity CRITICAL,HIGH \
          --ignore-unfixed \
          --format sarif \
          --output "$REPORTS_DIR/trivy_report.sarif"\
          "$IMAGE_NAME"
    fi

    if [ $? -ne 0 ]; then
        echo -e "❌ Trivy scan failed. Please check the image name and try again."
        exit 1
    else
        echo -e "✅ Trivy scan completed. Report saved to $REPORTS_DIR/trivy_report.{html,sarif}"
    fi

}

# Function to run Snyk and Grype
run_syft_grype() {
    echo -e "\n🔍 Running Syft & Grype scans..."

    syft scan "dir:${SRC_DIR}" \
        -o json > "$REPORTS_DIR/syft_report.json" \

    syft scan "dir:${SRC_DIR}" \
        -o template -t "$TEMPLATE_DIR/syft-html.tmpl" > "$REPORTS_DIR/syft_report.html" \

    if [ $? -ne 0 ]; then
        echo -e "\n❌ Syft scan failed. Please check the image/path name and try again."
    else
        echo -e "\n✅ Syft scan completed. Report saved to $REPORTS_DIR/syft_report.json"
    fi

    if [[ ! -f "$TEMPLATE_DIR/grype-html.tmpl" ]]; then
        echo -e "\n❌ Grype HTML report template not found at $TEMPLATE_DIR/grype-html.tmpl"
    else 
        echo -e "\n✅ Using Grype HTML report template at $TEMPLATE_DIR/grype-html.tmpl"
        grype "sbom:$REPORTS_DIR/syft_report.json" \
          --only-fixed \
          --output template \
          --template "$TEMPLATE_DIR/grype-html.tmpl" \
          --file "$REPORTS_DIR/grype_report.html"
    fi
    if [ $? -ne 0 ]; then
        echo -e "❌ Grype scan failed. Please check the image name and try again."
    else
        echo -e "✅ Grype scan completed. Report saved to $REPORTS_DIR/grype_report.html"
    fi

}

# Function to run Gitleaks
run_gitleaks() {
    echo -e "\n🔍 Running Gitleaks scan..."

    git config --global --add safe.directory "$SRC_DIR"

    if [[ ! -f "$TEMPLATE_DIR/gitleaks-html.tmpl" ]]; then
        echo -e "\n❌ Gitleaks HTML report template not found at $TEMPLATE_DIR/gitleaks-html.tmpl"
    else
        echo -e "\n✅ Using Gitleaks HTML report template at $TEMPLATE_DIR/gitleaks-html.tmpl"

        gitleaks git "$SRC_DIR" \
          --log-opts -1 -v \
          --exit-code 0 \
          --platform azuredevops \
          --report-path "$REPORTS_DIR/gitleaks_report.html" \
          --report-format template \
          --report-template "$TEMPLATE_DIR/gitleaks-html.tmpl"
        
        gitleaks git "$SRC_DIR" \
          --log-opts -1 -v \
          --exit-code 0 \
          --platform azuredevops \
          --report-format sarif \
          --report-path "$REPORTS_DIR/gitleaks_report.sarif"
    fi
    if [ $? -ne 0 ]; then
        echo -e "\n❌ Gitleaks scan failed. Please check the path name and try again."
    else
        echo -e "\n✅ Gitleaks scan completed. Report saved to $REPORTS_DIR/gitleaks_report.{html,sarif}"
    fi
}

# Function to run Semgrep
run_semgrep() {
    echo -e "\n🔍 Running Semgrep scan..."

    semgrep --config=auto "${SRC_DIR}" \
      -v \
      --json --json-output="$REPORTS_DIR/semgrep_report.json"
    
    if [ $? -ne 0 ]; then
        echo -e "\n❌ Semgrep scan failed. Please check the path name and try again."
    else
        echo -e "\n✅ Semgrep scan completed. Report saved to $REPORTS_DIR/semgrep_report.json"
    fi
}

shift
case $TOOL_NAME in
    trivy)
        run_trivy
        ;;
    syft|grype)
        run_syft_grype
        ;;
    gitleaks)
        run_gitleaks
        ;;
    semgrep)
        run_semgrep
        ;;
    *)
        echo -e "
            ❌ Unknown tool: $TOOL_NAME
            
            ✅ Available tools: trivy, syft, grype, gitleaks, semgrep
            
            🎯 Usage:
            docker run --rm \
                -v /path/to/your/repo:/home/devsecops/src \
                -v /path/to/your/reports:/home/devsecops/reports \
                -e 'IMAGE_NAME=/path/to/your/image' \
                -e 'SRC_DIR=/home/devsecops/src' \
                -e 'REPORTS_DIR=/home/devsecops/reports' \
                devsecops-suite-tools:latest /bin/bash -c '/home/devsecops/run_tools.sh gitleaks'
        "
        exit 1
        ;;
esac
