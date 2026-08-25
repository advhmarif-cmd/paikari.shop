import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/chat/models/chat_models.dart';
import 'package:paikari_shop/features/chat/repositories/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? productId;
  final String? vendorId;
  final String? productName;
  final String? vendorName;
  final bool isVendor;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.productId,
    this.vendorId,
    this.productName,
    this.vendorName,
    this.isVendor = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _conversationId;
  bool _initializing = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId == null) {
      Future.microtask(_createConversation);
    } else {
      _initializing = false;
      Future.microtask(
          () => ref.read(chatRepositoryProvider).markRead(_conversationId!));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createConversation() async {
    if (widget.productId == null || widget.vendorId == null) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'এই product-এর seller chat available নয়।';
        });
      }
      return;
    }
    try {
      final id = await ref.read(chatRepositoryProvider).getOrCreateConversation(
            productId: widget.productId!,
            vendorId: widget.vendorId!,
          );
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _initializing = false;
      });
      await ref.read(chatRepositoryProvider).markRead(id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Chat শুরু করা যায়নি: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationId = _conversationId;
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (conversationId == null) {
      return _ChatStateScreen(
          message: _error ?? 'Chat conversation পাওয়া যায়নি।',
          onRetry: widget.conversationId == null ? _createConversation : null);
    }

    final messagesAsync = ref.watch(chatMessagesProvider(conversationId));
    ref.listen(chatMessagesProvider(conversationId), (_, next) {
      if (next.hasValue) {
        ref.read(chatRepositoryProvider).markRead(conversationId);
      }
    });
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.vendorName ??
                    (widget.isVendor ? 'Buyer chat' : 'Seller chat'),
                style: const TextStyle(fontSize: 18)),
            if (widget.productName != null)
              Text(widget.productName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ChatStatePanel(
                  message: 'Message load করা যায়নি: $error',
                  onRetry: () =>
                      ref.invalidate(chatMessagesProvider(conversationId))),
              data: (messages) {
                if (messages.isEmpty) {
                  return const _ChatEmptyState();
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _MessageBubble(
                    message: messages[index],
                    isMine: messages[index].senderId == currentUserId,
                  ),
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            sending: _sending,
            onSend: _sendMessage,
            hintText: widget.isVendor
                ? 'Buyer-কে message লিখুন'
                : 'Seller-কে message লিখুন',
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    final conversationId = _conversationId;
    if (body.isEmpty || conversationId == null || _sending) return;
    if (body.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Message সর্বোচ্চ ২০০০ character হতে পারে।')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: conversationId, body: body);
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message পাঠানো যায়নি: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final String hintText;

  const _MessageComposer(
      {required this.controller,
      required this.sending,
      required this.onSend,
      required this.hintText});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.chat_bubble_outline)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Message পাঠান',
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(message.body,
                  style: TextStyle(
                      color: isMine ? Colors.white : colorScheme.onSurface,
                      height: 1.4)),
            ),
            const SizedBox(height: 4),
            Text(
              _timeLabel(message.createdAt),
              style: TextStyle(
                  color: isMine ? Colors.white70 : colorScheme.outline,
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined,
                size: 58, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            const Text('Conversation শুরু করুন',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
                'Requirement, quantity, delivery বা packaging সম্পর্কে seller-কে লিখুন।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ChatStatePanel extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ChatStatePanel({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 54),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('আবার চেষ্টা করুন')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatStateScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ChatStateScreen({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller chat')),
      body: _ChatStatePanel(message: message, onRetry: onRetry),
    );
  }
}

class ChatInboxScreen extends ConsumerWidget {
  final bool isVendor;

  const ChatInboxScreen({super.key, required this.isVendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(isVendor
        ? vendorChatConversationsProvider
        : buyerChatConversationsProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(isVendor ? 'Buyer chats' : 'Seller chats')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ChatStatePanel(
            message: 'Chat list load করা যায়নি: $error',
            onRetry: () => ref.invalidate(isVendor
                ? vendorChatConversationsProvider
                : buyerChatConversationsProvider)),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const _ChatStatePanel(message: 'এখনও কোনো chat নেই।');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final unread = conversation.isUnreadFor(userId);
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        conversation.productImageUrl?.trim().isNotEmpty == true
                            ? NetworkImage(conversation.productImageUrl!)
                            : null,
                    child:
                        conversation.productImageUrl?.trim().isNotEmpty == true
                            ? null
                            : Icon(isVendor
                                ? Icons.storefront_outlined
                                : Icons.person_outline),
                  ),
                  title: Text(
                      conversation.productName?.trim().isNotEmpty == true
                          ? conversation.productName!
                          : 'Product #${conversation.productId.substring(0, 6)}',
                      style: TextStyle(
                          fontWeight:
                              unread ? FontWeight.w900 : FontWeight.w700)),
                  subtitle: Text(
                      conversation.lastMessagePreview ??
                          'Conversation শুরু হয়নি',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  trailing: unread
                      ? const CircleAvatar(radius: 5)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conversation.id,
                        productName: conversation.productName,
                        isVendor: isVendor,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
