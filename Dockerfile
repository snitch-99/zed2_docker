# ─── Base (set by build.sh --version pc|nano) ────────────────────────────────
ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

# ─── Global build args ────────────────────────────────────────────────────────
ARG DEBIAN_FRONTEND=noninteractive

# ─── Locale ───────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ─── apt retry config (handles transient network failures) ────────────────────
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80retries

# ─── ROS Noetic apt sources ───────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg2 \
        lsb-release \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
        | apt-key add - \
    && echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/ros-noetic.list \
    && rm -rf /var/lib/apt/lists/*

# ─── ROS Noetic desktop-full ──────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        ros-noetic-desktop-full \
    && rm -rf /var/lib/apt/lists/*

# ─── Perception extras ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-noetic-vision-opencv \
        ros-noetic-image-pipeline \
        ros-noetic-camera-info-manager \
        python3-opencv \
    && rm -rf /var/lib/apt/lists/*

# ─── ROS build tooling ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool \
        python3-catkin-tools \
        build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && rosdep init \
    && rosdep update

# ─── CUDA ─────────────────────────────────────────────────────────────────────
# pc:   installs cuda-toolkit-12-6 from NVIDIA apt repo
# nano: l4t-base:r32.6.1 already ships CUDA 10.2 — no install needed
RUN ARCH=$(uname -m) && echo "Detected architecture: $ARCH" && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -fsSLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.1-1_all.deb && \
        dpkg -i cuda-keyring_1.1-1_all.deb && \
        rm cuda-keyring_1.1-1_all.deb && \
        apt-get update && \
        apt-get install -y --no-install-recommends --fix-missing cuda-toolkit-12-6 && \
        rm -rf /var/lib/apt/lists/* ; \
    else \
        echo "Jetson Nano: CUDA 10.2 provided by l4t-base, skipping install." ; \
    fi

ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64

# ─── Environment ──────────────────────────────────────────────────────────────
RUN echo "source /opt/ros/noetic/setup.bash" >> /etc/bash.bashrc

ENV ROS_DISTRO=noetic

# ─── Default shell with ROS sourced ───────────────────────────────────────────
SHELL ["/bin/bash", "-c"]
CMD ["bash"]
