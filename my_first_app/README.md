# my_first_app

## Checklist Verivikasi
1. Flutter doctor
![](lib/screenshoots/flutter_doctor.png)

2. Flutter devices
![](lib/screenshoots/flutter_devices.png)

3. Aplikasi berjalan dan UI default telah diganti dengan profil sederhana.
![](lib/screenshoots/sudah_diganti.png)

4. Anda dapat menjelaskan perbedaan hot reload dan hot restart.
<br>Hot Reload hanya memperbarui kode tampilan (UI) dengan tetap mempertahankan data aplikasi, sedangkan Hot Restart mereset total aplikasi dan status datanya dari awal.

## Mini Assignment
![](lib/screenshoots/mini_assignment.png)
<br>Kendala awal saya adalah setup devices ke HP. Flutter saya tidak mendeteksi HP jadi agak lama untuk setup awalnya.

## Refleksi
1. Kapan native lebih tepat dipilih daripada cross-platform?
<br>Lebih dipilih untuk komputasi berat real-time, Augmented Reality (AR) kompleks, atau game 3D intensif.

2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?
<br>Saat state berubah, Flutter otomatis memanggil ulang fungsi build() untuk merekonstruksi cabang widget tree yang terdampak dan hanya merender perubahan visual yang diperlukan ke layar.

3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?
<br>Karena untuk memudahkan dokumentasi bagian pekerjaan apa yang sudah dikerjakan