#!/bin/bash
# ==========================================================================
# AUTOGRADER PERTEMUAN 5 - cek_nilai_p5.sh
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: memvalidasi docker-compose.yml siswa dengan cara benar-benar
#         menjalankan ulang secara independen (bukan hanya cek state lama)
#
# Cara jalankan : cd ~/wordpress-compose && bash cek_nilai_p5.sh
# Prasyarat     : file docker-compose.yml ada di folder yang sama
# ==========================================================================

COMPOSE_FILE="docker-compose.yml"
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

echo "Menjalankan validasi Docker Compose... (proses ini butuh beberapa detik)"
echo ""

# Bersihkan dulu, supaya validasi selalu independen/fresh
docker compose down &>/dev/null

# C1-C4: struktur file docker-compose.yml
check "C1" "File docker-compose.yml ditemukan"                    "test -f '$COMPOSE_FILE'"
check "C2" "Ada service database (db) dengan image mysql"         "grep -qE '^\s*db:' '$COMPOSE_FILE' && grep -qi 'mysql' '$COMPOSE_FILE'"
check "C3" "Ada service wordpress dengan image wordpress"         "grep -qE '^\s*wordpress:' '$COMPOSE_FILE' && grep -qi 'image:\s*wordpress' '$COMPOSE_FILE'"
check "C4" "depends_on digunakan (wordpress bergantung ke db)"    "grep -q 'depends_on' '$COMPOSE_FILE'"
check "C5" "Volume didefinisikan untuk persistensi data database" "grep -q 'volumes:' '$COMPOSE_FILE'"

# C6: docker compose up benar-benar berhasil
UP_OK=false
if docker compose up -d &>/tmp/compose_log_p5.txt; then
  sleep 6
  UP_OK=true
fi
TOTAL=$((TOTAL + 1))
if [ "$UP_OK" = true ]; then
  printf "[LULUS] %-5s %s\n" "C6" "docker compose up -d berhasil tanpa error" >> "$TMPFILE"
  PASS=$((PASS + 1))
else
  printf "[BELUM] %-5s %s (lihat /tmp/compose_log_p5.txt)\n" "C6" "docker compose up -d berhasil tanpa error" >> "$TMPFILE"
fi

# C7: kedua service berstatus running
check "C7" "Kedua service (db & wordpress) berstatus running"     "[ \$(docker compose ps --status running --format '{{.Name}}' 2>/dev/null | wc -l) -ge 2 ]"

# C8: aplikasi WordPress benar-benar merespons
WP_PORT=$(grep -oE '\"[0-9]+:80\"' "$COMPOSE_FILE" | head -n1 | grep -oE '^[0-9]+' | tr -d '"')
WP_PORT=${WP_PORT:-8085}
check "C8" "WordPress merespons di port host ($WP_PORT)"          "curl -s localhost:$WP_PORT 2>/dev/null | grep -qi wordpress"

# Bersihkan setelah validasi (volume TIDAK dihapus, supaya data siswa tetap aman)
docker compose down &>/dev/null

NOMOR_ABSEN="belumdiisi"
read -p "Masukkan nomor absen Anda untuk pelaporan: " NOMOR_ABSEN
NOMOR_ABSEN=${NOMOR_ABSEN:-belumdiisi}

REPORT_FILE="$HOME/laporan_p5_${NOMOR_ABSEN}.txt"
SKOR=0
if [ "$TOTAL" -gt 0 ]; then
  SKOR=$(( PASS * 100 / TOTAL ))
fi

{
  echo "=========================================================="
  echo " LAPORAN VALIDASI DOCKER COMPOSE - PERTEMUAN 5"
  echo " CLOUD COMPUTING KELAS XII"
  echo "=========================================================="
  echo "Nomor Absen      : $NOMOR_ABSEN"
  echo "Waktu Pengecekan : $(date '+%d-%m-%Y %H:%M:%S')"
  echo "--------------------------------------------------------"
  echo "DETAIL HASIL PENGECEKAN OTOMATIS ($TOTAL task):"
  echo "--------------------------------------------------------"
  cat "$TMPFILE"
  echo "--------------------------------------------------------"
  echo "SKOR PERTEMUAN 5 : $PASS / $TOTAL task lulus ($SKOR%)"
  echo "=========================================================="
  echo "CATATAN: Autograder ini benar-benar menjalankan ulang"
  echo "docker-compose.yml Anda secara independen (docker compose"
  echo "down lalu up lagi), jadi hasilnya mencerminkan apakah file"
  echo "Anda BENAR-BENAR bisa dipakai dari kondisi bersih."
  echo "Volume data TIDAK dihapus oleh autograder ini."
  echo "Upload docker-compose.yml + laporan ini ke Moodle."
  echo "=========================================================="
} > "$REPORT_FILE"

rm -f "$TMPFILE"

echo ""
echo "Selesai! Laporan tersimpan di: $REPORT_FILE"
echo "Skor Pertemuan 5: $PASS / $TOTAL ($SKOR%)"
echo ""
cat "$REPORT_FILE"
