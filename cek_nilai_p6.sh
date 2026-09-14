#!/bin/bash
# ==========================================================================
# AUTOGRADER PERTEMUAN 6 - cek_nilai_p6.sh
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: memvalidasi image benar-benar ter-push & PUBLIC di Docker Hub,
#         lewat API publik Docker Hub + pull independen (bukan cuma cek
#         klaim siswa)
#
# Cara jalankan : bash cek_nilai_p6.sh
# ==========================================================================

TMPFILE=$(mktemp)
PASS=0
TOTAL=0

check() {
  local id="$1"
  local desc="$2"
  local cmd="$3"
  TOTAL=$((TOTAL + 1))
  if eval "$cmd" &>/dev/null; then
    printf "[LULUS] %-5s %s\n" "$id" "$desc" >> "$TMPFILE"
    PASS=$((PASS + 1))
  else
    printf "[BELUM] %-5s %s\n" "$id" "$desc" >> "$TMPFILE"
  fi
}

echo "=========================================================="
echo " AUTOGRADER PERTEMUAN 6 - CONTAINER REGISTRY"
echo "=========================================================="
read -p "Masukkan username Docker Hub Anda      : " DH_USER
read -p "Masukkan nama repo aplikasi-saya (mis. aplikasi-saya): " DH_REPO
read -p "Masukkan nama repo TUGAS TRANSFER (Bagian E)         : " DH_REPO2
echo ""
echo "Menjalankan validasi... (proses ini butuh waktu, ada proses pull dari internet)"
echo ""

# ==========================================================================
# BAGIAN UTAMA: aplikasi-saya
# ==========================================================================

# R1: cek via Docker Hub API publik bahwa repo ada & PUBLIC
check "R1" "Repository $DH_USER/$DH_REPO ditemukan & PUBLIC di Docker Hub" \
  "curl -s https://hub.docker.com/v2/repositories/$DH_USER/$DH_REPO/ | grep -q '\"is_private\":false'"

# R2: docker pull independen (hapus dulu image lokal kalau ada, supaya bukti murni dari registry)
docker rmi -f "$DH_USER/$DH_REPO:latest" &>/dev/null
docker rmi -f "$DH_USER/$DH_REPO" &>/dev/null
PULL_OK=false
if docker pull "$DH_USER/$DH_REPO" &>/dev/null; then
  PULL_OK=true
fi
check "R2" "Image berhasil di-pull ulang dari Docker Hub (independen)" "[ '$PULL_OK' = true ]"

# R3: jalankan hasil pull, verifikasi benar-benar merespons
RUN_OK=false
if [ "$PULL_OK" = true ]; then
  docker rm -f registry-test-container &>/dev/null
  if docker run -d --name registry-test-container -p 5098:5000 "$DH_USER/$DH_REPO" &>/dev/null; then
    sleep 3
    RUN_OK=true
  fi
fi
check "R3" "Container hasil pull berjalan & merespons" \
  "[ '$RUN_OK' = true ] && curl -s localhost:5098 2>/dev/null | grep -qi hello"
docker stop registry-test-container &>/dev/null
docker rm registry-test-container &>/dev/null

# ==========================================================================
# BAGIAN E: TUGAS TRANSFER (tanpa panduan)
# ==========================================================================

# R4: cek repo kedua juga public di Docker Hub (bukti tugas transfer benar-benar dikerjakan)
check "R4" "Repository transfer $DH_USER/$DH_REPO2 ditemukan & PUBLIC di Docker Hub" \
  "curl -s https://hub.docker.com/v2/repositories/$DH_USER/$DH_REPO2/ | grep -q '\"is_private\":false'"

NOMOR_ABSEN="belumdiisi"
read -p "Masukkan nomor absen Anda untuk pelaporan: " NOMOR_ABSEN
NOMOR_ABSEN=${NOMOR_ABSEN:-belumdiisi}

REPORT_FILE="$HOME/laporan_p6_${NOMOR_ABSEN}.txt"
SKOR=0
if [ "$TOTAL" -gt 0 ]; then
  SKOR=$(( PASS * 100 / TOTAL ))
fi

{
  echo "=========================================================="
  echo " LAPORAN VALIDASI CONTAINER REGISTRY - PERTEMUAN 6"
  echo " CLOUD COMPUTING KELAS XII"
  echo "=========================================================="
  echo "Nomor Absen        : $NOMOR_ABSEN"
  echo "Username Docker Hub: $DH_USER"
  echo "Repo Utama         : $DH_REPO"
  echo "Repo Transfer      : $DH_REPO2"
  echo "Waktu Pengecekan   : $(date '+%d-%m-%Y %H:%M:%S')"
  echo "--------------------------------------------------------"
  echo "DETAIL HASIL PENGECEKAN OTOMATIS ($TOTAL task):"
  echo "--------------------------------------------------------"
  cat "$TMPFILE"
  echo "--------------------------------------------------------"
  echo "SKOR PERTEMUAN 6 : $PASS / $TOTAL task lulus ($SKOR%)"
  echo "=========================================================="
  echo "CATATAN: R1 & R4 dicek langsung ke Docker Hub API publik"
  echo "(bukan klaim Anda), R2-R3 dibuktikan dengan menghapus"
  echo "image lokal lalu pull ulang murni dari registry."
  echo "Upload laporan ini + 4 screenshot ke Moodle."
  echo "=========================================================="
} > "$REPORT_FILE"

rm -f "$TMPFILE"

echo ""
echo "Selesai! Laporan tersimpan di: $REPORT_FILE"
echo "Skor Pertemuan 6: $PASS / $TOTAL ($SKOR%)"
echo ""
cat "$REPORT_FILE"
