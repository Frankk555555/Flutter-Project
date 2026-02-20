# Stock Management Mobile App

แอปพลิเคชันบริหารจัดการสต๊อกสินค้า พัฒนาด้วย **Flutter** และเชื่อมต่อฐานข้อมูล **MySQL** โดยตรง (ผ่านแพ็กเกจ `mysql_client`)

## 🛠 Prerequisites (สิ่งที่ต้องมีในเครื่อง)
ก่อนรันโปรเจคนี้ เครื่องของคุณต้องติดตั้งเครื่องมือต่อไปนี้:
1. **Flutter SDK** (เวอร์ชันล่าสุด)
2. **Dart SDK** (มาพร้อมกับ Flutter)
3. **โปรแกรมจำลองฐานข้อมูล MySQL** เช่น [XAMPP](https://www.apachefriends.org/index.html), [MAMP](https://www.mamp.info/en/), หรือ Docker

---

## 🚀 การติดตั้งและรันโปรเจค (Installation & Setup)

### 1. โคลนโปรเจค (Clone Repository)
```bash
git clone https://github.com/Frankk555555/Flutter-Project.git
cd Flutter-Project
```

### 2. ติดตั้งแพ็กเกจ (Install Dependencies)
รันคำสั่งต่อไปนี้เพื่อดาวน์โหลดแพ็กเกจทั้งหมดที่จำเป็น
```bash
flutter pub get
```

### 3. การตั้งค่าฐานข้อมูล (Database Setup)
โปรเจคนี้ต้องการฐานข้อมูล MySQL ในการทำงาน โดยมีขั้นตอนการตั้งค่า 2 วิธี:

**วิธีที่ 1: ตั้งค่าผ่าน phpMyAdmin (วิธีที่ง่ายที่สุด)**
1. เปิด XAMPP (หรือโปรแกรมอื่น) แล้ว Start บริการ **Apache** และ **MySQL**
2. เปิดเบราว์เซอร์ไปที่ `http://localhost/phpmyadmin`
3. นำโค้ด SQL ด้านล่างนี้ไปรันในช่อง **SQL**:

```sql
-- สร้างฐานข้อมูลและ User สำหรับรันแอป
CREATE DATABASE IF NOT EXISTS `stock_management` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'stockapp'@'localhost' IDENTIFIED BY 'Iylqv3FscukyV5tV';
GRANT ALL PRIVILEGES ON `stock_management`.* TO 'stockapp'@'localhost';
FLUSH PRIVILEGES;
```

> **หมายเหตุ:** โครงสร้างตาราง (Table) ต่างๆ จะถูกสร้างขึ้นอัตโนมัติเมื่อแอปรันและเชื่อมต่อฐานข้อมูลในครั้งแรก (ผ่านโค้ดใน `lib/services/database_service.dart`)

**วิธีที่ 2: ตั้งค่าคอนฟิกเอง (ถ้าต้องการใช้ชื่ออื่น)**
หากคุณต้องการใช้ฐานข้อมูลชื่ออื่น หรือ Username/Password แบบอื่น ให้ไปแก้ไขโค้ดที่ไฟล์:
📁 `lib/config/database_config.dart`

```dart
class DatabaseConfig {
  static const String host = 'localhost';
  static const int port = 3307; // เปลี่ยนเป็น 3306 หากใช้ MySQL ทั่วไป (เช่น XAMPP ค่าเริ่มต้น)
  static const String user = 'stockapp';
  static const String password = 'Iylqv3FscukyV5tV';
  static const String database = 'stock_management';
}
```

### 4. รันแอปพลิเคชัน (Run the App)
คุณสามารถเลือกรันแอปได้หลายแพลตฟอร์ม:
```bash
# รันบนเครื่อง Windows (Desktop App)
flutter run -d windows

# รันบน Web Browser (Chrome)
flutter run -d chrome


```

---

## 🗑 การแก้ปัญหา (Troubleshooting)
**ปัญหา:** รัน `flutter run -d windows` แล้วเจอ Error `CMake Error: The current CMakeCache.txt directory...`

**วิธีแก้:** เกิดจาก Cache เก่าของระบบ ค้างอยู่ ให้เปิด Terminal ในโฟลเดอร์โปรเจคแล้วรันคำสั่งเหล่านี้ทีละบรรทัดเพื่อล้างแคช:
```bash
flutter clean
flutter pub get
flutter run -d windows
```
