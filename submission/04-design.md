## Solusi

Saya memilih solusi berikut, dan tidak memakai tool baru.

Deploy dijalankan oleh GitHub Actions, bukan dari laptop. Job yang membutuhkan akses ke AWS berjalan di satu runner private yang dipasang di dalam EKS/instance. Runner ini masuk ke AWS lewat IRSA, sama seperti `claims-worker`, sehingga tidak ada access key yang disimpan di GitHub.

Setiap perubahan harus lewat Pull Request. Plan berjalan otomatis di PR seperti Atlantis, sehingga reviewer bisa melihat apa yang akan berubah sebelum menyetujui. Setelah PR disetujui dan di merge ke `main`, plan berjalan lagi secara otomatis. Apply tidak berjalan otomatis. Untuk dev, apply dijalankan oleh platform engineer lewat tombol "Run workflow" di GitHub Actions. Untuk production, deploy dilakukan memakai release tag yang hanya bisa dibuat oleh platform engineer.

Untuk akses developer, setiap engineer punya IAM user sendiri dengan MFA.


## 1. Alur perubahan dari PR ke production

Alurnya sama untuk infrastruktur maupun aplikasi cluster.

1. Engineer membuat branch dan membuka Pull Request.
2. Runner private otomatis menjalankan lint, validate, test, lalu `terragrunt plan` dan `helmfile diff` untuk dev dan prod. Hasil plan ditampilkan sebagai komentar di PR.
3. Reviewer memeriksa kode dan hasil plan, lalu menyetujui PR. Minimal satu persetujuan dari engineer lain yang punya akses ke repo.
4. PR di merge ke `main`.
5. Runner private otomatis menjalankan plan lagi untuk dev dan prod dari `main`. Plan ini menjadi acuan sebelum apply.
6. Platform engineer menekan tombol "Run workflow" di GitHub Actions dan memilih dev. Runner private menerapkan perubahan ke dev, lalu perubahan dicek di dev.
7. Jika dev sudah aman, platform engineer membuat release tag, misalnya `v2026.10.14`.
8. Runner private menerapkan perubahan ke prod dari tag tersebut.
9. Setelah deploy, kesehatan sistem dicek. Untuk infrastruktur, plan ulang harus menunjukkan "No changes". Untuk aplikasi cluster, `kubectl rollout status` harus berhasil, dan deploy dianggap gagal kalau pod tidak sehat.

Environment tujuan ditentukan oleh folder. Saat apply dev dijalankan, yang diterapkan hanya folder `live/**/dev/` dan `apps/acme-dev-cluster/`. Saat ada tag `v*`, yang diterapkan hanya folder `live/**/prod/` dan `apps/acme-prod-cluster/`, untuk stack yang berubah sejak tag sebelumnya. Apply tidak memakai `run-all apply` untuk semua stack.

Kalau apply ke dev gagal, perbaikannya lewat PR baru, dan tag untuk prod tidak dibuat sampai dev berhasil.

Ada beberapa aturan yang saya aktifkan di GitHub. Branch `main` dilindungi, sehingga semua perubahan wajib lewat PR, plan harus berhasil, minimal ada satu persetujuan, dan tidak ada yang bisa push langsung. Opsi "Dismiss stale approvals" juga aktif, jadi kalau ada commit baru setelah PR disetujui, persetujuannya batal dan PR harus disetujui lagi.

Hanya satu apply yang boleh berjalan pada satu waktu untuk setiap environment, supaya dua deploy tidak menerapkan perubahan ke tempat yang sama secara bersamaan.

Saya memilih release tag karena perubahan bisa dicoba di dev terlebih dahulu, beberapa PR bisa dirilis bersama dalam satu tag, dan setiap rilis prod punya nama yang jelas sehingga mudah dicatat dan diaudit. Kalau perlu rollback, buat PR berisi `git revert`, merge ke `main`, lalu buat tag baru.


## 2. Akses AWS

### Otomasi

