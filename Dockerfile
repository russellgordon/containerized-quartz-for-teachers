# Use a slim Node+Python base image
FROM python:3.11-slim

# Install Python package for frontmatter parsing
RUN pip install python-frontmatter

# Install Node.js (needed for Quartz) and other tools (incl. dos2unix)
RUN apt-get update && apt-get install -y curl git lsof dos2unix \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone Quartz v4.5.0 into /opt/quartz
WORKDIR /opt
RUN git clone --branch v4.5.0 https://github.com/jackyzha0/quartz.git quartz

# Copy patched Quartz components into place
COPY patches/Explorer.tsx /opt/quartz/quartz/components/Explorer.tsx
COPY patches/FolderContent.tsx /opt/quartz/quartz/components/pages/FolderContent.tsx
COPY patches/explorer.inline.ts /opt/quartz/quartz/components/scripts/explorer.inline.ts

# Copy Quartz scaffold to /opt/quartz-site
RUN cp -r /opt/quartz /opt/quartz-site

# Copy in setup_course.py, build_site.py, deploy.py
COPY scripts/setup_course.py /opt/scripts/setup_course.py
COPY scripts/build_site.py /opt/scripts/build_site.py
COPY scripts/deploy.py /opt/scripts/deploy.py

# Copy course metadata lookup & other support files into container
COPY support/ /opt/support/

# --- Bake launcher scripts for export ---
RUN mkdir -p /opt/export
COPY setup.sh preview.sh deploy.sh /opt/export/
COPY setup.bat preview.bat deploy.bat /opt/export/
# Ensure .sh are executable (no-op on .bat)
RUN chmod +x /opt/export/*.sh || true
# Convert Windows launchers to CRLF line endings
RUN unix2dos /opt/export/*.bat

# --- Helper command to export scripts to a mounted folder ---
# Usage (macOS/Linux):   docker run --rm -v "$PWD":/out <image> export-scripts
# Usage (Windows PowerShell): docker run --rm -v "${PWD}:/out" <image> export-scripts
RUN cat >/usr/local/bin/export-scripts <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DEST="/out"
if [ ! -d "$DEST" ]; then
  echo "❌ No /out mount found. Run with:  -v \"$PWD\":/out"
  exit 1
fi
cp -f /opt/export/* "$DEST"/
chmod +x "$DEST"/*.sh || true
echo "✅ Exported scripts to $DEST:" && ls -1 "$DEST" | sed 's/^/   - /'
EOF
RUN chmod +x /usr/local/bin/export-scripts

# Set default working directory
WORKDIR /teaching

# Default command
CMD ["/bin/bash"]

