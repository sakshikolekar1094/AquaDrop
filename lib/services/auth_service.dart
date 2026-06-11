import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // REGISTER
  Future<String?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      // CHECK IF SUPPLIER ALREADY EXISTS
      if (role == 'supplier') {
        final existingSupplier = await supabase
            .from('profiles')
            .select()
            .eq('role', 'supplier');

        if (existingSupplier.isNotEmpty) {
          return "Supplier already registered";
        }
      }

      // CREATE AUTH USER
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // INSERT USER DATA
        await supabase.from('profiles').insert({
          'id': user.id,
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
        });

        return null;
      }

      return "Registration Failed";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // GET CURRENT USER ROLE
  Future<String?> getUserRole() async {
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        return profile['role'];
      }

      final deliveryBoy = await supabase
          .from('delivery_boys')
          .select('role')
          .eq('email', user.email ?? '')
          .maybeSingle();

      if (deliveryBoy != null) {
        return deliveryBoy['role'];
      }

      return null;
    } catch (e) {
      print("GET ROLE ERROR : $e");
      return null;
    }
  }
}