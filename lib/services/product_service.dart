import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {

  final supabase =
      Supabase.instance.client;

  // INSERT PRODUCT
  Future<String?> addProduct({

    required String productName,
    required String description,
    required double price,
    required int quantity,
    required String canSize,
    required File imageFile,

  }) async {

    try {

      final fileName =
      DateTime.now()
          .millisecondsSinceEpoch
          .toString();

      // UPLOAD IMAGE
      await supabase.storage
          .from('product-images')
          .upload(

        fileName,
        imageFile,
      );

      // GET IMAGE URL
      final imageUrl =
      supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

      // INSERT DATA
      await supabase
          .from('products')
          .insert({

        'supplier_id':
        supabase.auth.currentUser!.id,

        'product_name':
        productName,

        'description':
        description,

        'price':
        price,

        'quantity':
        quantity,

        'can_size':
        canSize,

        'image_url':
        imageUrl,
      });

      return null;

    } catch (e) {

      return e.toString();
    }
  }

  // GET PRODUCTS
  Future<List<dynamic>> getProducts() async {

    final data =
    await supabase
        .from('products')
        .select()
        .order('created_at');

    return data;
  }

  // UPDATE PRODUCT
  Future<String?> updateProduct({

    required String productId,
    required String productName,
    required String description,
    required double price,
    required int quantity,
    required String canSize,

  }) async {

    try {

      await supabase
          .from('products')
          .update({

        'product_name':
        productName,

        'description':
        description,

        'price':
        price,

        'quantity':
        quantity,

        'can_size':
        canSize,

      })

          .eq('id', productId);

      return null;

    } catch (e) {

      return e.toString();
    }
  }

  // DELETE PRODUCT
  Future<String?> deleteProduct(
      String productId,
      ) async {

    try {

      await supabase
          .from('products')
          .delete()
          .eq('id', productId);

      return null;

    } catch (e) {

      return e.toString();
    }
  }
}