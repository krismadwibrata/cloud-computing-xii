# Pertemuan 8 - Odoo Koperasi Sekolah

File pendukung praktikum Pertemuan 8 (Docker Hub: rilis, deploy, rollback).

| Folder | Isi |
|---|---|
| `v1.0/koperasi_smk` | Addon Odoo 18 versi 1.0: data anggota koperasi (nomor, nama, kelas, tanggal bergabung) |
| `v1.1/koperasi_smk` | Addon versi 1.1: menambahkan field **Saldo Simpanan** |

Addon disalin ke dalam image dengan Dockerfile milik siswa:

```dockerfile
FROM odoo:18
COPY --chown=odoo:odoo ./koperasi_smk /mnt/extra-addons/koperasi_smk
```

Lihat perbedaan kedua versi:

```bash
diff -r v1.0/koperasi_smk v1.1/koperasi_smk
```

Panduan lengkap ada di jobsheet Pertemuan 8.
