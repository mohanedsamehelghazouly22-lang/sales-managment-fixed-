import 'supabase_service.dart';

class ReportsService {
  static Future<List<Map<String, dynamic>>> salesSince(
      String businessId, DateTime since) async {
    final c = SupabaseService.client;
    if (c == null) return [];
    final result = await c
        .from('sales')
        .select('id,invoice_number,total,payment_method,status,created_at')
        .eq('business_id', businessId)
        .gte('created_at', since.toIso8601String())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result)
        .where((s) => s['status'] != 'cancelled')
        .toList();
  }
}
