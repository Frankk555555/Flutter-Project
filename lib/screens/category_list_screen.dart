import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

/// Screen for managing product categories (CRUD via dialogs)
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService _service = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _service.getAllCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.category),
            SizedBox(width: 8),
            Text('ประเภทสินค้า'),
          ],
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('ยังไม่มีประเภทสินค้า',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('เพิ่มประเภทสินค้าใหม่โดยกดปุ่ม + ด้านล่าง',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.category, color: Colors.indigo[700]),
                          ),
                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(cat.description ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showCategoryDialog(category: cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(cat),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มประเภท'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'แก้ไขประเภทสินค้า' : 'เพิ่มประเภทสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อประเภท *',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                if (isEdit) {
                  await _service.updateCategory(Category(
                    id: category.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : null,
                  ));
                } else {
                  await _service.createCategory(Category(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : null,
                  ));
                }
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'แก้ไขประเภทสินค้าเรียบร้อย' : 'เพิ่มประเภทสินค้าเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบประเภท "${category.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteCategory(category.id!);
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ลบ "${category.name}" เรียบร้อยแล้ว'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถลบได้: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
