
## Find the root cause
1. Melihat health check ke semua server yang ada atau yang dicurigai, apakah ada server yang unhealthy, atau resource penuh sepeti CPU, RAM, Disk, dan koneksi. Jika ada resource yang penuh, memriksa service yang memakan rosource.
2. Memeriksa status service, adakah yang unhealthy atau tidak runnong
Command (systemctl list-units --type=service --state=active, systemctl status <nama_service>, journalctl -u <nama_service>, docker ps -a, docker inspect <nama_atau_id_container>, kubectl get pods, kubectl get svc, kubectl get nodes, kubectl describe pod <nama_pod>, pm2 list, pm2 describe <nama_atau_id_aplikasi>, supervisorctl status)
3. Melihat log service, container, dan pod yang dicurigai brmasalah.
Command (journalctl -u <nama_service>, docker logs <nama_atau_id_container>, kubectl logs <nama_pod> -c <nama_container>)
4. Melihat status, dan kesehatan database
(Resouece database, connection database, slow query, Lock Wait dan Deadlock, Replication Lag dan status replikasi)
5. Melihat status queue jika memakai kafka atau rabbitmq seperti kafka lag / consumer lag, Queue Depth
6. Melihat status trakhir perubahan seperti : 
(pipeline history, commit history, audit trial di cloud)
7. Menganalisa error log, dan mengikuti log sampai ketemu dengan akar masalah
8. Fix problem
    a. Jika resource melihat service apa yang memakan resource, jika memungkinkan menaikan rosource Vertical Scaling atau Horizontal Scaling dan menghubngi service owner, untuk fix problem
    b. Jika enpoint tidak respon, menelusuri endpint dari DNS, sampai service yang dicurigai
    c. Jika error code, melakukan rollback ke versi terakhir jika memungkinkan, atau menghubungi service ownner, untuk fix problem
    d. Jika database, melihat query bermasalah heavy query, jika memungkinkan untuk di kill seperti select quey lakukan kill, Jika tidak menghubungi service owner untuk optimalisasi. Jika DB connection menambahkan nilai db connectiion, atau fix problem idle connection bersama service owner.
9. Verifikasi service telah kembali normal
    a. Melihat status service telah kembali up atau healthy
    b. Melihat log aplikasi di service tidak ditemukan eror yang sebelum nya terjadi
    c. Membuaka enpoint di pastikan respon 200.
    d. Meminta tolong qa team atau service owner untuk mencoba kembali layanan, apakah sudah recovery


## Masalah yang saya temukan di repository ini

1. Helm values

   `apps/acme-prod-cluster/values/claims-worker.yaml` baris 6:
 
   serviceAccount:
     name: claims-worker-sa        # ← nama baru
     roleArn: arn:aws:iam::111111111111:role/claims-worker-prod
      

2. Konfigurasi Terragrunt

   `live/acme/ap-southeast-3/claims/prod/claims-worker-iam/terragrunt.hcl`:
 
   inputs = {
     name              = "claims-worker-prod"
     oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
     namespace         = "claims"
     service_account   = "claims-worker"   # ← masih menggunakan nama lama

     policy_statements = [
       {
         sid       = "Queue"
         effect    = "Allow"
         actions   = ["sqs:*"]
         resources = ["*"]
       },
     ]
   }
      

3. Kenapa mengganti nama service account bisa membuat error?

   Di dalam `modules/irsa-role/main.tf` terdapat:
 
   condition {
     test     = "StringEquals"
     variable = "${local.oidc_issuer}:sub"
     values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
   }

   Sehingga setelah service account diganti namanya menjadi `claims-worker-sa`, pod ditolak saat assume role.

4. Masalah alert tidak berjalan

   `modules/sqs-queue/variables.tf` sudah menyediakan variabel `alarm_actions`, tetapi default-nya kosong:
  
   variable "alarm_actions" {
     description = "ARNs to notify when the alarm changes state."
     type        = list(string)
     default     = []   # ← kosong, tidak ada yang dinotifikasi
   }
      
   `live/acme/ap-southeast-3/claims/prod/claims-documents-queue/terragrunt.hcl` tidak ada `alarm_actions`:
 
   inputs = {
     name                        = "claims-documents"
     visibility_timeout_seconds  = 300
     max_receive_count           = 5
     alarm_age_threshold_seconds = 900
     # ← alarm_actions tidak ditambahkan
   }
      

   **Yang harus ditambahkan:** SNS topic sebagai tujuan notifikasi, lalu ARN-nya dimasukkan ke `alarm_actions`.

   a. Membuat Modul baru `modules/sns-topic/main.tf`:

   resource "aws_sns_topic" "this" {
     name = var.name
     tags = var.tags
   }

   resource "aws_sns_topic_subscription" "email" {
     for_each  = toset(var.email_subscribers)
     topic_arn = aws_sns_topic.this.arn
     protocol  = "email"
     endpoint  = each.value
   }
      
   `modules/sns-topic/variables.tf`:
      
   variable "name" {
     description = "SNS topic name."
     type        = string
   }

   variable "email_subscribers" {
     description = "Email addresses receive alarm."
     type        = list(string)
     default     = []
   }

   variable "tags" {
     type        = map(string)
     default     = {}
   }
      
   `modules/sns-topic/outputs.tf`:
      
   output "topic_arn" {
     value = aws_sns_topic.this.arn
   }
      
   b. Stack baru `live/acme/ap-southeast-3/claims/prod/claims-alerts/terragrunt.hcl`:
    
   include "root" {
     path = find_in_parent_folders()
   }

   terraform {
     source = "${get_repo_root()}/modules//sns-topic"
   }

   inputs = {
     name              = "claims-alerts-prod"
     email_subscribers = ["tian6889@gmail.com"]
   }
      
   c. Ubah `live/acme/ap-southeast-3/claims/prod/claims-documents-queue/terragrunt.hcl`:
      
   dependency "alerts" {
     config_path = "../claims-alerts"

     mock_outputs = {
       topic_arn = "arn:aws:sns:ap-southeast-3:111111111111:claims-alerts-prod"
     }
     mock_outputs_allowed_terraform_commands = ["validate", "plan"]
   }

   inputs = {
     name                        = "claims-documents"
     visibility_timeout_seconds  = 300
     max_receive_count           = 5
     alarm_age_threshold_seconds = 900
     alarm_actions               = [dependency.alerts.outputs.topic_arn]   # ← baru
   }
      
   Alur setelah perubahan: Jika antrean menumpuk → AWS CloudWatch alarm ALARM → SNS topic `claims-alerts-prod` → email ke `tian6889@gmail.com`. Karena modul juga memakai `ok_actions = var.alarm_actions`, email juga dikirim saat alarm kembali ke status OK.



