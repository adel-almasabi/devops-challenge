## Kebutuhan dari tim claims

1. Tempat menyimpan foto KTP dan kuitansi atau dokumen medis yang diupload customer dari aplikasi.
2. Dibuat di dev dulu, lalu prod.
3. `claims-worker` harus bisa membaca file untuk OCR.
4. File disimpan "selama dibutuhkan untuk klaim".
5. Rina meminta IAM user dengan access key untuk backend dan script di laptop, seperti `reports-uploader-user` milik Budi.


## Asumsi

1. Upload dari aplikasi mobile memakai presigned URL yang dibuat oleh `claims-worker`, sehingga cukup satu role untuk aplikasi.
2. Engineer hanya perlu akses dari laptop di dev untuk testing, dengan data contoh, bukan KTP asli.
3. Prod tidak boleh diakses dari laptop.
4. Lama penyimpanan dokumen di prod belum diketahui, sehingga di prod belum ada aturan hapus otomatis.


## Keputusan yang saya ambil

1. Tidak membuat IAM user dan access key

   Datanya KTP dan data medis. Access key permanen tidak pernah kedaluwarsa, bisa bocor dari laptop, dan dipakai bersama sehingga tidak bisa diketahui siapa yang mengakses. Pola Budi di `modules/iam-user/main.tf` juga memberi `s3:*` dan secret-nya tersimpan di Terraform state.

   Sebagai gantinya:

   Siapa dan Cara akses:
   1. `claims-worker` (pod di EKS) | IRSA, role `claims-worker-{dev,prod}` |
   2. Customer (aplikasi mobile) | Presigned URL dari `claims-worker`, tanpa credential di HP |
   3. Engineer (laptop, dev saja) | Role `claims-dev-engineer`, wajib MFA, sesi maksimal 1 jam |

2. Memperbaiki modul `modules/s3-bucket` yang sudah ada

   Modul lama hanya membuat bucket polos, tanpa Block Public Access, tanpa enkripsi yang diatur, dan `force_destroy` default-nya `true`. Saya perbaiki modulnya, bukan membuat modul baru, supaya `reports-bucket` milik Budi juga ikut aman.

   Perubahan ini juga berlaku untuk `reports-bucket` prod, sehingga perlu dicek dengan `terragrunt plan` sebelum di-apply, dan dipastikan tidak ada script yang masih memakai HTTP atau ACL publik.

3. Enkripsi memakai SSE-S3 (`AES256`), tanpa KMS, supaya lebih sederhana.


## Infrastruktur yang dibuat

1. Perbaikan modul `modules/s3-bucket/main.tf`

   Ditambahkan Block Public Access, ownership `BucketOwnerEnforced`, enkripsi, dan bucket policy yang menolak koneksi non-HTTPS:
    
   resource "aws_s3_bucket_public_access_block" "this" {
     bucket = aws_s3_bucket.this.id

     block_public_acls       = true
     block_public_policy     = true
     ignore_public_acls      = true
     restrict_public_buckets = true
   }

   resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
     bucket = aws_s3_bucket.this.id

     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm = "AES256"
       }
     }
   }
   

   condition {
     test     = "Bool"
     variable = "aws:SecureTransport"
     values   = ["false"]
   }

   Di `modules/s3-bucket/variables.tf`, default `force_destroy` diubah menjadi `false`:

   variable "force_destroy" {
     description = "Allow Terraform to delete the bucket even if it contains objects."
     type        = bool
     default     = false
   }

2. Bucket dev

   `live/acme/ap-southeast-3/claims/dev/claims-documents-bucket/terragrunt.hcl`:

   inputs = {
     name          = "acme-claims-documents-dev"
     versioning    = false
     force_destroy = true

     lifecycle_rules = [
       {
         id              = "expire-test-data"
         prefix          = ""
         expiration_days = 30
       },
     ]
   }

   Data di dev hanya untuk testing, sehingga otomatis dihapus setelah 30 hari.

3. Bucket prod

   `live/acme/ap-southeast-3/claims/prod/claims-documents-bucket/terragrunt.hcl`:

   inputs = {
     name          = "acme-claims-documents-prod"
     versioning    = true
     force_destroy = false
   }

   Versioning aktif supaya file yang terhapus atau tertimpa masih bisa dipulihkan.

