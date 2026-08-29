#!/bin/bash
# ==========================================================================
# AUTOGRADER TRANSFER TEST - cek_nilai_transfer.sh
# Mata Pelajaran: Cloud Computing - Kelas XII SMK
# Fungsi: mengecek 11 task uji praktik transfer (Pertemuan 2)
#         Task ini SENGAJA tidak diberi command tertulis ke siswa,
#         untuk menguji pemahaman konsep, bukan hafalan urutan ketik.
#
# Lokasi wajib   : ~/autograder/cek_nilai_transfer.sh
# Cara jalankan  : bash ~/autograder/cek_nilai_transfer.sh
# ==========================================================================

WORKDIR="$HOME/ujian_transfer"
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

check "T1"  "Folder ujian_transfer + subfolder arsip & sementara dibuat" "test -d '$WORKDIR/arsip' && test -d '$WORKDIR/sementara'"
check "T2"  "File arsip/laporan.txt dibuat, minimal 3 baris"             "[ \$(wc -l < '$WORKDIR/arsip/laporan.txt' 2>/dev/null || echo 0) -ge 3 ]"
check "T3"  "File sementara/laporan_final.txt ada (copy+rename)"         "test -f '$WORKDIR/sementara/laporan_final.txt'"
check "T4"  "File laporan_final.txt dapat ditemukan (implisit via T3)"   "test -f '$WORKDIR/sementara/laporan_final.txt'"
check "T5"  "Permission laporan_final.txt sudah 640"                     "[ \"\$(stat -c '%a' '$WORKDIR/sementara/laporan_final.txt' 2>/dev/null)\" = '640' ]"
check "T6"  "User user_ujian dibuat & jadi anggota group ujiankelas"      "id user_ujian &>/dev/null && getent group ujiankelas | grep -q user_ujian"
check "T7"  "Owner laporan_final.txt sudah milik user_ujian"             "[ \"\$(stat -c '%U' '$WORKDIR/sementara/laporan_final.txt' 2>/dev/null)\" = 'user_ujian' ]"
check "T8"  "Package tree terinstal"                                     "command -v tree"
check "T9"  "ping_ujian.txt menunjukkan ping ke 1.1.1.1 berhasil"        "test -s '$HOME/ping_ujian.txt' && grep -q '0% packet loss' '$HOME/ping_ujian.txt'"
check "T10" "dns_ujian.txt berisi hasil resolusi DNS github.com"         "test -s '$HOME/dns_ujian.txt' && grep -qi 'Address' '$HOME/dns_ujian.txt'"

SUBMISSION_FILE=$(ls "$HOME" 2>/dev/null | grep -E '^ujian_[0-9]+_selesai\.txt$' | head -n 1)
check "T11" "File ujian_[absen]_selesai.txt dibuat & berisi identitas"   "[ -n '$SUBMISSION_FILE' ] && test -s '$HOME/$SUBMISSION_FILE'"

NOMOR_ABSEN="belumdiisi"
NAMA_SISWA="(nama belum terdeteksi - pastikan task T11 sudah dikerjakan)"
if [ -n "$SUBMISSION_FILE" ]; then
  NOMOR_ABSEN=$(echo "$SUBMISSION_FILE" | grep -oE '[0-9]+')
  NAMA_SISWA=$(cat "$HOME/$SUBMISSION_FILE" 2>/dev/null)
fi

REPORT_FILE="$HOME/laporan_transfer_${NOMOR_ABSEN}.txt"
SKOR=0
if [ "$TOTAL" -gt 0 ]; then
  SKOR=$(( PASS * 100 / TOTAL ))
fi

{
  echo "=========================================================="
  echo " LAPORAN UJI PRAKTIK TRANSFER - CLOUD COMPUTING KELAS XII"
  echo "=========================================================="
  echo "Nama / Identitas : $NAMA_SISWA"
  echo "Nomor Absen      : $NOMOR_ABSEN"
  echo "Waktu Pengecekan : $(date '+%d-%m-%Y %H:%M:%S')"
  echo "--------------------------------------------------------"
  echo "DETAIL HASIL PENGECEKAN OTOMATIS ($TOTAL task):"
  echo "--------------------------------------------------------"
  cat "$TMPFILE"
  echo "--------------------------------------------------------"
  echo "SKOR TRANSFER TEST : $PASS / $TOTAL task lulus ($SKOR%)"
  echo "=========================================================="
  echo "CATATAN: Tes ini menguji pemahaman konsep tanpa contoh"
  echo "perintah tertulis. Upload laporan ini ke Moodle sesuai"
  echo "instruksi guru."
  echo "=========================================================="
} > "$REPORT_FILE"

rm -f "$TMPFILE"

echo ""
echo "Selesai! Laporan tersimpan di: $REPORT_FILE"
echo "Skor transfer test: $PASS / $TOTAL ($SKOR%)"
echo ""
cat "$REPORT_FILE"
