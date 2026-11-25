import 'package:activity_firebase/auth_service.dart';
import 'package:activity_firebase/crud_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  // FAVORITE FILTER
  bool showFavoritesOnly = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Firebase Ednilan'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(context),
      ),
      body: Column(
        children: [
          // FAVORITE FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('All Items'),
                    selected: !showFavoritesOnly,
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: !showFavoritesOnly ? Colors.white : Colors.black,
                    ),
                    onSelected: (value) {
                      setState(() {
                        showFavoritesOnly = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.favorite,
                      color: showFavoritesOnly ? Colors.white : Colors.red,
                      size: 18,
                    ),
                    label: const Text('Favorites'),
                    selected: showFavoritesOnly,
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: showFavoritesOnly ? Colors.white : Colors.black,
                    ),
                    onSelected: (value) {
                      setState(() {
                        showFavoritesOnly = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // FIREBASE ITEMS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.getItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                // FILTER FAVORITES
                final filteredDocs = docs.where((item) {
                  final data = item.data() as Map<String, dynamic>;
                  final isFavorite = data['isFavorite'] ?? false;

                  if (showFavoritesOnly) {
                    return isFavorite == true;
                  }

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      showFavoritesOnly
                          ? 'No favorite items yet ❤️'
                          : 'No items found',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var item = filteredDocs[index];
                    final data = item.data() as Map<String, dynamic>;
                    final imageUrl = data['image_url'];
                    final isFavorite = data['isFavorite'] ?? false;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        // ITEM IMAGE
                        leading: imageUrl != null &&
                                imageUrl.toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image_not_supported,
                                    );
                                  },
                                ),
                              )
                            : null,

                        // ITEM NAME
                        title: Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ITEM QUANTITY
                        subtitle: Text(
                          'Quantity ${data['quantity'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),

                        // ACTION BUTTONS
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // FAVORITE BUTTON
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () async {
                                await service.toggleFavorite(
                                  item.id,
                                  isFavorite,
                                );
                              },
                            ),

                            // EDIT BUTTON
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () => openEditDialog(context, item),
                            ),

                            // DELETE BUTTON
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.orange,
                              ),
                              onPressed: () => _confirmDelete(context, item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // DELETE CONFIRMATION
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item'),
        content: const Text(
          'Are you sure you want to delete the item?',
        ),
        actions: [
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ADD ITEM DIALOG
  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    String? selectedImageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              if (selectedImageUrl != null && selectedImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    selectedImageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload image'),
                onPressed: () async {
                  final pickedFile = await service.pickImageForAddItem();

                  if (pickedFile != null) {
                    setState(() {
                      selectedImageUrl = pickedFile.url;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                  final quantity = int.tryParse(qtyCtrl.text);

                  if (quantity == null) return;

                  try {
                    await service.addItemWithImage(
                      nameCtrl.text,
                      quantity,
                      selectedImageUrl,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save error: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // EDIT ITEM DIALOG
  void openEditDialog(
    BuildContext context,
    DocumentSnapshot item,
  ) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
            onPressed: () async {
              final quantity = int.tryParse(qtyCtrl.text);

              if (nameCtrl.text.isNotEmpty && quantity != null) {
                await service.updateItem(
                  item.id,
                  nameCtrl.text,
                  quantity,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}