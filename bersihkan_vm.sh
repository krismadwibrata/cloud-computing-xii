#!/bin/bash
# ==========================================================================
# SKRIP PEMBERSIHAN VM - bersihkan_vm.sh
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: membersihkan sisa praktikum P3-P6 (container, image, volume,
#         network, build cache, folder & laporan lama) sebelum Pertemuan 8.
#         Docker TETAP terpasang. Image di Docker Hub TIDAK ikut terhapus.
#
# Cara jalankan : bash bersihkan_vm.sh
# ==========================================================================

echo "=========================================================="
echo " PEMBERSIHAN VM SEBELUM PERTEMUAN 8"
echo "=========================================================="
echo ""
echo "Kondisi VM saat ini:"
echo "----------------------------------------------------------"
echo "Container : $(docker ps -aq 2>/dev/null | wc -l)"
echo "Image     : $(docker images -q 2>/dev/null | wc -l)"
echo "Volume    : $(docker volume ls -q 2>/dev/null | wc -l)"
echo "Isi folder home:"
ls -1 "$HOME"
echo "----------------------------------------------------------"
echo ""
echo "PERHATIAN! Skrip ini akan MENGHAPUS PERMANEN:"
echo "  - semua container, image, volume, network, dan build cache"
echo "  - data WordPress Pertemuan 5"
echo "  - folder ~/wordpress-compose, file laporan_p*.txt, dan cek_*.sh"
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
echo "[1/6] Menghapus semua container..."
CONTAINERS=$(docker ps -aq)
if [ -n "$CONTAINERS" ]; then
  docker rm -f $CONTAINERS >/dev/null
fi

echo "[2/6] Menghapus semua image, network, dan build cache..."
docker system prune -a -f >/dev/null

echo "[3/6] Menghapus semua volume..."
VOLUMES=$(docker volume ls -q)
if [ -n "$VOLUMES" ]; then
  docker volume rm $VOLUMES >/dev/null
fi

echo "[4/6] Menghapus folder dan file praktikum lama..."
rm -rf "$HOME/wordpress-compose"
rm -f "$HOME"/laporan_p*.txt "$HOME"/laporan_transfer*.txt "$HOME"/cek_*.sh

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

echo "[5/6] Logout dari Docker Hub..."
docker logout >/dev/null 2>&1

echo "[6/6] Verifikasi hasil..."
echo ""
echo "=========================================================="
echo " HASIL PEMBERSIHAN"
echo "=========================================================="
echo "Container tersisa : $(docker ps -aq | wc -l)"
echo "Image tersisa     : $(docker images -q | wc -l)"
echo "Volume tersisa    : $(docker volume ls -q | wc -l)"
echo "----------------------------------------------------------"
df -h / | awk 'NR==1 || NR==2'
echo "=========================================================="
echo "VM siap untuk Pertemuan 8. Lanjutkan dengan:"
echo "  docker load -i odoo18.tar"
echo "=========================================================="

# Hapus skrip ini sendiri agar home benar-benar bersih
rm -f "$0"
