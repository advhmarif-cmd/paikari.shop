import shutil
import os

src = r"C:\Users\advhm\.gemini\antigravity\brain\3959f8d8-a897-4ed4-8d4a-549b2ccf240d\uploaded_image_1766898263084.jpg"
dst = r"c:\Users\advhm\paikari.shop\assets\logo.jpg"

print(f"Attempting copy from {src} to {dst}")

try:
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print("Copy Success")
        print(f"New size: {os.path.getsize(dst)}")
    else:
        print("Source file not found")
except Exception as e:
    print(f"Error: {e}")