## Postmortem

   Judul: Dokumen klaim tidak diproses karena claims-worker tidak bisa mengakses SQS
   Tanggal: 13–14 Oktober 2026
   Status: Resolved
   Sumber data : /incient/evidence/

   ### Ringkasan

   Pada 13 Oktober pukul 17:38 WIB, service account `claims-worker` di prod diganti namanya menjadi `claims-worker-sa`. IAM role `claims-worker-prod` hanya mengizinkan nama lama, sehingga semua pod claims-worker ditolak AWS saat mengakses SQS dan crash terus-menerus. Dokumen klaim yang diupload customer tidak diproses selama sekitar 8,5 jam. Alarm sebenarnya sudah menyala, tetapi tidak terhubung ke siapa pun, sehingga masalah baru diketahui dari komplain customer.

   ### Dampak

   - Sekitar 8,5 jam (17:43 – 02:xx WIB) tidak ada dokumen klaim yang diproses.
   - 48.213 pesan tertahan di antrean `claims-documents`.
   - 40+ tiket customer, status klaim tertahan di "documents uploaded".
   - Tidak ada data yang hilang: pesan tetap tersimpan di SQS (retensi 4 hari) dan diproses setelah perbaikan.

   ### Timeline (WIB)

   Waktu Kejadian 
   - 13 Okt 14:21–15:29 | Query lambat dari job laporan bulanan (tidak berhubungan dengan incident)
   - 13 Okt 17:38 | Commit `8f3c2a1`: rename service account menjadi `claims-worker-sa`
   - 13 Okt 17:40–17:55 | `helmfile apply` ke prod. Apply pertama timeout (dikira VPN), apply kedua "nothing to change"
   - 13 Okt 17:43 | Pod baru mulai crash dengan error `AccessDenied` 403
   - 13 Okt 18:12 | Alarm `claims-documents-oldest-message-age` masuk status ALARM, tetapi tidak ada notifikasi
   - 14 Okt 01:38 | Customer Support melaporkan 40+ tiket di #claims-eng
   - 14 Okt 02:10 | Rina menghubungi platform engineer
   - 14 Okt 02:xx | Nama service account dikembalikan ke `claims-worker` dan di-deploy
   - 14 Okt 02:xx | Pod kembali Running, antrean mulai turun

   ### Akar masalah

   Trust policy IAM role `claims-worker-prod` (dibuat oleh `modules/irsa-role` dari `live/.../claims/prod/claims-worker-iam/terragrunt.hcl`) hanya mengizinkan `system:serviceaccount:claims:claims-worker`. Setelah nama service account di `apps/acme-prod-cluster/values/claims-worker.yaml` diganti menjadi `claims-worker-sa`, AWS menolak pod saat assume role. Worker tidak bisa membaca SQS dan langsung keluar (`CrashLoopBackOff`).

   Database **bukan** penyebab: query lambat sudah berhenti pukul 15:29 WIB, sebelum rename, dan log worker menunjukkan koneksi database berhasil.

   ### Kenapa kita tahu dari customer

   1. Alarm sudah menyala pukul 18:12 WIB, tetapi `alarm_actions` kosong, jadi notifikasi tidak terkirim ke siapa pun.
   2. Tidak ada alert untuk pod yang crash.
   3. Timeout pada `helmfile apply` (karena pod tidak pernah sehat) dianggap masalah VPN, dan tidak ada pengecekan pod setelah deploy.

   ### Perbaikan

   - Mengembalikan `serviceAccount.name` menjadi `claims-worker` di `apps/acme-prod-cluster/values/claims-worker.yaml`, lalu `helmfile apply`.
   - Verifikasi: pod Running, tidak ada error 403 di log, `ApproximateNumberOfMessages` turun, DLQ tidak bertambah, alarm kembali OK.
   - Rollback: `git revert` commit perbaikan, lalu `helmfile apply` lagi.
