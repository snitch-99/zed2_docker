#!/bin/bash
set -e

usage() {
    echo "Usage: bash build.sh --version [pc|nano]"
    echo "  --version pc    Build for x86_64 PC (ubuntu:20.04 + CUDA 12.6)"
    echo "  --version nano  Build for Jetson Nano (l4t-base:r32.6.1 + CUDA 10.2)"
    exit 1
}

# ─── Parse args ───────────────────────────────────────────────────────────────
VERSION=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then
    echo "Error: --version is required"
    usage
fi

# ─── Select base image ────────────────────────────────────────────────────────
case $VERSION in
    pc)
        BASE_IMAGE="ubuntu:20.04"
        echo "Building for PC (x86_64) — base: $BASE_IMAGE"
        ;;
    nano)
        BASE_IMAGE="nvcr.io/nvidia/l4t-base:r32.6.1"
        echo "Building for Jetson Nano (aarch64) — base: $BASE_IMAGE"
        ;;
    *)
        echo "Error: unknown version '$VERSION'"
        usage
        ;;
esac

# ─── Build ────────────────────────────────────────────────────────────────────
docker build --build-arg BASE_IMAGE="$BASE_IMAGE" -t zed2_docker .
