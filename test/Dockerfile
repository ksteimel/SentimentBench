FROM julia:latest

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
        autoconf \
        build-essential \
        git \
        mc \
        nano \
        curl \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add Distributed   ;precompile");using Distributed'
RUN julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add DataStructures;precompile");using DataStructures'
RUN julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add SparseArrays ;precompile");using SparseArrays'

WORKDIR /projects
