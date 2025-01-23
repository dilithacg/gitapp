import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:giftapp/const/colors.dart';

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Compress the image before saving it
  Future<File> compressImage(File image) async {
    final result = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      minWidth: 800, // Minimum width for compression
      minHeight: 800, // Minimum height for compression
      quality: 80, // Quality level (0-100)
    );

    return File(image.absolute.path)..writeAsBytesSync(result!);
  }

  // This function would be used to upload the image to an external server
  // and return the URL. Replace with actual API call if required.
  Future<String?> uploadImageToExternalService(File image) async {
    // You can implement uploading logic here, for now we'll simulate a URL.
    // Example: Upload the image to a server and get the URL.
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    return "https://example.com/your_image.jpg"; // Placeholder URL
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text;
      String description = _descriptionController.text;
      String price = _priceController.text;
      File? image = _selectedImage;

      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      try {
        // Compress the image before uploading
        File compressedImage = await compressImage(image);

        // Upload the image to an external service (replace with your actual implementation)
        String? imageUrl = await uploadImageToExternalService(compressedImage);
        if (imageUrl == null) return;

        // Save item details to Firestore
        await FirebaseFirestore.instance.collection('items').add({
          'title': title,
          'description': description,
          'price': double.parse(price),
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
        });

        // Clear form
        _formKey.currentState!.reset();
        setState(() {
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedImage == null
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  onPressed: _saveItem,
                  child: Text(
                    'Add Item',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
