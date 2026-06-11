import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final supabase = Supabase.instance.client;

  Future<String?> addToCart(String productId) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return "User not logged in";
      }

      final existing = await supabase
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        final currentQty = existing['quantity'] ?? 1;

        await supabase
            .from('cart')
            .update({
          'quantity': currentQty + 1,
        })
            .eq('id', existing['id']);
      } else {
        await supabase.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': 1,
        });
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<dynamic>> getCartItems() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final data = await supabase
        .from('cart')
        .select('*, products(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return data;
  }

  Future<String?> updateQuantity(String cartId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(cartId);
      } else {
        await supabase
            .from('cart')
            .update({
          'quantity': quantity,
        })
            .eq('id', cartId);
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeFromCart(String cartId) async {
    try {
      await supabase.from('cart').delete().eq('id', cartId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> clearCart() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return "User not logged in";
      }

      await supabase.from('cart').delete().eq('user_id', user.id);

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}