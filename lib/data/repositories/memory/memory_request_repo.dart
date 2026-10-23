import 'dart:async';
import 'dart:math';

import '../../models/acceptance.dart';
import '../../models/agent.dart';
import '../../models/job_request.dart';
import '../request_repository.dart';
import 'reactive.dart';

class MemoryRequestRepo implements RequestRepository {
  final Map<String, JobRequest> _requests = {};
  final Map<String, List<Acceptance>> _acceptances = {};
  final Map<String, Reactive<List<JobRequest>>> _requestsByClient = {};
  final List<Agent> _agentPool = [];

  final Random _rand = Random();

  MemoryRequestRepo() {
    _seedAgents();
  }
  List<JobRequest> get publicRequestsSnapshot => _requests.values.toList();

  void _seedAgents() {
    final agents = [
      Agent(
        id: 'a_001',
        displayName: 'Budi S.',
        phone: '081100000001',
        ratingAvg: 4.8,
        jobsCompleted: 42,
        baseLat: -6.2020,
        baseLng: 106.8180,
        categoryIds: ['cleaning', 'moving', 'repair'],
        bio: 'Berpengalaman bersih-bersih & pindahan.',
      ),
      Agent(
        id: 'a_002',
        displayName: 'Joko P.',
        phone: '081100000002',
        ratingAvg: 4.6,
        jobsCompleted: 18,
        baseLat: -6.1980,
        baseLng: 106.8140,
        categoryIds: ['repair', 'garden'],
        bio: 'Tukang perbaikan rumah ringan.',
      ),
      Agent(
        id: 'a_003',
        displayName: 'Slamet R.',
        phone: '081100000003',
        ratingAvg: 4.9,
        jobsCompleted: 67,
        baseLat: -6.2050,
        baseLng: 106.8220,
        categoryIds: ['cleaning', 'laundry', 'pickup'],
        bio: 'Rajin, teliti, tepat waktu.',
      ),
      Agent(
        id: 'a_004',
        displayName: 'Andi W.',
        phone: '081100000004',
        ratingAvg: 4.5,
        jobsCompleted: 12,
        baseLat: -6.1950,
        baseLng: 106.8100,
        categoryIds: ['moving', 'repair'],
        bio: 'Kuat angkat barang.',
      ),
      Agent(
        id: 'a_005',
        displayName: 'Rudi H.',
        phone: '081100000005',
        ratingAvg: 4.7,
        jobsCompleted: 30,
        baseLat: -6.2100,
        baseLng: 106.8200,
        categoryIds: ['cleaning', 'garden'],
        bio: 'Spesialis taman & halaman.',
      ),
      Agent(
        id: 'a_006',
        displayName: 'Dedi K.',
        phone: '081100000006',
        ratingAvg: 4.4,
        jobsCompleted: 8,
        baseLat: -6.2050,
        baseLng: 106.8060,
        categoryIds: ['pickup', 'cleaning'],
        bio: 'Siap antar-jemput & bantu ringan.',
      ),
      Agent(
        id: 'a_007',
        displayName: 'Hendra S.',
        phone: '081100000007',
        ratingAvg: 4.8,
        jobsCompleted: 55,
        baseLat: -6.1920,
        baseLng: 106.8250,
        categoryIds: ['repair', 'moving'],
        bio: 'Tukang serba bisa.',
      ),
      Agent(
        id: 'a_008',
        displayName: 'Yanto B.',
        phone: '081100000008',
        ratingAvg: 4.6,
        jobsCompleted: 22,
        baseLat: -6.2080,
        baseLng: 106.8120,
        categoryIds: ['laundry', 'cleaning', 'pickup'],
        bio: 'Teliti untuk urusan rumah tangga.',
      ),
    ];
    _agentPool.addAll(agents);
  }

  List<Agent> get allAgents => List.unmodifiable(_agentPool);

  @override
  List<Agent> nearbyAgents(String categoryId, {double? lat, double? lng}) {
    final list = _agentPool
        .where((a) => a.categoryIds.contains(categoryId) && a.isOnline)
        .toList();
    if (lat != null && lng != null) {
      list.sort((a, b) {
        final da = a.distanceFrom(lat, lng);
        final db = b.distanceFrom(lat, lng);
        return da.compareTo(db);
      });
    }
    return list;
  }

