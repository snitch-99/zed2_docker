# ─── Base ────────────────────────────────────────────────────────────────────
FROM ubuntu:20.04

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

# ─── Environment ──────────────────────────────────────────────────────────────
RUN echo "source /opt/ros/noetic/setup.bash" >> /etc/bash.bashrc

ENV ROS_DISTRO=noetic

# ─── Default shell with ROS sourced ───────────────────────────────────────────
SHELL ["/bin/bash", "-c"]
CMD ["bash"]
