# Lightweight container environment for testing dbscripts shell, Python, and Perl tools
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        coreutils \
        curl \
        findutils \
        gawk \
        grep \
        iproute2 \
        openssl \
        perl \
        pigz \
        procps \
        python3 \
        python3-yaml \
        sed \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r -g 1000 tester \
    && useradd -r -u 1000 -g tester -m -s /bin/bash tester

WORKDIR /workspace
USER tester

CMD ["bash", "docker/script_tests/run_all_script_tests.sh"]
