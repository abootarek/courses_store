import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new order
  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toJson());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get all orders (Admin only)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get orders by user ID
  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      // Sort in Dart to avoid Firestore Index requirement
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return orders;
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Update order status (Admin only)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Delete order (Admin only)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // Get pending orders count
  Future<int> getPendingOrdersCount() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get pending orders count: $e');
    }
  }

  // Get pending orders
  Future<List<OrderModel>> getPendingOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Sort in Dart to avoid Firestore Index requirement
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      throw Exception('Failed to get pending orders: $e');
    }
  }

  // Get all orders for management (pending, approved, rejected)
  Future<List<OrderModel>> getAllOrdersForManagement() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Sort in Dart to avoid Firestore Index requirement
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      throw Exception('Failed to get orders for management: $e');
    }
  }

  // Get total revenue
  Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'approved')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final order = OrderModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
        total += order.coursePrice;
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }
}
