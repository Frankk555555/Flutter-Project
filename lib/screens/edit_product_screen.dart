import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';

/// Screen for editing an existing product
class EditProductScreen extends StatefulWidget {
  final int productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategory;
  String? _selectedImagePath;
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _categories = [];
  bool _isCategoryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadProduct(),
    ]);
  }

  Future<void> _loadCategories() async {
    final categoryService = CategoryService();
    try {
      final categories = await categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories.map((c) => c.name).toList();
          _isCategoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCategoryLoading = false);
      }
    } finally {
      await categoryService.close();
    }
  }

  Future<void> _loadProduct() async {
    final service = ProductService();
    final product = await service.getProductById(widget.productId);

    if (product != null && mounted) {
      setState(() {
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _priceController.text = product.price.toString();
        _quantityController.text = product.quantity.toString();
        _minQuantityController.text = product.minQuantity.toString();
        _imageUrlController.text = product.imageUrl ?? '';
        _selectedCategory = product.category;
        // ถ้าหมวดหมู่ของสินค้าไม่อยู่ในรายการจากฐานข้อมูล ให้เพิ่มเข้าไป
        if (!_categories.contains(product.category) && product.category.isNotEmpty) {
          _categories.add(product.category);
        }
        _isLoading = false;
      });
    } else if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบสินค้า'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขสินค้า'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImagePath != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_selectedImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImagePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _imageUrlController.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                                    ),
                                  )
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL รูปภาพ (ไม่บังคับ)',
                              prefixIcon: Icon(Icons.link),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('เลือกไฟล์'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสินค้า *',
                        prefixIcon: Icon(Icons.inventory_2),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อสินค้า';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    _isCategoryLoading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: _categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : (_categories.isNotEmpty ? _categories.first : null),
                            decoration: const InputDecoration(
                              labelText: 'หมวดหมู่ *',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat));
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาเลือกหมวดหมู่';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),

                    // Price and Quantity Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'ราคา (บาท) *',
                              prefixIcon: Container(
                                width: 48,
                                alignment: Alignment.center,
                                child: const Text('฿', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกราคา';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price < 0) {
                                return 'ราคาไม่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'จำนวน *',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกจำนวน';
                              }
                              final qty = int.tryParse(value);
                              if (qty == null || qty < 0) {
                                return 'จำนวนไม่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Min Quantity
                    TextFormField(
                      controller: _minQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'จำนวนขั้นต่ำ (แจ้งเตือน)',
                        prefixIcon: Icon(Icons.warning_amber),
                        border: OutlineInputBorder(),
                        helperText: 'แจ้งเตือนเมื่อสต๊อกต่ำกว่าจำนวนนี้',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียด (ไม่บังคับ)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'กำลังบันทึก...' : 'อัปเดตสินค้า',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'เพิ่มรูปภาพสินค้า',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImagePath = result.files.single.path;
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Use local path if available, otherwise use URL
    String? imageUrl = _selectedImagePath ?? 
        (_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null);

    final product = Product(
      id: widget.productId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      category: _selectedCategory ?? '',
      price: double.parse(_priceController.text),
      quantity: int.parse(_quantityController.text),
      minQuantity: int.tryParse(_minQuantityController.text) ?? 10,
      imageUrl: imageUrl,
    );

    final success = await context.read<ProductProvider>().updateProduct(product);

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดต "${product.name}" เรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถอัปเดตสินค้าได้ กรุณาลองใหม่'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
