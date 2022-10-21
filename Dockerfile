FROM hexpm/elixir:1.13.4-erlang-25.0.2-alpine-3.16.0

ENV XLA_TARGET=cpu

ENV BAZEL_VERSION="5.3.0" \
    BAZEL_SHA256SUM="ee801491ff0ec3a562422322a033c9afe8809b64199e4a94c7433d4e14e6b921  bazel-5.3.0-dist.zip" \
    JAVA_HOME="/usr/lib/jvm/default-jvm"

RUN apk update && apk upgrade && \
    apk add --no-cache libstdc++ openjdk11 && \
    apk add --no-cache --virtual build-dependencies bash curl git wget musl-dev make libexecinfo libexecinfo-dev coreutils gcc g++ linux-headers unzip zip && \
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sLO https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip && \
    echo ${BAZEL_SHA256SUM} | sha256sum --check && \    
    unzip bazel-${BAZEL_VERSION}-dist.zip && \
    ./compile.sh && \
    cp ${DIR}/output/bazel /usr/local/bin/ && \
    rm -rf ${DIR} && \
    apk del build-dependencies

RUN apk add --update --no-cache python3 py3-pip python3-dev
RUN ln -s /usr/bin/python3 /usr/bin/python && \
    python -m pip install --upgrade pip numpy

COPY . /xla
# ENTRYPOINT [ "/docker-entrypoint.sh" ]
