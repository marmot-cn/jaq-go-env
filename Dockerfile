FROM golang:1.22.4

# 更新包列表并安装编译 OpenCV 和 dlib 所需的依赖，包括 unzip
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    ca-certificates \
    unzip \
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
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 下载并编译 OpenCV，并确保包含 Aruco 模块，禁用 AVX512 优化
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/4.10.0.zip \
    && unzip opencv.zip \
    && cd opencv-4.10.0 \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=Release \
             -D CMAKE_INSTALL_PREFIX=/usr/local \
             -D OPENCV_ENABLE_NONFREE=ON \
             -D BUILD_opencv_aruco=ON \
             -D CPU_BASELINE_DISABLE=AVX512 .. \
    && make -j$(nproc) \
    && make install \
    && ldconfig

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

# 删除不需要的编译工具和清理系统，但保留 OpenCV 开发文件
RUN apt-get remove -y build-essential cmake git wget curl \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/*

# 添加 Go 项目代码并编译
ADD . /application
WORKDIR /application

# 编译 Go 应用
RUN go build -buildmode=pie -o server cmd/main.go && \
    go build -o smokeTest utils/smoke/smoke.go && \
    go build -o cronRun utils/cron/cron_run.go