Runner private dipasang memakai Actions Runner Controller (ARC), yaitu Helm chart resmi dari GitHub. Pemasangannya lewat `helmfile`, sama seperti aplikasi cluster yang lain. Cukup satu runner di cluster prod, dengan satu service account dan satu IAM role bernama `runner-deploy` yang dibuat memakai modul `irsa-role` yang sudah ada di repo. Role ini juga didaftarkan di EKS access entry untuk cluster dev dan prod, supaya `helmfile` bisa deploy ke kedua cluster.

Semua job berjalan di runner private ini. Saat PR dibuka atau diperbarui, runner menjalankan lint, validate, test, dan plan. Saat ada push ke `main`, runner menjalankan plan lagi. Saat platform engineer menekan "Run workflow" untuk dev, runner menjalankan apply ke dev. Saat ada tag `v*`, runner menjalankan apply ke prod.

Karena memakai IRSA, tidak ada access key di GitHub secrets dan tidak perlu OIDC GitHub. Credential AWS bersifat sementara dan diperbarui otomatis oleh EKS.

Karena plan berjalan otomatis sebelum PR direview, sama seperti Atlantis, kode di PR sudah dijalankan di runner private sebelum ada yang menyetujui. Repo ini privat, sehingga orang luar tidak bisa membuat fork dan membuka PR, dan hanya karyawan yang punya akses yang bisa membuat PR. Perubahan di folder `.github/workflows/` tetap harus lewat PR dan disetujui. Apply hanya berjalan dari tombol "Run workflow" oleh platform engineer atau dari tag `v*` yang dilindungi, dan setiap job berjalan di pod baru yang langsung dihapus setelah selesai.

### Akses Developer

Setiap engineer punya IAM user sendiri, sehingga tidak ada lagi user yang dipakai bersama. MFA wajib untuk semua user. Akses sehari hari hanya bisa membaca, karena perubahan dilakukan lewat PR, bukan dari laptop. Akses admin hanya dipakai saat darurat dan tetap wajib MFA. User `budi` beserta access key nya dinonaktifkan.

### Audit untuk OJK

Kalau OJK bertanya siapa yang mengubah production, jawabannya bisa dilihat dari penulis PR, orang yang membuat release tag, dan nama role runner yang tercatat di CloudTrail. Waktu perubahan bisa dilihat dari waktu tag dibuat, log GitHub Actions, dan CloudTrail. Yang menyetujui adalah approver PR dan orang yang membuat release tag. Untuk dev, yang menjalankan apply tercatat di log GitHub Actions. Isi rilisnya bisa dilihat dari daftar commit di antara tag sebelumnya dan tag yang baru, dan hasil plan tersimpan sebagai komentar di setiap PR.

## 3. Yang sengaja saya tidak lakukan
1. Tidak memasang tools tambahan seperti Atlantis, Argo CD, Flux, atau Terraform Cloud. Dikarenakan budget Budget optimization.
2. Memisahkan account AWS, karena ini roject besar, dan harus di planing dengan matang.

## 4. Rollout bertahap

1. Minggu pertama, saya aktifkan perlindungan branch, lalu umumkan ke product engineer bahwa semua perubahan sekarang harus lewat PR.
2. Minggu kedua, saya pasang ARC dan satu runner private dengan role `runner-deploy`, sehingga lint, test, dan plan berjalan otomatis di setiap PR dan setelah merge. Pemasangan pertama ini dilakukan sekali dari laptop.
3. Minggu ketiga, saya aktifkan tombol "Run workflow" untuk apply ke dev.
4. Minggu keempat, saya aktifkan perlindungan tag dan deploy ke prod mulai memakai release tag.
5. Minggu kelima, saya buat IAM user untuk setiap orang dengan MFA, menonaktifkan user `budi`, dan akses dari laptop hanya untuk keadaan darurat.

Setiap tahap bisa berjalan tanpa menghentikan pekerjaan product engineer. Kalau ada tahap yang bermasalah, apply manual dari laptop masih bisa dipakai untuk sementara.


## Diagram

Terlampir (04-design.png)

File sumber diagram ada di `04-design.drawio`
