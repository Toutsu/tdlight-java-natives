#!/bin/bash -e
# MAIN REQUIRED ENVIRONMENT VARIABLES:
#   OPERATING_SYSTEM_NAME = <windows | linux | osx>
#   CPU_ARCHITECTURE_NAME = <amd64 | aarch64 | 386 | armv6 | armv7 | ppc64le>
#   IMPLEMENTATION_NAME = <tdlib | tdlight>
#   BUILD_TYPE = <Debug | Release | RelWithDebInfo | MinSizeRel>
#   CPU_CORES = "-- -j<cores>" or "-m" on Windows
# OTHER REQUIRED ENVIRONMENT VARIABLES:
#   CMAKE_EXTRA_ARGUMENTS = <args>

# Check variables correctness
if [ -z "${OPERATING_SYSTEM_NAME}" ]; then
	echo "Missing parameter: OPERATING_SYSTEM_NAME"
	exit 1
fi
if [ -z "${CPU_ARCHITECTURE_NAME}" ]; then
	echo "Missing parameter: CPU_ARCHITECTURE_NAME"
	exit 1
fi
if [ -z "${IMPLEMENTATION_NAME}" ]; then
	echo "Missing parameter: IMPLEMENTATION_NAME"
	exit 1
fi
if [ -z "${BUILD_TYPE}" ]; then
	echo "Missing parameter: BUILD_TYPE"
	exit 1
fi
if [ -z "${CPU_CORES}" ]; then
	echo "Missing parameter: CPU_CORES"
	exit 1
fi

source ./setup-variables.sh

cd ../../
ROOT_DIR="$(pwd)"

# Print details
echo "Installing dependencies..."
echo "Current directory: $ROOT_DIR"
echo "Operating system: ${OPERATING_SYSTEM_NAME}"
echo "Architecture: ${CPU_ARCHITECTURE_NAME}"
echo "Td implementation: ${IMPLEMENTATION_NAME}"
echo "Build type: ${BUILD_TYPE}"
echo "CPU cores count: ${CPU_CORES}"
echo "CMake extra arguments: '${CMAKE_EXTRA_ARGUMENTS}'"

CROSS_OPENJDK_PATH=""
fix_jdk_path() {
  # Setup OpenJDK path
  CROSS_OPENJDK_PATH="$(find "$CROSS_BUILD_DEPS_DIR/usr/lib/jvm/" -maxdepth 1 -type d -iname "java*jdk*" | head -n 1)"
}

check_jdk_existance() {
  if [[ ! -d "$CROSS_OPENJDK_PATH" ]]; then
    echo "Can't find cross OpenJDK at location $CROSS_OPENJDK_PATH"
    exit 1
  fi
}

