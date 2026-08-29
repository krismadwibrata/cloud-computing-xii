#!/bin/bash
# ==========================================================================
# AUTOGRADER PERTEMUAN 4 - cek_nilai_p4.sh
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: memvalidasi Dockerfile siswa dengan cara benar-benar build & run
#         ulang secara independen (bukan hanya cek state yang sudah ada)
#
# Cara jalankan : bash ~/cek_nilai_p4.sh
# Prasyarat     : folder ~/aplikasi-saya berisi Dockerfile, app.py,
#                 requirements.txt (sesuai Jobsheet Bagian A & B)
# ==========================================================================

APPDIR="$HOME/aplikasi-saya"
TEST_IMAGE="validasi-p4-image"
TEST_CONTAINER="validasi-p4-container"
TEST_PORT="5099"
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

# Bersihkan sisa validasi sebelumnya (kalau ada), supaya hasil selalu independen/fresh
docker rm -f "$TEST_CONTAINER" &>/dev/null
docker rmi -f "$TEST_IMAGE" &>/dev/null

# F1: folder & file yang dibutuhkan ada
check "F1" "Folder ~/aplikasi-saya berisi Dockerfile"        "test -f '$APPDIR/Dockerfile'"
check "F2" "File app.py ada"                                  "test -f '$APPDIR/app.py'"
check "F3" "File requirements.txt ada"                        "test -f '$APPDIR/requirements.txt'"

# F4-F6: cek instruksi dasar ada di dalam Dockerfile (struktur minimal)
if [ -f "$APPDIR/Dockerfile" ]; then
  check "F4" "Dockerfile memiliki instruksi FROM"              "grep -qi '^FROM' '$APPDIR/Dockerfile'"
  check "F5" "Dockerfile memiliki instruksi COPY"              "grep -qi '^COPY' '$APPDIR/Dockerfile'"
  check "F6" "Dockerfile memiliki instruksi CMD"               "grep -qi '^CMD' '$APPDIR/Dockerfile'"
else
  TOTAL=$((TOTAL + 3))
  printf "[BELUM] %-5s %s\n" "F4" "Dockerfile memiliki instruksi FROM" >> "$TMPFILE"
  printf "[BELUM] %-5s %s\n" "F5" "Dockerfile memiliki instruksi COPY" >> "$TMPFILE"
  printf "[BELUM] %-5s %s\n" "F6" "Dockerfile memiliki instruksi CMD" >> "$TMPFILE"
fi

# F7: docker build benar-benar berhasil (bukan cuma dicek filenya, tapi DIBANGUN ULANG)
BUILD_OK=false
if [ -f "$APPDIR/Dockerfile" ]; then
  if (cd "$APPDIR" && docker build -t "$TEST_IMAGE" . &>/tmp/build_log_p4.txt); then
    BUILD_OK=true
  fi
fi
TOTAL=$((TOTAL + 1))
if [ "$BUILD_OK" = true ]; then
  printf "[LULUS] %-5s %s\n" "F7" "docker build berhasil tanpa error" >> "$TMPFILE"
  PASS=$((PASS + 1))
else
  printf "[BELUM] %-5s %s (lihat /tmp/build_log_p4.txt untuk detail error)\n" "F7" "docker build berhasil tanpa error" >> "$TMPFILE"
fi

# F8: container bisa dijalankan dari image hasil build tadi
RUN_OK=false
if [ "$BUILD_OK" = true ]; then
  if docker run -d --name "$TEST_CONTAINER" -p "$TEST_PORT":5000 "$TEST_IMAGE" &>/dev/null; then
    sleep 3
    RUN_OK=true
  fi
fi
TOTAL=$((TOTAL + 1))
if [ "$RUN_OK" = true ]; then
  printf "[LULUS] %-5s %s\n" "F8" "Container berhasil dijalankan dari image" >> "$TMPFILE"
  PASS=$((PASS + 1))
else
  printf "[BELUM] %-5s %s\n" "F8" "Container berhasil dijalankan dari image" >> "$TMPFILE"
fi

# F9: aplikasi merespons & bisa diakses lewat curl
TOTAL=$((TOTAL + 1))
if [ "$RUN_OK" = true ] && curl -s "localhost:$TEST_PORT" 2>/dev/null | grep -qi "hello\|docker"; then
  printf "[LULUS] %-5s %s\n" "F9" "Aplikasi merespons & bisa diakses lewat curl" >> "$TMPFILE"
  PASS=$((PASS + 1))
else
  printf "[BELUM] %-5s %s\n" "F9" "Aplikasi merespons & bisa diakses lewat curl" >> "$TMPFILE"
fi

# Bersihkan container & image hasil validasi (tidak mengganggu container asli milik siswa)
docker stop "$TEST_CONTAINER" &>/dev/null
docker rm "$TEST_CONTAINER" &>/dev/null
docker rmi "$TEST_IMAGE" &>/dev/null

NOMOR_ABSEN="belumdiisi"
read -p "Masukkan nomor absen Anda untuk pelaporan: " NOMOR_ABSEN
NOMOR_ABSEN=${NOMOR_ABSEN:-belumdiisi}

REPORT_FILE="$HOME/laporan_p4_${NOMOR_ABSEN}.txt"
SKOR=0
if [ "$TOTAL" -gt 0 ]; then
  SKOR=$(( PASS * 100 / TOTAL ))
fi

{
  echo "=========================================================="
  echo " LAPORAN VALIDASI DOCKERFILE - PERTEMUAN 4"
  echo " CLOUD COMPUTING KELAS XII"
  echo "=========================================================="
  echo "Nomor Absen      : $NOMOR_ABSEN"
  echo "Waktu Pengecekan : $(date '+%d-%m-%Y %H:%M:%S')"
  echo "--------------------------------------------------------"
  echo "DETAIL HASIL PENGECEKAN OTOMATIS ($TOTAL task):"
  echo "--------------------------------------------------------"
  cat "$TMPFILE"
  echo "--------------------------------------------------------"
  echo "SKOR PERTEMUAN 4 : $PASS / $TOTAL task lulus ($SKOR%)"
  echo "=========================================================="
  echo "CATATAN: Autograder ini benar-benar membangun ulang image"
  echo "dari Dockerfile Anda secara independen (bukan hanya cek"
  echo "container yang sudah ada), jadi hasilnya mencerminkan"
  echo "apakah Dockerfile Anda BENAR-BENAR bisa dipakai dari nol."
  echo "Upload Dockerfile + laporan ini ke Moodle sesuai instruksi guru."
  echo "=========================================================="
} > "$REPORT_FILE"

rm -f "$TMPFILE"

echo ""
echo "Selesai! Laporan tersimpan di: $REPORT_FILE"
echo "Skor Pertemuan 4: $PASS / $TOTAL ($SKOR%)"
echo ""
cat "$REPORT_FILE"
