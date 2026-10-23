import 'dart:async';

import '../../models/order.dart';
import '../order_repository.dart';
import 'reactive.dart';

class MemoryOrderRepo implements OrderRepository {
  final Map<String, Order> _orders = {};
  final Map<String, Reactive<List<Order>>> _byUser = {};

  Reactive<List<Order>> _bucket(String uid) =>
      _byUser.putIfAbsent(uid, () => Reactive(<Order>[]));

  @override
  Stream<List<Order>> watchMyOrders(String userId) => _bucket(userId).stream;

  @override
  Stream<Order?> watchOrder(String orderId) {
    final ctrl = StreamController<Order?>();
    void emit() => ctrl.add(_orders[orderId]);
    emit();
    for (final b in _byUser.values) {
      final sub = b.stream.listen((_) => emit());
      ctrl.onCancel = () => sub.cancel();
    }
    return ctrl.stream;
  }

  @override
  Future<Order> create(Order order) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _orders[order.id] = order;
    _appendTo(order.clientId, order);
    _appendTo(order.agentId, order);
    return order;
  }

  @override
  Future<Order> payEscrow(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _update(orderId, OrderStatus.paidEscrow);
  }

  @override
  Future<Order> startWork(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _update(orderId, OrderStatus.inProgress);
  }

  @override
  Future<Order> confirmComplete(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _update(orderId, OrderStatus.completed);
  }

  @override
  Future<Order> cancel(String orderId) async {
    return _update(orderId, OrderStatus.cancelled);
  }

  Order _update(String orderId, OrderStatus status) {
    final o = _orders[orderId]!;
    final updated = o.copyWith(status: status);
    _orders[orderId] = updated;
    _refreshUserBucket(o.clientId);
    _refreshUserBucket(o.agentId);
    return updated;
  }

  Order? getOrder(String id) => _orders[id];

  void _appendTo(String uid, Order o) {
    final b = _bucket(uid);
    final list = [...b.value];
    final idx = list.indexWhere((x) => x.id == o.id);
    if (idx == -1) {
      list.insert(0, o);
    } else {
      list[idx] = o;
    }
    b.set(list);
  }

  void _refreshUserBucket(String uid) {
    final b = _bucket(uid);
    b.set([...b.value]);
  }
}