import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewDeliveryBoysPage extends StatefulWidget {
  const ViewDeliveryBoysPage({super.key});

  @override
  State<ViewDeliveryBoysPage> createState() =>
      _ViewDeliveryBoysPageState();
}

class _ViewDeliveryBoysPageState extends State<ViewDeliveryBoysPage> {
  final supabase = Supabase.instance.client;

  List deliveryBoys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDeliveryBoys();
  }

  Future<void> loadDeliveryBoys() async {
    try {
      final data = await supabase
          .from('delivery_boys')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          deliveryBoys = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LOAD DELIVERY ERROR : $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteDeliveryBoy(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Delivery Boy"),
          content: const Text(
            "Are you sure you want to delete this delivery boy?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await supabase.from('delivery_boys').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Delivery Boy Deleted"),
          ),
        );

        loadDeliveryBoys();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void showEditDialog(Map boy) {
    final nameController =
    TextEditingController(text: boy['name'] ?? '');

    final phoneController =
    TextEditingController(text: boy['phone'] ?? '');

    final addressController =
    TextEditingController(text: boy['address'] ?? '');

    final ageController =
    TextEditingController(text: boy['age']?.toString() ?? '');

    final licenseController =
    TextEditingController(text: boy['license_number'] ?? '');

    final aadharController =
    TextEditingController(text: boy['aadhar_number'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xff021B33).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text(
                        "Edit Delivery Boy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      editField(
                        nameController,
                        "Name",
                        Icons.person,
                      ),

                      editField(
                        phoneController,
                        "Phone",
                        Icons.phone,
                      ),

                      editField(
                        addressController,
                        "Address",
                        Icons.location_on,
                      ),

                      editField(
                        ageController,
                        "Age",
                        Icons.cake,
                        keyboardType: TextInputType.number,
                      ),

                      editField(
                        licenseController,
                        "License Number",
                        Icons.credit_card,
                      ),

                      editField(
                        aadharController,
                        "Aadhar Number",
                        Icons.badge,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Cancel"),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                await supabase
                                    .from('delivery_boys')
                                    .update({
                                  'name': nameController.text.trim(),
                                  'phone': phoneController.text.trim(),
                                  'address': addressController.text.trim(),
                                  'age': int.parse(
                                    ageController.text.trim(),
                                  ),
                                  'license_number':
                                  licenseController.text.trim(),
                                  'aadhar_number':
                                  aadharController.text.trim(),
                                }).eq(
                                  'id',
                                  boy['id'],
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }

                                loadDeliveryBoys();
                              },
                              child: const Text("Update"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget editField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
            vertical: 16,
            horizontal: 10,
          ),
        ),
      ),
    );
  }

  Widget deliveryBoyCard(Map boy) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.cyanAccent,
                    child: Icon(
                      Icons.delivery_dining,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          boy['name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          boy['email'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

              const SizedBox(height: 15),

              infoRow(
                Icons.phone,
                "Phone",
                boy['phone'] ?? '-',
              ),

              infoRow(
                Icons.location_on,
                "Address",
                boy['address'] ?? '-',
              ),

              infoRow(
                Icons.cake,
                "Age",
                boy['age']?.toString() ?? '-',
              ),

              infoRow(
                Icons.credit_card,
                "License",
                boy['license_number'] ?? '-',
              ),

              infoRow(
                Icons.badge,
                "Aadhar",
                boy['aadhar_number'] ?? '-',
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        showEditDialog(boy);
                      },
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                      ),
                      label: const Text("Edit"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        deleteDeliveryBoy(
                          boy['id'],
                        );
                      },
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                      ),
                      label: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.cyanAccent,
          ),

          const SizedBox(width: 8),

          Text(
            "$title: ",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
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
                            "Delivery Boys",
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
                ),

                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                    ),
                  )
                      : deliveryBoys.isEmpty
                      ? const Center(
                    child: Text(
                      "No Delivery Boys Found",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: loadDeliveryBoys,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: deliveryBoys.length,
                      itemBuilder: (context, index) {
                        return deliveryBoyCard(
                          deliveryBoys[index],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}