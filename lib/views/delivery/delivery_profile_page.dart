import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryProfilePage extends StatefulWidget {
  const DeliveryProfilePage({super.key});

  @override
  State<DeliveryProfilePage> createState() =>
      _DeliveryProfilePageState();
}

class _DeliveryProfilePageState extends State<DeliveryProfilePage> {

  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isEditing = false;

  Map<String, dynamic>? data;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final ageController = TextEditingController();
  final licenseController = TextEditingController();
  final aadharController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {

    final user = supabase.auth.currentUser;

    final res = await supabase
        .from('delivery_boys')
        .select()
        .eq('email', user!.email ?? '')
        .maybeSingle();

    data = res;

    nameController.text = res?['name'] ?? '';
    phoneController.text = res?['phone'] ?? '';
    addressController.text = res?['address'] ?? '';
    ageController.text = res?['age']?.toString() ?? '';
    licenseController.text = res?['license_number'] ?? '';
    aadharController.text = res?['aadhar_number'] ?? '';

    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateProfile() async {

    final user = supabase.auth.currentUser;

    await supabase.from('delivery_boys').update({
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
      'age': int.tryParse(ageController.text) ?? 0,
      'license_number': licenseController.text.trim(),
      'aadhar_number': aadharController.text.trim(),
    }).eq('email', user!.email ?? '');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated successfully")),
    );

    setState(() {
      isEditing = false;
    });

    fetchProfile();
  }

  Widget infoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.cyanAccent,
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget inputField(TextEditingController c, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle:
          TextStyle(color: Colors.white.withOpacity(0.6)),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          /// BG
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff021B33),
                  Color(0xff004E92),
                  Color(0xff000428),
                ],
              ),
            ),
          ),

          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  /// HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (isEditing) {
                            setState(() {
                              isEditing = false;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          isEditing ? "Edit Profile" : "My Profile",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// PROFILE CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.cyanAccent,
                          child: Icon(Icons.person, size: 40, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data!['name'] ?? "",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          data!['email'] ?? "",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// VIEW MODE
                  if (!isEditing) ...[
                    infoCard("Phone", data!['phone'] ?? "-", Icons.phone),
                    infoCard("Address", data!['address'] ?? "-", Icons.location_on),
                    infoCard("Age", data!['age']?.toString() ?? "-", Icons.cake),
                    infoCard("License", data!['license_number'] ?? "-", Icons.credit_card),
                    infoCard("Aadhar", data!['aadhar_number'] ?? "-", Icons.badge),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            isEditing = true;
                          });
                        },
                        child: const Text("EDIT PROFILE"),
                      ),
                    ),
                  ],

                  /// EDIT MODE
                  if (isEditing) ...[
                    inputField(nameController, "Name"),
                    inputField(phoneController, "Phone"),
                    inputField(addressController, "Address"),
                    inputField(ageController, "Age"),
                    inputField(licenseController, "License"),
                    inputField(aadharController, "Aadhar"),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                              });
                            },
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: updateProfile,
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}