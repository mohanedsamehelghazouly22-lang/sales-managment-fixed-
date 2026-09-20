import 'supabase_service.dart';

class ProductService {
  static Future<List<Map<String, dynamic>>> list(String businessId) async {
    final c = SupabaseService.client;
    if (c == null) return [];
    final result = await c.from('products')
        .select('id,name,barcode,sku,purchase_price,sale_price,wholesale_price,stock,minimum_stock,unit,is_active,category_id')
        .eq('business_id', businessId)
        .order('name');
    return List<Map<String, dynamic>>.from(result);
  }

  static Stream<List<Map<String, dynamic>>> stream(String businessId) {
    final c = SupabaseService.client;
    if (c == null) return const Stream.empty();
    return c.from('products')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('name');
  }

  static Future<void> upsert({
    String? id,
    required String businessId,
    required String name,
    String? barcode,
    String? sku,
    required double purchasePrice,
    required double salePrice,
    required double wholesalePrice,
    required double stock,
    required double minimumStock,
    required String unit,
  }) async {
    final c = SupabaseService.client;
    if (c == null) throw StateError('Cloud backend is not configured.');
    final payload = {
      if (id != null) 'id': id,
      'business_id': businessId,
      'name': name.trim(),
      'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'wholesale_price': wholesalePrice,
      'stock': stock,
      'minimum_stock': minimumStock,
      'unit': unit.trim().isEmpty ? 'قطعة' : unit.trim(),
    };
    await c.from('products').upsert(payload);
  }

  static Future<void> delete(String id) async {
    final c = SupabaseService.client;
    if (c == null) throw StateError('Cloud backend is not configured.');
    await c.from('products').delete().eq('id', id);
  }
}
