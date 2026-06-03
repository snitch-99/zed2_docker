#!/bin/bash
set -e

usage() {
    echo "Usage: bash build.sh --version [pc|nano] [--clean]"
    echo "  --version pc    Build for x86_64 PC (ubuntu:18.04 + CUDA 11.8)"
    echo "  --version nano  Build for Jetson Nano (l4t-base:r32.6.1 + CUDA 10.2)"
    echo "  --clean         Force a full rebuild ignoring cache"
    exit 1
}

# ─── Parse args ───────────────────────────────────────────────────────────────
VERSION=""
CLEAN=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift ;;
        --clean)   CLEAN="--no-cache" ;;
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
        BASE_IMAGE="ubuntu:18.04"
        ROS_DISTRO="melodic"
        echo "Building for PC (x86_64)    — base: $BASE_IMAGE | ROS: $ROS_DISTRO"
        ;;
    nano)
        BASE_IMAGE="nvcr.io/nvidia/l4t-base:r32.6.1"
        ROS_DISTRO="melodic"
        echo "Building for Jetson Nano    — base: $BASE_IMAGE | ROS: $ROS_DISTRO"
        ;;
    *)
        echo "Error: unknown version '$VERSION'"
        usage
        ;;
esac

# ─── Build ────────────────────────────────────────────────────────────────────
docker build $CLEAN \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg ROS_DISTRO="$ROS_DISTRO" \
    -t zed2_docker .
