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

USE `stock_management`;

-- โครงสร้างตารางผลิตภัณฑ์ (Products)
CREATE TABLE IF NOT EXISTS products (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  min_quantity INT DEFAULT 10,
  image_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- โครงสร้างตารางประวัติการเคลื่อนไหวสต๊อก (Stock Movements)
CREATE TABLE IF NOT EXISTS stock_movements (
  id INT PRIMARY KEY AUTO_INCREMENT,
  product_id INT NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  movement_type ENUM('IN', 'OUT', 'ADJUST', 'NEW') NOT NULL,
  quantity INT NOT NULL,
  previous_quantity INT NOT NULL,
  new_quantity INT NOT NULL,
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- โครงสร้างตารางหมวดหมู่ (Categories)
CREATE TABLE IF NOT EXISTS categories (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- โครงสร้างตารางลูกค้า (Customers)
CREATE TABLE IF NOT EXISTS customers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- โครงสร้างตารางใบสั่งซื้อ (Purchase Orders)
CREATE TABLE IF NOT EXISTS purchase_orders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  supplier_name VARCHAR(100) NOT NULL,
  order_date DATE NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status ENUM('pending', 'received', 'cancelled') DEFAULT 'pending',
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- โครงสร้างตารางรายการในใบสั่งซื้อ (Purchase Order Items)
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id INT PRIMARY KEY AUTO_INCREMENT,
  purchase_order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL DEFAULT 0
);

-- โครงสร้างตารางรับสินค้า (Goods Received)
CREATE TABLE IF NOT EXISTS goods_received (
  id INT PRIMARY KEY AUTO_INCREMENT,
  purchase_order_id INT,
  received_date DATE NOT NULL,
  received_by VARCHAR(100),
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- โครงสร้างตารางรายการรับสินค้า (Goods Received Items)
CREATE TABLE IF NOT EXISTS goods_received_items (
  id INT PRIMARY KEY AUTO_INCREMENT,
  goods_received_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL DEFAULT 0
);

-- โครงสร้างตารางการขาย (Sales)
CREATE TABLE IF NOT EXISTS sales (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  sale_date DATE NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  net_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  payment_method ENUM('cash', 'transfer', 'credit') DEFAULT 'cash',
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- โครงสร้างตารางรายการขาย (Sale Items)
CREATE TABLE IF NOT EXISTS sale_items (
  id INT PRIMARY KEY AUTO_INCREMENT,
  sale_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) DEFAULT 0,
  total_price DECIMAL(12,2) NOT NULL DEFAULT 0
);
```

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
