# zed2_docker

Docker-based perception stack for running YOLOv8-s with a ZED2i stereo camera on a Jetson Nano. Built incrementally and tested on both an x86_64 PC and a Jetson Nano (JetPack 4.6).

## Stack

| Component | Version |
|---|---|
| OS | Ubuntu 18.04 |
| ROS | Melodic |
| CUDA | 11.8 (PC) / 10.2 (Nano, via l4t-base) |
| ZED SDK | 3.8.2 |
| ZED ROS Wrapper | v3.8.x |

## Platform matrix

| | PC (x86_64) | Jetson Nano (aarch64) |
|---|---|---|
| Base image | `ubuntu:18.04` | `nvcr.io/nvidia/l4t-base:r32.6.1` |
| CUDA | Installed via apt (11.8) | Bundled with l4t-base (10.2) |
| ZED SDK installer | `cu117/ubuntu18` | `l4t32.6/jetsons` |

## Prerequisites

### PC
- NVIDIA GPU (Compute Capability ≥ 5.0)
- NVIDIA drivers installed on host
- `nvidia-container-toolkit` installed on host
- Docker installed

### Jetson Nano
- JetPack 4.6 (L4T r32.6.1)
- `nvidia-container-toolkit` installed on host
- Docker installed

## Build

```bash
# PC
bash build.sh --version pc

# Jetson Nano
bash build.sh --version nano

# Force clean rebuild (ignores cache)
bash build.sh --version pc --clean
bash build.sh --version nano --clean
```

## Run

### PC
```bash
xhost +local:docker

docker run --rm -it \
  --gpus all \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --name zed2_docker zed2_docker bash
```

### Jetson Nano
```bash
xhost +local:docker

docker run --rm -it \
  --runtime nvidia \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --name zed2_docker zed2_docker bash
```

## Verify

Inside the container:

```bash
# Check ROS
rosversion -d                        # → melodic

# Check CUDA
nvcc --version                       # → 11.8 (PC) or 10.2 (Nano)

# Check ZED SDK
ZED_Diagnostic --version

# Check ZED camera feed (GUI)
ZED_Explorer
```

## Launch ZED ROS node

Terminal 1 — start the ZED node:
```bash
roslaunch zed_wrapper zed2.launch
```

Terminal 2 — open a second shell in the running container:
```bash
docker exec -it zed2_docker bash
```

Then visualize:
```bash
rviz                                 # 3D point cloud, depth, RGB
rosrun rqt_image_view rqt_image_view # camera feed only
```

Key topics published by the wrapper:

| Topic | Description |
|---|---|
| `/zed2/zed_node/rgb/image_rect_color` | Rectified RGB image |
| `/zed2/zed_node/depth/depth_registered` | Depth map (metres) |
| `/zed2/zed_node/point_cloud/cloud_registered` | Colour point cloud |
| `/zed2/zed_node/imu/data` | IMU data |

## Repository structure

```
zed2_docker/
├── Dockerfile      # Single file builds for both PC and Nano
├── build.sh        # Build script with --version pc|nano [--clean]
└── .dockerignore
```
