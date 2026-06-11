import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() =>
      _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final supabase = Supabase.instance.client;

  final productNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final canSizeController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("IMAGE PICK ERROR : $e");
    }
  }

  Future<String?> uploadImage() async {
    try {
      if (selectedImage == null) {
        return null;
      }

      final fileName =
          "products/${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage.from('product-images').upload(
        fileName,
        selectedImage!,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final imageUrl = supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

      debugPrint("IMAGE URL : $imageUrl");

      return imageUrl;
    } catch (e) {
      debugPrint("UPLOAD ERROR : $e");
      return null;
    }
  }

  Future<void> addProduct() async {
    try {
      FocusScope.of(context).unfocus();

      setState(() {
        isLoading = true;
      });

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      if (productNameController.text.trim().isEmpty) {
        throw Exception("Enter product name");
      }

      if (priceController.text.trim().isEmpty) {
        throw Exception("Enter product price");
      }

      if (quantityController.text.trim().isEmpty) {
        throw Exception("Enter quantity");
      }

      if (canSizeController.text.trim().isEmpty) {
        throw Exception("Enter can size");
      }

      final imageUrl = await uploadImage();

      await supabase.from('products').insert({
        'supplier_id': user.id,
        'product_name': productNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'quantity': int.parse(quantityController.text.trim()),
        'can_size': canSizeController.text.trim(),
        'image_url': imageUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product Added Successfully"),
        ),
      );

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      debugPrint("PRODUCT ERROR : $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.65),
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.cyanAccent,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 10,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    productNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    canSizeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff021B33),
                  Color(0xff004E92),
                  Color(0xff000428),
                ],
              ),
            ),
          ),

          // WATER GLOW
          Positioned(
            bottom: -70,
            left: -40,
            right: -40,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(220),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.25),
                    Colors.cyan.withOpacity(0.12),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 50,
                  sigmaY: 50,
                ),
                child: const SizedBox(),
              ),
            ),
          ),

          Positioned(
            top: -80,
            right: -60,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.lightBlueAccent.withOpacity(0.18),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Add Product",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // TOP INFO CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 58,
                              width: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyan.withOpacity(0.9),
                                    Colors.blue,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Create New Product",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Add water can details and stock",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // FORM CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 190,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color:
                                    Colors.white.withOpacity(0.20),
                                  ),
                                ),
                                child: selectedImage == null
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor:
                                      Colors.cyanAccent,
                                      child: const Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.black,
                                        size: 34,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Select Product Image",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Tap here to upload image",
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.65),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                                    : ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(22),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            inputField(
                              controller: productNameController,
                              hint: "Product Name",
                              icon: Icons.water_drop,
                            ),

                            inputField(
                              controller: descriptionController,
                              hint: "Description",
                              icon: Icons.description,
                              maxLines: 3,
                            ),

                            inputField(
                              controller: priceController,
                              hint: "Price",
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                            ),

                            inputField(
                              controller: quantityController,
                              hint: "Quantity",
                              icon: Icons.inventory,
                              keyboardType: TextInputType.number,
                            ),

                            inputField(
                              controller: canSizeController,
                              hint: "Can Size",
                              icon: Icons.local_drink,
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                  elevation: 12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed:
                                isLoading ? null : addProduct,
                                child: isLoading
                                    ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                    : const Text(
                                  "ADD PRODUCT",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}