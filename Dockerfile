# ─── Base (set by build.sh --version pc|nano) ────────────────────────────────
ARG BASE_IMAGE=ubuntu:18.04
FROM ${BASE_IMAGE}

# ─── Global build args ────────────────────────────────────────────────────────
ARG DEBIAN_FRONTEND=noninteractive
ARG ROS_DISTRO=melodic

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

# ─── ROS apt sources ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg2 \
        lsb-release \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
        | apt-key add - \
    && echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/ros.list \
    && rm -rf /var/lib/apt/lists/*

# ─── ROS desktop-full ─────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        ros-${ROS_DISTRO}-desktop-full \
    && rm -rf /var/lib/apt/lists/*

# ─── Perception extras ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-vision-opencv \
        ros-${ROS_DISTRO}-image-pipeline \
        ros-${ROS_DISTRO}-camera-info-manager \
        python3-opencv \
    && rm -rf /var/lib/apt/lists/*

# ─── ROS build tooling ────────────────────────────────────────────────────────
# python3-catkin-pkg conflicts with l4t-base pre-installed packages so
# we install the Python tools via pip3 instead of apt.
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-pip \
        build-essential \
    && pip3 install --no-cache-dir setuptools wheel \
    && pip3 install --no-cache-dir \
        catkin-pkg \
        rosdep \
        rosinstall \
        rosinstall-generator \
        wstool \
        catkin-tools \
    && rm -rf /var/lib/apt/lists/* \
    && rosdep init \
    && rosdep update

# ─── CUDA ─────────────────────────────────────────────────────────────────────
# pc:   installs cuda-toolkit-11-8 from NVIDIA apt repo (max for Ubuntu 18.04)
# nano: l4t-base:r32.6.1 already ships CUDA 10.2 — no install needed
RUN ARCH=$(uname -m) && echo "Detected architecture: $ARCH" && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -fsSLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.1-1_all.deb && \
        dpkg -i cuda-keyring_1.1-1_all.deb && \
        rm cuda-keyring_1.1-1_all.deb && \
        apt-get update && \
        apt-get install -y --no-install-recommends --fix-missing cuda-toolkit-11-8 && \
        rm -rf /var/lib/apt/lists/* ; \
    else \
        echo "Jetson Nano: CUDA 10.2 provided by l4t-base, skipping install." ; \
    fi

ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64

# ─── ZED SDK dependencies ────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        zstd \
        wget \
        udev \
        sudo \
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# ─── ZED SDK 3.8 ─────────────────────────────────────────────────────────────
# Both platforms use SDK 3.8.2 — same version, different installers
# pc:   cu117/ubuntu18 (CUDA 11.7 build, compatible with our CUDA 11.8)
# nano: l4t32.6/jetsons (exact match for L4T r32.6.1 / JetPack 4.6)
# skip_cuda      — CUDA already present in the image
# skip_od_module — skips ~1.5GB AI object detection models (YOLO handles detection)
# skip_drivers   — Nano only: host L4T handles hardware, not the container
RUN ARCH=$(uname -m) && echo "Installing ZED SDK 3.8 for: $ARCH" && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q -O /tmp/zed_sdk.run https://download.stereolabs.com/zedsdk/3.8/cu117/ubuntu18 && \
        chmod +x /tmp/zed_sdk.run && \
        /tmp/zed_sdk.run -- silent skip_cuda skip_od_module && \
        rm /tmp/zed_sdk.run ; \
    else \
        wget -q -O /tmp/zed_sdk.run https://download.stereolabs.com/zedsdk/3.8/l4t32.6/jetsons && \
        chmod +x /tmp/zed_sdk.run && \
        /tmp/zed_sdk.run -- silent skip_cuda skip_od_module skip_drivers && \
        rm /tmp/zed_sdk.run ; \
    fi \
    && rm -rf /usr/local/zed/resources/*

ENV ZED_SDK_ROOT=/usr/local/zed
ENV PATH=${ZED_SDK_ROOT}/tools:${PATH}
ENV LD_LIBRARY_PATH=${ZED_SDK_ROOT}/lib:${LD_LIBRARY_PATH}

# ─── Environment ──────────────────────────────────────────────────────────────
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/bash.bashrc

ENV ROS_DISTRO=${ROS_DISTRO}

# ─── ZED ROS Wrapper ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/catkin_ws/src \
    && cd /root/catkin_ws/src \
    && git clone --recursive --branch v3.8.x \
        https://github.com/stereolabs/zed-ros-wrapper.git

RUN /bin/bash -c "\
    source /opt/ros/${ROS_DISTRO}/setup.bash \
    && cd /root/catkin_ws \
    && rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} \
    && catkin_make -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
        -DCUDA_CUDART_LIBRARY=/usr/local/cuda/lib64/stubs \
        -DCMAKE_CXX_FLAGS='-Wl,--allow-shlib-undefined'"

RUN echo "source /root/catkin_ws/devel/setup.bash" >> /etc/bash.bashrc

# ─── Default shell with ROS sourced ───────────────────────────────────────────
SHELL ["/bin/bash", "-c"]
CMD ["bash"]
