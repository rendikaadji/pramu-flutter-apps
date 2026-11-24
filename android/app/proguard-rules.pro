# OCR KTP memakai google_mlkit_text_recognition dengan model Latin saja. Plugin merujuk opsi untuk aksara lain
# (Mandarin, Devanagari, Jepang, Korea); kelasnya tidak disertakan, jadi peringatan R8-nya aman diabaikan.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
