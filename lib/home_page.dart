import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'crud_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();

  // ADD ITEM DIALOG (Matches Reference UI)
  void _showAddItemDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    String? selectedImageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('Add item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isUploading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    else if (selectedImageUrl != null &&
                        selectedImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          selectedImageUrl!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        elevation: 2,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: isUploading
                          ? null
                          : () async {
                              setDialogState(() => isUploading = true);
                              try {
                                final response =
                                    await service.pickImageForAddItem();
                                if (response != null) {
                                  setDialogState(() {
                                    selectedImageUrl = response.secureUrl;
                                  });
                                }
                              } finally {
                                setDialogState(() => isUploading = false);
                              }
                            },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('upload Image'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final qty =
                              int.tryParse(quantityController.text.trim()) ?? 0;
                          if (name.isEmpty) return;

                          Navigator.pop(dialogContext);
                          await service.addItemWithImage(
                            name,
                            qty,
                            selectedImageUrl,
                          );
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // EDIT ITEM DIALOG
  void _showEditItemDialog(
    BuildContext context,
    String id,
    String currentName,
    int currentQuantity,
  ) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController quantityController =
        TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Edit item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final qty =
                    int.tryParse(quantityController.text.trim()) ?? 0;
                if (name.isEmpty) return;

                Navigator.pop(dialogContext);
                await service.updateItem(id, name, qty);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Firebase Ednilan',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No items yet. Tap + to add one!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index];
              final data = item.data() as Map<String, dynamic>;
              final String name = data['name'] ?? '';
              final int quantity = data['quantity'] ?? 0;
              final String imageUrl = data['image_url'] ?? '';

              return Card(
                elevation: 2,
                color: const Color(0xFFEDE8F0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 40),
                          ),
                        )
                      : null,
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Quantity $quantity',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showEditItemDialog(
                          context,
                          item.id,
                          name,
                          quantity,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => service.deleteItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
