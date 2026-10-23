import 'dart:async';

class Reactive<T> {
  T _value;
  final _ctrl = StreamController<T>.broadcast();
  Reactive(this._value);

  T get value => _value;

  void set(T newValue) {
    _value = newValue;
    _ctrl.add(newValue);
  }

  Stream<T> get stream {
    final first = _value;
    final ctrl = StreamController<T>();
    ctrl.add(first);
    final sub = _ctrl.stream.listen(
      ctrl.add,
      onError: ctrl.addError,
    );
    ctrl.onCancel = () => sub.cancel();
    return ctrl.stream;
  }
}