import 'supabase_service.dart';

class SalesService {
  static Future<Map<String, dynamic>> createSale({
    required String businessId,
    String? customerId,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double tax = 0,
    required double paid,
    required String paymentMethod,
    String? note,
  }) async {
    final c = SupabaseService.client;
    if (c == null) throw StateError('Cloud backend is not configured.');

    final result = await c.rpc('create_sale', params: {
      'p_business_id': businessId,
      'p_customer_id': customerId,
      'p_items': items,
      'p_discount': discount,
      'p_tax': tax,
      'p_paid': paid,
      'p_payment_method': paymentMethod,
      'p_note': note,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<List<Map<String, dynamic>>> recent(String businessId) async {
    final c = SupabaseService.client;
    if (c == null) return [];
    final result = await c
        .from('sales')
        .select('id,invoice_number,customer_id,total,paid,payment_method,status,created_at')
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(result);
  }
}
