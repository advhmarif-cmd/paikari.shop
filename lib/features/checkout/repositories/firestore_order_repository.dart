import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paikari_shop/features/checkout/models/order.dart' as app_order;

class FirestoreOrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> placeOrder(app_order.Order order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toJson());
    } catch (e) {
      throw Exception('অর্ডারটি সেভ করতে সমস্যা হয়েছে: $e');
    }
  }

  Stream<List<app_order.Order>> getOrders(String userId) {
    // Note: In a real app, we would filter by userId
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.Order.fromFirestore(doc))
            .toList());
  }
}
