FROM golang:1.22.4 AS golang-builder

# 更新包列表并安装编译 dlib 所需的依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    ca-certificates \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libgtk-3-dev \
    libatlas-base-dev \
    gfortran \
    libopencv-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 克隆 dlib 并编译安装
RUN git clone --depth=1 https://github.com/davisking/dlib.git /dlib \
    && cd /dlib \
    && mkdir build \
    && cd build \
    && cmake .. \
    && cmake --build . --config Release \
    && make install \
    && ldconfig \
    && rm -rf /dlib  # 清理构建文件

# 删除不需要的编译工具和清理系统
RUN apt-get remove -y build-essential cmake git wget curl \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