if [[ "$OPERATING_SYSTEM_NAME" == "linux" ]]; then
  fix_jdk_path
  if [[ ! -f "$CROSS_BUILD_DEPS_DIR/ok-012" ]]; then
    rm -rf "$CROSS_BUILD_DEPS_DIR" || true
    mkdir -p "$CROSS_BUILD_DEPS_DIR"
    sudo dpkg --add-architecture "${CPU_ARCH_DPKG}"
    sudo apt-get update || true
    sudo apt-get install -y "libstdc++-11-dev-${CPU_ARCH_DPKG}-cross" \
      "crossbuild-essential-${CPU_ARCH_DPKG}" "libstdc++-11-pic-${CPU_ARCH_DPKG}-cross"
    cd "$CROSS_BUILD_DEPS_DIR"
    # LibZ-Dev
    apt-get download "zlib1g-dev:${CPU_ARCH_DPKG}"
    ZLIB1G_DEV_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "zlib1g-dev*.deb" | head -n 1)"
    dpkg -x "$ZLIB1G_DEV_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$ZLIB1G_DEV_DEB"
    # LibZ
    apt-get download "zlib1g:${CPU_ARCH_DPKG}"
    ZLIB1G_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "zlib1g*.deb" | head -n 1)"
    dpkg -x "$ZLIB1G_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$ZLIB1G_DEB"
    # LibSSL-Dev
    apt-get download "libssl-dev:${CPU_ARCH_DPKG}"
    LIBSSL_DEV_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "libssl-dev*.deb" | head -n 1)"
    dpkg -x "$LIBSSL_DEV_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$LIBSSL_DEV_DEB"
    # LibSSL
    apt-get download "libssl1.1:${CPU_ARCH_DPKG}"
    LIBSSL_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "libssl1.1*.deb" | head -n 1)"
    dpkg -x "$LIBSSL_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$LIBSSL_DEB"
    # Java Common
    apt-get download "java-common"
    JC_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "java-common*.deb" | head -n 1)"
    dpkg -x "$JC_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$JC_DEB"
    # OpenJDK-JRE-Headless
    apt-get download "openjdk-11-jre-headless:${CPU_ARCH_DPKG}"
    OJDKRH_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "openjdk-11-jre-headless*.deb" | head -n 1)"
    dpkg -x "$OJDKRH_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$OJDKRH_DEB"
    # OpenJDK-JRE
    apt-get download "openjdk-11-jre:${CPU_ARCH_DPKG}"
    OJDKR_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "openjdk-11-jre*.deb" | head -n 1)"
    dpkg -x "$OJDKR_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$OJDKR_DEB"
    # OpenJDK-JDK
    apt-get download "openjdk-11-jdk-headless:${CPU_ARCH_DPKG}"
    OJDKJ_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "openjdk-11-jdk-headless*.deb" | head -n 1)"
    dpkg -x "$OJDKJ_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$OJDKJ_DEB"
    # OpenJDK-GUI
    apt-get download "openjdk-11-jdk:${CPU_ARCH_DPKG}"
    OJDKG_DEB="$(find "$CROSS_BUILD_DEPS_DIR" -maxdepth 1 -type f -iname "openjdk-11-jdk*.deb" | head -n 1)"
    dpkg -x "$OJDKG_DEB" "$CROSS_BUILD_DEPS_DIR"
    rm "$OJDKG_DEB"

    # Fix symlinks
    find "$CROSS_BUILD_DEPS_DIR" -lname "/*" \
        -exec  sh -c "ln -sf \"\`echo \"$CROSS_BUILD_DEPS_DIR\$(readlink \$0)\"\`\" \"\$0\"" {} \;

    # Check if openjdk is found
    fix_jdk_path
    check_jdk_existance

    touch "$CROSS_BUILD_DEPS_DIR/ok-012"
  fi

  check_jdk_existance

  # Create toolchain
  echo "Creating toolchain file..."
  cd "$ROOT_DIR"
  {
    echo "set(CMAKE_SYSTEM_PROCESSOR ${CPU_ARCH_CMAKE})";
    echo "set(CMAKE_C_COMPILER ${CPU_ARCH_CMAKE}-linux-gnu-gcc)";
    echo "set(CMAKE_C_COMPILER_TARGET ${CLANG_TRIPLE})";
    echo "set(CMAKE_CXX_COMPILER ${CPU_ARCH_CMAKE}-linux-gnu-g++)";
    echo "set(CMAKE_CXX_COMPILER_TARGET ${CLANG_TRIPLE})";
    echo "set(CMAKE_ASM_COMPILER ${CPU_ARCH_CMAKE}-linux-gnu-g++)";
    echo "set(CMAKE_ASM_COMPILER_TARGET ${CLANG_TRIPLE})";
    echo "set(CMAKE_LIBRARY_PATH \"$CROSS_BUILD_DEPS_DIR/\")";
    #echo "include_directories(\"${CROSS_BUILD_DEPS_DIR}\")";
    #echo "include_directories(\"${CROSS_BUILD_DEPS_DIR}/usr/include/\")";
    echo "include_directories(\"${CROSS_BUILD_DEPS_DIR}/usr/include/${CPU_ARCH_CMAKE}-linux-gnu/\")";
    echo "include_directories(\"${CROSS_OPENJDK_PATH}/include\")";
    echo "include_directories(\"${CROSS_OPENJDK_PATH}/include/linux\")";
    #echo "set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES \"$CROSS_BUILD_DEPS_DIR/usr/include/\" \"${CROSS_BUILD_DEPS_DIR}/usr/include/${CPU_ARCH_CMAKE}-linux-gnu/\")";

    echo "SET(CMAKE_FIND_ROOT_PATH \"$CROSS_BUILD_DEPS_DIR\" \"$JAVA_HOME\")";
    #echo "SET(JAVA_HOME \"$CROSS_OPENJDK_PATH\")";
    echo "SET(JAVA_INCLUDE_PATH \"$CROSS_OPENJDK_PATH/include\")";
    echo "SET(JAVA_INCLUDE_PATH2 \"$CROSS_OPENJDK_PATH/include/linux\")";
    echo "SET(JAVA_JVM_LIBRARY \"$CROSS_OPENJDK_PATH/lib/server/libjvm.so\")";
    echo "SET(JAVA_AWT_LIBRARY \"$CROSS_OPENJDK_PATH/lib/libawt.so\")";
    echo "SET(JNI_INCLUDE_DIRS \"$CROSS_OPENJDK_PATH/include\" \"$CROSS_OPENJDK_PATH/include/linux\")";
    echo "SET(JNI_LIBRARIES \"$CROSS_OPENJDK_PATH/lib/server/libjvm.so\" \"$CROSS_OPENJDK_PATH/lib/libawt.so\")";
    echo "SET(JNI_FOUND True)";
    echo "MESSAGE(STATUS \"JNI INCLUDE DIRS: \${JNI_INCLUDE_DIRS}\")";
    echo "MESSAGE(STATUS \"JNI LIBS: \${JNI_LIBRARIES}\")";
    #echo "SET(JAVA_AWT_LIBRARY \"$CROSS_OPENJDK_PATH\")";
    #echo "SET(JAVA_JVM_LIBRARY \"$CROSS_OPENJDK_PATH\")";
    #echo "SET(JAVA_AWT_INCLUDE_PATH \"$CROSS_OPENJDK_PATH\")";
    cat <<EOF
SET(CMAKE_SYSTEM_NAME Linux)

# Use our definitions for compiler tools
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search for libraries and headers in the target directories only
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF
   if [[ ${CPU_ARCHITECTURE_NAME} == "aarch64" || ${CPU_ARCHITECTURE_NAME} == "armv6" || ${CPU_ARCHITECTURE_NAME} == "armv7" ]]; then
     cat <<EOF
set(CMAKE_THREAD_LIBS_INIT "-lpthread")
set(CMAKE_HAVE_THREADS_LIBRARY 1)
set(CMAKE_USE_WIN32_THREADS_INIT 0)
set(CMAKE_USE_PTHREADS_INIT 1)
set(THREADS_PREFER_PTHREAD_FLAG ON)
EOF
    fi
  } > "$CROSS_BUILD_DEPS_DIR/toolchain.cmake"

fi;

echo "Done."
exit 0