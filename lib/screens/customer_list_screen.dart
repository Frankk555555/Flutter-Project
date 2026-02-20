import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

/// Screen for managing customers
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _service = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      if (_searchController.text.isNotEmpty) {
        _customers = await _service.searchCustomers(_searchController.text);
      } else {
        _customers = await _service.getAllCustomers();
      }
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
            Icon(Icons.people),
            SizedBox(width: 8),
            Text('ลูกค้า'),
          ],
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.indigo[700],
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาลูกค้า (ชื่อ/เบอร์โทร)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCustomers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _loadCustomers(),
            ),
          ),
          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('ยังไม่มีลูกค้า',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final cust = _customers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.teal[100],
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[700],
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (cust.phone != null && cust.phone!.isNotEmpty)
                                      Row(children: [
                                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(cust.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ]),
                                    if (cust.email != null && cust.email!.isNotEmpty)
                                      Row(children: [
                                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(cust.email!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ]),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showCustomerDialog(customer: cust),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(cust),
                                    ),
                                  ],
                                ),
                                isThreeLine: (cust.phone != null && cust.phone!.isNotEmpty) &&
                                    (cust.email != null && cust.email!.isNotEmpty),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('เพิ่มลูกค้า'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showCustomerDialog({Customer? customer}) async {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final isEdit = customer != null;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'แก้ไขข้อมูลลูกค้า' : 'เพิ่มลูกค้าใหม่'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อลูกค้า *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทร', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่', prefixIcon: Icon(Icons.home), border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final c = Customer(
                  id: customer?.id,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                );
                if (isEdit) {
                  await _service.updateCustomer(c);
                } else {
                  await _service.createCustomer(c);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white),
            child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'แก้ไขข้อมูลลูกค้าเรียบร้อย' : 'เพิ่มลูกค้าเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบลูกค้า "${customer.name}" หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
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
        await _service.deleteCustomer(customer.id!);
        await _loadCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ลบ "${customer.name}" เรียบร้อยแล้ว'), backgroundColor: Colors.green),
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
