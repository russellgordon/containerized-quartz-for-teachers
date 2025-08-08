# Use a slim Node+Python base image
FROM python:3.11-slim

# Install Python package for frontmatter parsing
RUN pip install python-frontmatter

# Install Node.js (needed for Quartz) and other tools
RUN apt-get update && apt-get install -y curl git lsof \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone Quartz v4.5.0 into /opt/quartz
WORKDIR /opt
RUN git clone --branch v4.5.0 https://github.com/jackyzha0/quartz.git quartz

# Copy patched Quartz components into place
COPY patches/Explorer.tsx /opt/quartz/quartz/components/Explorer.tsx
COPY patches/explorer.inline.ts /opt/quartz/quartz/components/scripts/explorer.inline.ts

# Copy Quartz scaffold to /opt/quartz-site
RUN cp -r /opt/quartz /opt/quartz-site

# Copy in setup_course.py, build_site.py
COPY scripts/setup_course.py /opt/scripts/setup_course.py
COPY scripts/build_site.py /opt/scripts/build_site.py

# Copy course metadata lookup file into container
COPY support/ /opt/support/

# Set default working directory
WORKDIR /teaching

# Default command
CMD ["/bin/bash"]
