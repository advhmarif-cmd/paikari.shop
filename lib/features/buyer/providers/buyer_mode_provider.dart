import 'package:flutter_riverpod/flutter_riverpod.dart';

/// False means retail/B2C intent; true means business/B2B intent for the current session.
final businessBuyerModeProvider = StateProvider<bool>((ref) => false);
