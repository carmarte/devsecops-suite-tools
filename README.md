# DevSecOps Suite Tools

Orquestación de varias herramientas OpenSource DevSecOps (Trivy, Semgrep, Syft & Grype, Gitleaks) para escaneo de vulnerabilidades tanto en repositorios como a una imagen Docker. Los reportes se generan en varios formatos JSON, SARIF y HTML.

---

## 🔧 Prerrequisitos

- [Docker Desktop](https://docs.docker.com/get-started/introduction/get-docker-desktop/)

## 🚀 Herramientas

- [Gitleaks](https://github.com/gitleaks)
- [Trivy](https://github.com/aquasecurity/trivy)
- [Semgrep](https://github.com/semgrep/semgrep)
- [Syft](https://github.com/anchore/syft)
- [Grype](https://github.com/anchore/grype)

## 🎯 Uso en local

1. Construye la imagen Docker:

    ```bash
    docker build -t devsecops-suite-tools .
    ```

2. Inicia el contenedor con el comando:

    ```bash
    docker run --rm -v /path/to/your/repo:/home/devsecops/src -v /path/to/your/reports:/home/devsecops/reports -e "IMAGE_NAME=your/image:tag" -e "SRC_DIR=/home/devsecops/src" -e "REPORTS_DIR=/home/devsecops/reports" devsecops-suite-tools:latest /bin/bash -c "/home/devsecops/run_tools.sh [tool_name]"

    # o

    docker run --rm \
        -v /path/to/your/repo:/home/devsecops/src \
        -v /path/to/your/reports:/home/devsecops/reports \
        -e "IMAGE_NAME=/path/to/your/image" \
        -e "SRC_DIR=/home/devsecops/src" \
        -e "REPORTS_DIR=/home/devsecops/reports" \
        devsecops-suite-tools:latest /bin/bash -c "/home/devsecops/run_tools.sh [tool_name]"
    ```

## 📂 Estructura del proyecto

```bash
📂 devsecops-suite-tools
│   .dockerignore
│   .gitignore
│   Dockerfile
│   README.md
│   run_tools.sh
│
└───templates
        gitleaks-html.tmpl
        grype-html.tmpl
        trivy-html.tpl
```

## ✅ Script `run_tools.sh`

Funciona como un 'entrypoint' que, dependiendo de la herramienta especificada en el comando `docker run` ejecuta el script con el análisis de vulnerabilidades correspondiente.

## 📚 Directorio `Templates\`

Contiene los templates en formato HTML para las herramientas Gitleaks, Grype y Trivy.

## 📔 Software Bill of Materials (SBOM)

Un Software Bill of Materials (SBOM) o Lista de Materiales de Software es un inventario detallado de todos los componentes que forman parte de una aplicación de software.

### 🔍 ¿Qué contiene un SBOM?

Un SBOM incluye información como:

- 📦 Nombre del componente (por ejemplo, lodash)
- 🔢 Versión (4.17.21)
- 💻 Lenguaje o ecosistema (npm, pip, maven, etc.)
- 🔗 Origen o proveedor (por ejemplo, de qué repositorio proviene)
- 📁 Ubicación dentro del proyecto
- 📄 Licencia del componente
- 🧬 Identificadores como PURL (Package URL) y CPEs (Common Platform Enumerations)

### 🎯 ¿Para qué sirve un SBOM?

- 🔒 Seguridad
  - Ayuda a detectar rápidamente si una aplicación está usando versiones vulnerables de librerías (por ejemplo, cuando se publica una CVE nueva).

- 📑 Cumplimiento legal
  - Asegura que todas las licencias de software sean compatibles con el uso comercial o de código abierto del proyecto.

- 🔍 Transparencia y trazabilidad
  - Facilita saber qué software se está utilizando, de dónde viene, y cómo fue ensamblado.

- 🔄 Gestión de dependencias
  - Permite auditar y actualizar componentes fácilmente.
