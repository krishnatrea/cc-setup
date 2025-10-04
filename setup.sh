#!/usr/bin/env bash
# ============================================================
# i686-elf Cross Compiler Setup for Ubuntu 24.04.3 LTS
# Author: Harshit Sharma
# ============================================================

set -e

# -------- CONFIGURATION --------
PREFIX="$HOME/cross"
TARGET="i686-elf"
BINUTILS_VER="2.42"
GCC_VER="14.2.0"
NPROC=$(nproc)

# -------- INSTALL DEPENDENCIES --------
echo "📦 Installing required packages..."
sudo apt update
sudo apt install -y \
  build-essential bison flex libgmp-dev libmpfr-dev libmpc-dev \
  libisl-dev texinfo wget python3 pkg-config

# Optional for testing the kernel:
sudo apt install -y qemu-system-x86

# -------- CREATE FOLDERS --------
echo "📁 Creating directories..."
mkdir -p "$PREFIX/src" "$PREFIX/build-binutils" "$PREFIX/build-gcc"

cd "$PREFIX/src"

# -------- DOWNLOAD SOURCES --------
echo "🌐 Downloading sources..."
wget -nc https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz
wget -nc https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz

echo "📦 Extracting..."
tar -xf binutils-${BINUTILS_VER}.tar.xz
tar -xf gcc-${GCC_VER}.tar.xz

# -------- BUILD BINUTILS --------
echo "🔧 Building binutils..."
cd "$PREFIX/build-binutils"
../src/binutils-${BINUTILS_VER}/configure \
  --target=$TARGET \
  --prefix="$PREFIX" \
  --with-sysroot \
  --disable-nls \
  --disable-werror
make -j"$NPROC"
make install

# -------- BUILD GCC --------
echo "🔧 Preparing GCC..."
cd "$PREFIX/src/gcc-${GCC_VER}"
./contrib/download_prerequisites

echo "🔧 Building GCC..."
cd "$PREFIX/build-gcc"
../src/gcc-${GCC_VER}/configure \
  --target=$TARGET \
  --prefix="$PREFIX" \
  --disable-nls \
  --enable-languages=c,c++ \
  --without-headers \
  --disable-multilib
make all-gcc -j"$NPROC"
make install-gcc
make all-target-libgcc -j"$NPROC"
make install-target-libgcc

# -------- PATH SETUP --------
if ! grep -q "$PREFIX/bin" ~/.bashrc; then
  echo 'export PATH="$HOME/cross/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$PREFIX/bin:$PATH"

# -------- VERIFY --------
echo "✅ Installation complete!"
echo "Checking compiler version:"
i686-elf-gcc --version
i686-elf-ld --version

echo ""
echo "👉 Add to PATH manually for current shell if needed:"
echo "   export PATH=\"$PREFIX/bin:\$PATH\""
echo ""
echo "You can now compile bare-metal kernels using:"
echo "   i686-elf-gcc -ffreestanding -nostdlib -m32 ..."
echo "   i686-elf-ld ..."
echo ""
