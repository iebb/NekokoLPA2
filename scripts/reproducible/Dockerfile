# Both base images are public, pinned Linux amd64 manifests.
FROM rust:1.99.1-bookworm@sha256:0097cc72a939f26665ab11380e995aa9476735ec9516867e14ff5dfa8318b068 AS rust
FROM ghcr.io/cirruslabs/flutter@sha256:0a9de3b70b5b7b921a346eb2793e363dc22280849a4fd690d9dde99ce1c2b1b8

ENV FLUTTER_VERSION=3.47.2
ENV CARGO_HOME=/usr/local/cargo RUSTUP_HOME=/usr/local/rustup
COPY --from=rust /usr/local/cargo /usr/local/cargo
COPY --from=rust /usr/local/rustup /usr/local/rustup
ENV PATH=/usr/local/cargo/bin:$PATH \
    CI=true TZ=UTC LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true \
    CARGOKIT_TOOLCHAIN=1.99.1 CARGOKIT_REPRODUCIBLE=1

# Pin Flutter to the commit behind the public 3.47.2 tag, not a moving branch.
RUN rm -rf /sdks/flutter/bin/cache \
    && git -C /sdks/flutter fetch --depth 1 origin d3b14c876900e553bc736ca19295fc09e3853e8e \
    && git -C /sdks/flutter checkout --detach d3b14c876900e553bc736ca19295fc09e3853e8e \
    && flutter --disable-analytics \
    && flutter precache --android \
    && sdkmanager 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358' \
    && rustup target add --toolchain 1.99.1 aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

COPY build.sh /usr/local/bin/nlpa-community-build
ENTRYPOINT ["/usr/local/bin/nlpa-community-build"]