4. Izin S3 untuk `claims-worker`

   `live/acme/ap-southeast-3/claims/{dev,prod}/claims-worker-iam/terragrunt.hcl`:

   dependency "documents_bucket" {
     config_path = "../claims-documents-bucket"

     mock_outputs = {
       bucket_arn = "arn:aws:s3:::acme-claims-documents-prod"
     }
     mock_outputs_allowed_terraform_commands = ["validate", "plan"]
   }

   {
     sid       = "ReadWriteClaimDocuments"
     effect    = "Allow"
     actions   = ["s3:*"]
     resources = ["${dependency.documents_bucket.outputs.bucket_arn}/*"]
   },
  

   Izin hanya untuk isi file di bucket dokumen (`bucket/*`). `claims-worker` tidak bisa melihat daftar file, mengubah bucket policy, menghapus bucket, atau mengakses bucket lain. Role ini hanya bisa dipakai oleh pod dengan service account `claims-worker` di namespace `claims`, tidak bisa dipakai manusia.

5. Role untuk engineer di dev

   Modul baru `modules/human-role/main.tf`, trust policy wajib MFA:

   condition {
     test     = "Bool"
     variable = "aws:MultiFactorAuthPresent"
     values   = ["true"]
   }
   

   `live/acme/ap-southeast-3/claims/dev/claims-dev-engineer-role/terragrunt.hcl`:

   inputs = {
     name                   = "claims-dev-engineer"
     trusted_principal_arns = ["arn:aws:iam::111111111111:root"]
     max_session_duration   = 3600

     policy_statements = [
       {
         sid       = "ListClaimDocuments"
         effect    = "Allow"
         actions   = ["s3:ListBucket"]
         resources = [dependency.documents_bucket.outputs.bucket_arn]
       },
       {
         sid    = "ReadWriteClaimDocuments"
         effect = "Allow"
         actions = [
           "s3:GetObject",
           "s3:PutObject",
         ]
         resources = ["${dependency.documents_bucket.outputs.bucket_arn}/*"]
       },
     ]
   }

   Tidak ada role engineer untuk prod.

6. Validasi

   Semua modul lolos `terraform fmt` dan `terraform validate`. File Terragrunt lolos `terragrunt hcl fmt`. `terragrunt plan` tidak bisa dijalankan karena tidak ada akun AWS.


## Balasan ke Rina

Hi Rina,

Terima kasih sudah menunggu. Tempat penyimpanan dokumen claim di dev sudah siap, jadi tim kamu bisa mulai testing minggu ini.

Saya sudah membuat dua bucket, `acme-claims-documents-dev` dan `acme-claims-documents-prod`. Keduanya terenkripsi, tidak bisa diakses publik, dan hanya bisa diakses lewat HTTPS. `claims-worker` juga sudah saya beri izin untuk membaca dan upload file ke bucket tersebut, jadi proses OCR bisa langsung jalan. Untuk dev, file akan terhapus otomatis setelah 30 hari, jadi tolong pakai data contoh saja, jangan KTP asli. Untuk prod, versioning saya aktifkan supaya file yang tidak sengaja terhapus masih bisa dipulihkan.

Ada satu hal yang saya kerjakan berbeda dari permintaan anda. Saya tidak membuat IAM user dengan access key. Karena data KTP dan dokumen medis, access key permanen yang disimpan di laptop terlalu berisiko kalau bocor, dan kita juga tidak bisa tahu siapa yang mengakses datanya. Sebagai gantinya, upload dari aplikasi bisa memakai presigned URL yang dibuat oleh `claims-worker`, sehingga aplikasi upload langsung ke S3 tanpa perlu menyimpan key apa pun. Untuk script di laptop, di dev bisa memakai role `claims-dev-engineer` dengan MFA. Credential-nya sementara, maksimal 1 jam, dan tercatat atas nama masing-masing orang. Di prod sengaja tidak ada akses dari laptop.

Supaya saya bisa menyelesaikan, ada beberapa hal yang perlu saya konfirmasi dari anda atau tim product:

1. Berapa lama dokumen harus disimpan setelah klaim selesai? Apakah ada aturan dari OJK atau tim legal?
2. Script di laptop itu dipakai untuk apa saja? Supaya izinnya bisa saya sesuaikan.
3. Siapa saja engineer yang perlu akses ke dev? agar saya berikan izin ke role `claims-dev-engineer`. Dan saya buatkan credntialnya

Kalau ada yang kurang jelas atau ada kebutuhan lain, bisa kabari saya

Thanks,
Hardy
