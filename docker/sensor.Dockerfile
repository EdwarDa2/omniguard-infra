FROM debian:bookworm-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config libpcap-dev libhiredis-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY omniguard-sensor-cpp/CMakeLists.txt ./
COPY omniguard-sensor-cpp/include ./include
COPY omniguard-sensor-cpp/src ./src
COPY omniguard-sensor-cpp/test ./test

RUN cmake -S . -B build -DBUILD_TESTS=ON \
    && cmake --build build -j"$(nproc)" \
    && ctest --test-dir build --output-on-failure

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpcap0.8 libhiredis0.14 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/build/omniguard-sensor /usr/local/bin/omniguard-sensor

ENTRYPOINT ["omniguard-sensor"]
