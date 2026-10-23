import '../models/order.dart';

abstract class OrderRepository {
  Stream<List<Order>> watchMyOrders(String userId);
  Stream<Order?> watchOrder(String orderId);
  Future<Order> create(Order order);
  Future<Order> payEscrow(String orderId);
  Future<Order> startWork(String orderId);
  Future<Order> confirmComplete(String orderId);
  Future<Order> cancel(String orderId);
}