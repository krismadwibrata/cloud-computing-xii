from odoo import fields, models


class KoperasiAnggota(models.Model):
    _name = "koperasi.anggota"
    _description = "Anggota Koperasi Sekolah"
    _order = "nomor_anggota"

    name = fields.Char(string="Nama", required=True)
    kelas = fields.Char(string="Kelas")
    nomor_anggota = fields.Char(string="Nomor Anggota", required=True)
    tanggal_gabung = fields.Date(
        string="Tanggal Bergabung", default=fields.Date.context_today
    )
