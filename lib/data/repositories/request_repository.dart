import '../models/agent.dart';
import '../models/acceptance.dart';
import '../models/job_request.dart';

abstract class RequestRepository {
  Stream<List<JobRequest>> watchMyRequests(String clientId);
  Stream<JobRequest?> watchRequest(String requestId);
  Stream<List<Acceptance>> watchAcceptances(String requestId);
  Future<JobRequest> create(JobRequest req);
  Future<void> cancel(String requestId);
  Future<void> declineAcceptor(String acceptanceId);
  Future<void> updateAcceptance(Acceptance a);
  List<Agent> nearbyAgents(String categoryId, {double? lat, double? lng});
}