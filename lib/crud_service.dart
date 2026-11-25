import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'xoarkcao',
    'flutter_upload',
    cache: false,
  );

  Future<CloudinaryResponse?> pickImageForAddItem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    final bytes = await pickedFile.readAsBytes();
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromBytesData(
        bytes,
        identifier: pickedFile.name,
        folder: 'flutter_items',
      ),
    );
    return response;
  }

  Future<void> addItemWithImage(
    String name,
    int quantity,
    String? imageUrl,
  ) {
    return items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl ?? '',
      'isFavorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  Future<void> toggleFavorite(String id, bool currentStatus) {
    return items.doc(id).update({
      'isFavorite': !currentStatus,
    });
  }

  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}