  Reactive<List<JobRequest>> _bucket(String clientId) =>
      _requestsByClient.putIfAbsent(clientId, () => Reactive(<JobRequest>[]));

  @override
  Stream<List<JobRequest>> watchMyRequests(String clientId) {
    return _bucket(clientId).stream;
  }

  @override
  Stream<JobRequest?> watchRequest(String requestId) {
    final ctrl = StreamController<JobRequest?>();
    void emit() => ctrl.add(_requests[requestId]);
    emit();
    for (final bucket in _requestsByClient.values) {
      final sub = bucket.stream.listen((_) => emit());
      ctrl.onCancel = () => sub.cancel();
    }
    return ctrl.stream;
  }

  @override
  Stream<List<Acceptance>> watchAcceptances(String requestId) {
    return _acceptanceBucket(requestId).stream;
  }

  final Map<String, Reactive<List<Acceptance>>> _accBuckets = {};
  Reactive<List<Acceptance>> _acceptanceBucket(String requestId) =>
      _accBuckets.putIfAbsent(requestId, () => Reactive(<Acceptance>[]));

  @override
  Future<JobRequest> create(JobRequest req) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _requests[req.id] = req;
    _acceptances[req.id] = [];
    _accBuckets[req.id] = Reactive(<Acceptance>[]);
    _bucket(req.clientId).set([..._bucket(req.clientId).value, req]);
    return req;
  }

  @override
  Future<void> cancel(String requestId) async {
    final r = _requests[requestId];
    if (r == null) return;
    final updated = r.copyWith(status: RequestStatus.cancelled);
    _requests[requestId] = updated;
    _replaceInBucket(updated);
  }

  @override
  Future<void> declineAcceptor(String acceptanceId) async {
    for (final entry in _acceptances.entries) {
      final list = entry.value;
      final idx = list.indexWhere((a) => a.id == acceptanceId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(status: AcceptanceStatus.declined);
        _accBuckets[entry.key]?.set([...list]); // <-- pakai ?. untuk null safety
        return;
      }
    }
  }


  @override
  Future<void> updateAcceptance(Acceptance a) async {
    final list = _acceptances[a.requestId];
    if (list == null) return;
    final idx = list.indexWhere((x) => x.id == a.id);
    if (idx == -1) return;
    list[idx] = a;
    _accBuckets[a.requestId]?.set([...list]); // <-- pakai ?.
  }

  // Dipakai AgentSimulator
  void internalAddAcceptance(Acceptance a) {
    final r = _requests[a.requestId];
    if (r == null) return;
    if (r.status == RequestStatus.cancelled || r.status == RequestStatus.expired) return;
    
    final list = _acceptances[a.requestId];
    if (list == null) return; // <-- null check
    
    if (list.length >= r.acceptQuota) return;
    if (list.any((x) => x.agentId == a.agentId && x.status != AcceptanceStatus.declined)) return;
    
    list.add(a);
    _accBuckets[a.requestId]?.set([...list]); // <-- pakai ?.

    if (list.isNotEmpty) {
      final updated = r.copyWith(status: RequestStatus.hasAcceptors);
      _requests[r.id] = updated;
      _replaceInBucket(updated);
    }
    if (list.length >= r.acceptQuota) {
      final full = r.copyWith(status: RequestStatus.negotiating);
      _requests[r.id] = full;
      _replaceInBucket(full);
    }
  }

  JobRequest? getRequest(String id) => _requests[id];
  List<Acceptance> getAcceptances(String id) => _acceptances[id] ?? [];

  void _replaceInBucket(JobRequest r) {
    final bucket = _bucket(r.clientId);
    final list = [...bucket.value];
    final idx = list.indexWhere((x) => x.id == r.id);
    if (idx != -1) list[idx] = r;
    bucket.set(list);
  }

  int genId() => DateTime.now().microsecondsSinceEpoch.remainder(1 << 30);

  Random get rand => _rand;

  void seedDemoRequest(JobRequest r) {
    _requests[r.id] = r;
    _acceptances[r.id] = [];
    _accBuckets[r.id] = Reactive(<Acceptance>[]);
    final bucket = _bucket(r.clientId);
    bucket.set([...bucket.value, r]);
  }
}