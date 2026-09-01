#!/bin/bash
# ==========================================================================
# AUTOGRADER TANTANGAN PERTEMUAN 4 - cek_tantangan_p4.sh
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: memvalidasi 3 dari 4 tantangan + bonus (Tantangan 4 dinilai manual
#         karena berupa penalaran tertulis, bukan artefak yang bisa dijalankan)
#
# Cara jalankan : bash ~/cek_tantangan_p4.sh
# Prasyarat     : ikuti penamaan image/container/port persis seperti
#                 disebutkan di lembar soal tantangan
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

echo "Menjalankan validasi tantangan... (proses ini butuh beberapa detik)"
echo ""

# ==========================================================================
# TANTANGAN 1 - Ganti Port

# ==========================================================================
docker rm -f tantangan1-container &>/dev/null
T1_RUN=false
if docker run -d --name tantangan1-container -p 8000:8000 aplikasi-saya:port8000 &>/dev/null; then
  sleep 3
  T1_RUN=true
fi
check "T1a" "Image aplikasi-saya:port8000 berhasil dijalankan"          "[ '$T1_RUN' = true ]"
check "T1b" "Aplikasi merespons di port 8000 (port baru)"              "curl -s localhost:8000 2>/dev/null | grep -qi hello"
check "T1c" "Aplikasi TIDAK merespons di port 5000 (port lama)"        "! curl -s -m 2 localhost:5000 2>/dev/null | grep -qi hello"
docker stop tantangan1-container &>/dev/null
docker rm tantangan1-container &>/dev/null

# ==========================================================================
# TANTANGAN 2 - Pesan via Environment Variable
# ==========================================================================
docker rm -f tantangan2-container &>/dev/null
PESAN_UNIK="TES_OTOMATIS_$(date +%s)"
T2_RUN=false
if docker run -d --name tantangan2-container -p 5002:5000 -e PESAN="$PESAN_UNIK" aplikasi-saya:env &>/dev/null; then
  sleep 3
  T2_RUN=true
fi
check "T2a" "Image aplikasi-saya:env berhasil dijalankan dengan -e PESAN" "[ '$T2_RUN' = true ]"
check "T2b" "Pesan custom ($PESAN_UNIK) benar-benar muncul di response"   "curl -s localhost:5002 2>/dev/null | grep -q '$PESAN_UNIK'"
docker stop tantangan2-container &>/dev/null
docker rm tantangan2-container &>/dev/null

# ==========================================================================
# TANTANGAN 3 - Perbaiki Dockerfile yang Rusak
# ==========================================================================
T3DIR="$HOME/tantangan3"
docker rm -f tantangan3-container &>/dev/null
docker rmi -f tantangan3-fix &>/dev/null
check "T3a" "Folder ~/tantangan3 berisi Dockerfile hasil perbaikan"     "test -f '$T3DIR/Dockerfile'"
T3_BUILD=false
if [ -f "$T3DIR/Dockerfile" ]; then
  if (cd "$T3DIR" && docker build -t tantangan3-fix . &>/tmp/build_log_t3.txt); then
    T3_BUILD=true
  fi
fi
check "T3b" "Dockerfile hasil perbaikan berhasil di-build tanpa error" "[ '$T3_BUILD' = true ]"
T3_RUN=false
if [ "$T3_BUILD" = true ] && docker run -d --name tantangan3-container -p 5003:5000 tantangan3-fix &>/dev/null; then
  sleep 3
  T3_RUN=true
fi
check "T3c" "Container hasil perbaikan berjalan & merespons"          "[ '$T3_RUN' = true ] && curl -s localhost:5003 2>/dev/null | grep -qi hello"
docker stop tantangan3-container &>/dev/null
docker rm tantangan3-container &>/dev/null

# ==========================================================================
# BONUS - Tambah Fitur (endpoint /fitur-baru, isi bebas)
# ==========================================================================
docker rm -f bonus-container &>/dev/null
BONUS_RUN=false
if docker run -d --name bonus-container -p 5004:5000 aplikasi-saya:bonus &>/dev/null; then
  sleep 3
  BONUS_RUN=true
fi
check "BON" "Endpoint /fitur-baru merespons (HTTP 200) di image bonus" "[ '$BONUS_RUN' = true ] && curl -s -o /dev/null -w '%{http_code}' localhost:5004/fitur-baru | grep -q 200"
docker stop bonus-container &>/dev/null
docker rm bonus-container &>/dev/null

NOMOR_ABSEN="belumdiisi"
read -p "Masukkan nomor absen Anda untuk pelaporan: " NOMOR_ABSEN
NOMOR_ABSEN=${NOMOR_ABSEN:-belumdiisi}

REPORT_FILE="$HOME/laporan_tantangan_p4_${NOMOR_ABSEN}.txt"
SKOR=0
if [ "$TOTAL" -gt 0 ]; then
  SKOR=$(( PASS * 100 / TOTAL ))
fi

{
  echo "=========================================================="
  echo " LAPORAN TANTANGAN PERTEMUAN 4 - CLOUD COMPUTING KELAS XII"
  echo "=========================================================="
  echo "Nomor Absen      : $NOMOR_ABSEN"
  echo "Waktu Pengecekan : $(date '+%d-%m-%Y %H:%M:%S')"
  echo "--------------------------------------------------------"
  echo "DETAIL HASIL PENGECEKAN OTOMATIS ($TOTAL task):"
  echo "--------------------------------------------------------"
  cat "$TMPFILE"
  echo "--------------------------------------------------------"
  echo "SKOR TANTANGAN (OTOMATIS) : $PASS / $TOTAL task lulus ($SKOR%)"
  echo "=========================================================="
  echo "CATATAN: Tantangan 4 (Optimasi Build Cache) TIDAK dicek di"
  echo "sini - itu soal penalaran tertulis, dinilai manual oleh guru"
  echo "dari jawaban yang Anda tulis. Pastikan jawaban Tantangan 4"
  echo "ikut di-submit terpisah (teks/dokumen) ke Moodle."
  echo "=========================================================="
} > "$REPORT_FILE"

rm -f "$TMPFILE"

echo ""
echo "Selesai! Laporan tersimpan di: $REPORT_FILE"
echo "Skor tantangan (otomatis): $PASS / $TOTAL ($SKOR%)"
echo "(Ingat: Tantangan 4 dinilai terpisah secara manual)"
echo ""
cat "$REPORT_FILE"
