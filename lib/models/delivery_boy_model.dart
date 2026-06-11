class DeliveryBoyModel {

  final String id;
  final String name;
  final String phone;
  final String address;
  final int age;
  final String licenseNumber;
  final String aadharNumber;

  DeliveryBoyModel({

    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.age,
    required this.licenseNumber,
    required this.aadharNumber,
  });

  factory DeliveryBoyModel.fromJson(
      Map<String, dynamic> json){

    return DeliveryBoyModel(

      id: json['id'],

      name: json['name'],

      phone: json['phone'],

      address: json['address'],

      age: json['age'],

      licenseNumber:
      json['license_number'],

      aadharNumber:
      json['aadhar_number'],
    );
  }
}