#!/bin/bash
# ==========================================================================
# SKRIP PEMBERSIHAN VM - bersihkan_vm.sh (versi Pertemuan 8)
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: mengembalikan VM ke kondisi bersih sebelum Pertemuan 8:
#         1) menghapus sisa praktikum P3-P6 (folder, laporan, skrip lama)
#         2) menghapus Docker beserta semua container, image, dan volume
#         Setelah skrip ini, siswa menginstal Docker lagi dari nol.
#         Image yang sudah di-push ke Docker Hub TIDAK ikut terhapus.
#
# Skrip ini adalah versi otomatis dari Bagian A jobsheet Pertemuan 8.
# Cara jalankan : bash bersihkan_vm.sh
# ==========================================================================

echo "=========================================================="
echo " PEMBERSIHAN VM SEBELUM PERTEMUAN 8"
echo "=========================================================="
echo ""
echo "Kondisi VM saat ini:"
echo "----------------------------------------------------------"
if command -v docker >/dev/null 2>&1; then
  echo "Docker    : $(docker --version 2>/dev/null)"
else
  echo "Docker    : tidak terpasang"
fi
echo "Isi folder home:"
ls -1 "$HOME"
echo "----------------------------------------------------------"
echo ""
echo "PERHATIAN! Skrip ini akan MENGHAPUS PERMANEN:"
echo "  - Docker beserta SEMUA container, image, volume, dan network"
echo "  - data WordPress Pertemuan 5"
echo "  - folder ~/wordpress-compose, file laporan_*.txt, dan cek_*.sh"
echo ""
echo "Pastikan laporan & screenshot P5-P6 SUDAH diunggah ke Moodle."
echo "Image Anda di Docker Hub TIDAK akan terhapus."
echo ""
read -p "Ketik YA (huruf besar) untuk melanjutkan: " KONFIRMASI
if [ "$KONFIRMASI" != "YA" ]; then
  echo "Dibatalkan. Tidak ada yang dihapus."
  exit 0
fi

echo ""
echo "[1/5] Menghapus folder dan file praktikum lama..."
rm -rf "$HOME/wordpress-compose"
rm -f "$HOME"/laporan_*.txt "$HOME"/cek_*.sh

echo ""
echo "Folder yang masih tersisa di home:"
ls -1 "$HOME"
echo ""
echo "Jika masih ada folder praktikum P4/P6 dengan nama lain,"
read -p "ketik namanya (pisahkan spasi), atau tekan Enter untuk lewati: " FOLDER_LAIN
for f in $FOLDER_LAIN; do
  case "$f" in
    ""|"."|".."|/*|*..*|.*)
      echo "  Lewati '$f' (nama tidak diizinkan)"
      ;;
    *)
      if [ -e "$HOME/$f" ]; then
        rm -rf "$HOME/$f"
        echo "  Terhapus: ~/$f"
      else
        echo "  Tidak ditemukan: ~/$f"
      fi
      ;;
  esac
done

echo "[2/5] Menghentikan layanan Docker..."
sudo systemctl stop docker.socket docker containerd >/dev/null 2>&1

echo "[3/5] Menghapus paket Docker..."
for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
           docker-compose-plugin docker-ce-rootless-extras \
           docker.io docker-doc docker-compose docker-compose-v2 \
           podman-docker containerd runc; do
  sudo apt-get purge -y "$pkg" >/dev/null 2>&1
done
sudo apt-get autoremove -y >/dev/null 2>&1

echo "[4/5] Menghapus data Docker, repo apt Docker, dan login lama..."
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc /etc/apt/keyrings/docker.gpg
rm -rf "$HOME/.docker"

echo "[5/5] Verifikasi hasil..."
echo ""
echo "=========================================================="
echo " HASIL PEMBERSIHAN"
echo "=========================================================="
if command -v docker >/dev/null 2>&1; then
  echo "Docker : MASIH TERPASANG - hubungi guru"
else
  echo "Docker : sudah terhapus"
fi
echo "----------------------------------------------------------"
df -h / | awk 'NR==1 || NR==2'
echo "=========================================================="
echo "VM bersih. Lanjutkan ke Bagian B jobsheet (instalasi Docker)."
echo "=========================================================="

# Hapus skrip ini sendiri agar home benar-benar bersih
rm -f "$0"
