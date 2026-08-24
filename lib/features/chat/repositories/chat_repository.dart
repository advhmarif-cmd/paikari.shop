import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/chat/models/chat_models.dart';

class ChatRepository {
  ChatRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<String> getOrCreateConversation({required String productId, required String vendorId}) async {
    final result = await _supabase.rpc('get_or_create_chat_conversation', params: {
      'p_product_id': productId,
      'p_vendor_id': vendorId,
    });
    return result as String;
  }

  Future<void> sendMessage({required String conversationId, required String body}) async {
    await _supabase.rpc('send_chat_message', params: {
      'p_conversation_id': conversationId,
      'p_body': body.trim(),
    });
  }

  Future<void> markRead(String conversationId) async {
    await _supabase.rpc('mark_chat_read', params: {'p_conversation_id': conversationId});
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((row) => ChatMessage.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  Stream<List<ChatConversation>> watchBuyerConversations() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .eq('buyer_id', user.id)
        .order('last_message_at', ascending: false)
        .map((rows) => rows.map((row) => ChatConversation.fromJson(Map<String, dynamic>.from(row))).toList());
  }

  Stream<List<ChatConversation>> watchVendorConversations() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', user.id)
        .order('last_message_at', ascending: false)
        .map((rows) => rows.map((row) => ChatConversation.fromJson(Map<String, dynamic>.from(row))).toList());
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final buyerChatConversationsProvider = StreamProvider.autoDispose<List<ChatConversation>>((ref) {
  return ref.watch(chatRepositoryProvider).watchBuyerConversations();
});

final vendorChatConversationsProvider = StreamProvider.autoDispose<List<ChatConversation>>((ref) {
  return ref.watch(chatRepositoryProvider).watchVendorConversations();
});

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});
