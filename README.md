# Requirements
Godot Version: 4.2.2

# Pengerjaan
Project ini terinspirasi dengan game viewfinder di mana player biar mengambil foto dari lingkungannya dan kemudian foto tersebut menjadi realita ketika ditempelkan ke layar.

Cara melakukannya secara garis besar adalah dengan membuat sebuah CSG Intersector yang akan "memotong" secara pas dari POV player di tengah layar. Ketika player mengambil foto lingkungan, kita menggunakan Area3D dengan bentuk yang sama dengan CSG Intersector tersebut untuk mengambil semua object yang intersect dengan daerah foto, kemudian kita melakukan CSG Intersection terhadap semua object tersebut dan menyimpannya. Ketika player menggunakan foto tersebut, maka tinggal menggunakan semua object yang sudah dipotong dengan CSG Intersector tersebut sambil memotong lingkungan agar tidak ada object yang overlap dengan lingkungan.

Setelah itu bisa melakukan polishing berupa mengambil foto menggunakan SubViewport dan melakukan animasi seolah-olah mengambil foto dan menggunakan foto. Kemudian menggunakan Area3D untuk finishing area untuk player menang.

# Referensi
- Referensi paling besar dari project ini adalah blog post mengenai tutorial bagaimana membuat project ini: https://ishamf.com/p/implementing-viewfinder-mechanic/
- Subviewport Tutorial: https://youtu.be/Ln4E_2ZLLL4?si=fsjC0Bd9342RQ-gh
- Sky Shader Tutorial: https://youtu.be/SzNmHPr4vf8?si=FGMI4pV9qcKGE-hz