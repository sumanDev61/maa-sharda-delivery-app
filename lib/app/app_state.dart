import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api/api_client.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    final state = scope?.notifier;
    if (state == null) {
      throw StateError('AppStateScope not found in widget tree.');
    }
    return state;
  }
}

class AppState extends ChangeNotifier {
  AppState();

  final settings = SettingsState();
  RiderState rider = RiderState();
  OrdersState orders = OrdersState();
  EarningsState earnings = EarningsState();
  StreamSubscription<String>? _sseSub;
  Timer? _autoRefreshTimer;

  bool get isLoggedIn => rider.session.isLoggedIn;

  Future<void> login({required String phone}) async {
    rider.session = RiderSession(isLoggedIn: true, phone: phone);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rider_phone', phone);
    } catch (_) {}
    await _initAfterLogin();
    _startRealtime();
  }

  void logout() {
    rider = RiderState();
    orders = OrdersState();
    earnings = EarningsState();
    _sseSub?.cancel();
    _autoRefreshTimer?.cancel();
    ApiClient().clearSession();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('rider_phone');
    });
    notifyListeners();
  }
  Future<void> _startRealtime() async {
    try {
      await ApiClient().init();
      final riderId = await _readRiderId();
      if (riderId == null) return;
      final uri = Uri.parse('${ApiClient.baseUrl}/v1/sse/delivery?rider_id=$riderId');
      final client = http.Client();
      final req = http.Request('GET', uri);
      req.headers['Accept'] = 'text/event-stream';
      final res = await client.send(req);
      _sseSub = res.stream.transform(utf8.decoder).listen((chunk) async {
        if (chunk.contains('data:')) {
          await fetchAvailableOrders();
        }
      });
    } catch (_) {}
  }
  Future<String?> _readRiderId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('rider_id');
    } catch (_) {
      return null;
    }
  }

  bool get isOnboardingComplete {
    final profile = rider.profile;
    return profile.name.trim().isNotEmpty &&
        profile.city.trim().isNotEmpty &&
        profile.vehicle.type != VehicleType.unknown &&
        profile.bank.isComplete &&
        rider.profile.documents.mandatoryComplete;
  }

  Future<void> setOnline(bool value) async {
    try {
      await ApiClient().put('/v1/delivery/status', body: {'online': value});
      rider.isOnline = value;
      notifyListeners();
    } catch (_) {}
  }

  final Map<int, String> _backendOrderId = {};
  int _idSeq = 10000;

  Future<void> fetchAvailableOrders() async {
    try {
      final res = await ApiClient().get('/v1/delivery/orders/available');
      final list = (await _decode(res)) as List<dynamic>;
      orders.requests.clear();
      for (final o in list) {
        final backendId = o['id'].toString();
        final rid = _idSeq++;
        _backendOrderId[rid] = backendId;
        final now = DateTime.now();
        final cash = o['payment_method']?.toString().toUpperCase() == 'CASH' ? (o['amount'] as num?)?.toInt() ?? 0 : 0;
        final amount = (o['amount'] as num?)?.toInt() ?? 0;
        final items = _parseItems(o['items']);
        final estEarn = _estimateEarning(amount, items.length);
        final req = OrderRequest(
          id: rid,
          restaurantName: o['restaurant']?.toString() ?? '',
          restaurantArea: '',
          dropArea: _addressLabel(o['delivery_address']),
          pickupDistanceKm: 0,
          deliveryDistanceKm: 0,
          etaMin: (o['prep_time_minutes'] as num?)?.toInt() ?? 15,
          expectedEarning: estEarn,
          cashToCollect: cash,
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 30)),
          pickupOtp: (o['pickup_otp'] as String?) ?? '',
          deliveryOtp: (o['delivery_otp'] as String?) ?? '',
          orderAmount: amount,
          items: items,
        );
        orders.addRequest(req);
      }
      notifyListeners();
      if (settings.orderAlertsEnabled) {
        if (settings.soundEnabled) {
          SystemSound.play(SystemSoundType.alert);
        }
      }
      if (settings.vibrationEnabled) {
        HapticFeedback.vibrate();
      }
    } catch (_) {}
  }

  Future<void> rejectOrder(int requestId, {String reason = 'Rejected'}) async {
    final req = orders.removeRequest(requestId);
    final backendId = _backendOrderId[requestId];
    if (backendId != null) {
      try {
        await ApiClient().post('/v1/delivery/orders/$backendId/reject');
      } catch (_) {}
    }
    if (req != null) {
      orders.history.insert(0, OrderHistoryItem.fromRequest(req, status: OrderStatus.rejected, note: reason));
    }
    notifyListeners();
  }

  Future<bool> acceptOrder(int requestId) async {
    final req = orders.removeRequest(requestId);
    if (req == null) return false;
    if (orders.active.length >= 2) {
      orders.requests.insert(0, req);
      return false;
    }
    final backendId = _backendOrderId[requestId];
    if (backendId != null) {
      try {
        await ApiClient().post('/v1/delivery/orders/$backendId/accept');
      } catch (_) {}
    }
    final active = ActiveOrder.fromRequest(req);
    orders.active.insert(0, active);
    notifyListeners();
    return true;
  }

  Future<void> markReachedRestaurant(int orderId) async {
    final order = orders.findActive(orderId);
    if (order == null) return;
    final backendId = _backendOrderId[orderId];
    if (backendId != null) {
      try {
        await ApiClient().put('/v1/delivery/orders/$backendId/status', body: {'status': 'DRIVER_ARRIVED_AT_MERCHANT'});
      } catch (_) {}
    }
    order.progress = DeliveryProgress.reachedRestaurant;
    notifyListeners();
  }

  Future<bool> confirmPickupOtp(int orderId, String otp) async {
    final order = orders.findActive(orderId);
    if (order == null) return false;
    if (otp.trim() != order.pickupOtp) return false;
    final backendId = _backendOrderId[orderId];
    if (backendId != null) {
      try {
        await ApiClient().put('/v1/delivery/orders/$backendId/status', body: {'status': 'PICKED_UP'});
      } catch (_) {}
    }
    order.progress = DeliveryProgress.pickedUp;
    notifyListeners();
    return true;
  }

  Future<void> markArrivedCustomer(int orderId) async {
    final order = orders.findActive(orderId);
    if (order == null) return;
    final backendId = _backendOrderId[orderId];
    if (backendId != null) {
      try {
        await ApiClient().put('/v1/delivery/orders/$backendId/status', body: {'status': 'ARRIVED_AT_CUSTOMER'});
      } catch (_) {}
    }
    order.progress = DeliveryProgress.arrivedCustomer;
    notifyListeners();
  }

  Future<bool> confirmDeliveryOtp(int orderId, String otp) async {
    final order = orders.findActive(orderId);
    if (order == null) return false;
    if (otp.trim() != order.deliveryOtp) return false;
    final backendId = _backendOrderId[orderId];
    if (backendId != null) {
      try {
        await ApiClient().put('/v1/delivery/orders/$backendId/status', body: {'status': 'DELIVERED'});
      } catch (_) {}
    }
    order.progress = DeliveryProgress.delivered;
    await completeOrder(orderId);
    return true;
  }

  Future<void> completeOrder(int orderId) async {
    final order = orders.removeActive(orderId);
    if (order == null) return;
    orders.history.insert(0, OrderHistoryItem.fromActive(order));
    await _loadTrips();
    rider.metrics = rider.metrics.copyWith(
      completedTrips: rider.metrics.completedTrips + 1,
      rating: min(5, rider.metrics.rating + 0.01),
    );
    notifyListeners();
  }

  Future<void> updateGeneralInfo({
    required String name,
    String? email,
    String? address,
    String? city,
  }) async {
    try {
      await ApiClient().put('/v1/delivery/profile', body: {
        'name': name,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
      });
    } catch (_) {}
    rider.profile = rider.profile.copyWith(
      name: name,
      email: email ?? rider.profile.email,
      address: address ?? rider.profile.address,
      city: city ?? rider.profile.city,
    );
    notifyListeners();
  }

  Future<void> updateVehicle({
    required VehicleType type,
    String? number,
    String? drivingLicenseNumber,
  }) async {
    try {
      await ApiClient().put('/v1/delivery/profile/vehicle', body: {
        'type': switch (type) { VehicleType.bike => 'bike', VehicleType.scooter => 'scooter', VehicleType.cycle => 'cycle', _ => 'unknown' },
        if (number != null) 'number': number,
        if (drivingLicenseNumber != null) 'driving_license_number': drivingLicenseNumber,
      });
    } catch (_) {}
    rider.profile = rider.profile.copyWith(
      vehicle: rider.profile.vehicle.copyWith(type: type, number: number),
      drivingLicenseNumber: drivingLicenseNumber ?? rider.profile.drivingLicenseNumber,
    );
    notifyListeners();
  }

  Future<void> updateBank({
    required String holder,
    required String account,
    required String ifsc,
  }) async {
    try {
      await ApiClient().put('/v1/delivery/profile/bank', body: {
        'account_name': holder,
        'account_number': account,
        'ifsc': ifsc,
      });
    } catch (_) {}
    rider.profile = rider.profile.copyWith(
      bank: BankDetails(holderName: holder, accountNumber: account, ifsc: ifsc),
    );
    notifyListeners();
  }

  Future<void> setDocumentStatus(DocumentType type, DocumentStatus status) async {
    final doc = switch (type) { DocumentType.idProof => 'aadhar', DocumentType.drivingLicense => 'license', DocumentType.vehicleRc => 'rc' };
    try {
      await ApiClient().post('/v1/delivery/profile/documents', body: {'doc': doc, 'status': switch (status) { DocumentStatus.verified => 'verified', DocumentStatus.pending => 'pending', DocumentStatus.rejected => 'rejected', _ => 'missing' }});
    } catch (_) {}
    final docs = rider.profile.documents.copyWithStatus(type, status);
    rider.profile = rider.profile.copyWith(documents: docs);
    notifyListeners();
  }

  Future<void> uploadDocument({
    required DocumentType type,
    required File file,
  }) async {
    final doc = switch (type) { DocumentType.idProof => 'aadhar', DocumentType.drivingLicense => 'license', DocumentType.vehicleRc => 'rc' };
    try {
      await ApiClient().uploadRiderDocument(doc: doc, file: file);
      final docs = rider.profile.documents.copyWithStatus(type, DocumentStatus.pending);
      rider.profile = rider.profile.copyWith(documents: docs);
      notifyListeners();
    } catch (_) {}
  }

  void setBackgroundVerification(VerificationStatus status) {
    rider.verification = status;
    notifyListeners();
  }

  bool toggleAttendanceForToday() {
    final key = _dayKey(DateTime.now());
    if (rider.attendance.checkedInDays.contains(key)) {
      rider.attendance.checkedInDays.remove(key);
      notifyListeners();
      return false;
    }
    rider.attendance.checkedInDays.add(key);
    notifyListeners();
    return true;
  }

  static String _dayKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _initAfterLogin() async {
    await Future.wait([
      _loadProfile(),
      _loadSettings(),
      _loadTrips(),
      _loadMyOrders(),
      fetchAvailableOrders(),
    ]);
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!rider.isOnline) return;
      await Future.wait([
        fetchAvailableOrders(),
        _loadMyOrders(),
        _loadTrips(),
      ]);
    });
  }

  Future<void> restoreSession() async {
    try {
      await ApiClient().init();
      final prefs = await SharedPreferences.getInstance();
      final riderId = prefs.getString('rider_id');
      final phone = prefs.getString('rider_phone') ?? '';
      if (riderId != null && riderId.isNotEmpty) {
        rider.session = RiderSession(isLoggedIn: true, phone: phone);
        notifyListeners();
        await _initAfterLogin();
        _startRealtime();
      }
    } catch (_) {}
  }

  Future<void> refreshOrders() async {
    await Future.wait([
      fetchAvailableOrders(),
      _loadMyOrders(),
    ]);
  }

  Future<void> refreshEarnings() async {
    await _loadTrips();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiClient().get('/v1/delivery/profile');
      final data = await _decode(res) as Map<String, dynamic>;
      final g = data['general'] as Map<String, dynamic>;
      final v = data['vehicle'] as Map<String, dynamic>;
      final b = data['bank'] as Map<String, dynamic>;
      final d = data['documents'] as Map<String, dynamic>;
      final vt = switch ((v['type'] ?? 'unknown').toString()) { 'bike' => VehicleType.bike, 'scooter' => VehicleType.scooter, 'cycle' => VehicleType.cycle, _ => VehicleType.unknown };
      final approval = (data['approval_status'] ?? '').toString();
      rider.profile = RiderProfile(
        name: g['name']?.toString() ?? '',
        email: g['email']?.toString() ?? '',
        address: g['address']?.toString() ?? '',
        city: g['city']?.toString() ?? '',
        vehicle: VehicleDetails(type: vt, number: v['number']?.toString() ?? ''),
        bank: BankDetails(holderName: b['account_name']?.toString() ?? '', accountNumber: b['account_number']?.toString() ?? '', ifsc: b['ifsc']?.toString() ?? ''),
        documents: DocumentsState(
          idProof: _docStatus(d['aadhar']?.toString()),
          drivingLicense: _docStatus(d['license']?.toString()),
          vehicleRc: _docStatus(d['rc']?.toString()),
        ),
        drivingLicenseNumber: v['driving_license_number']?.toString() ?? '',
        photoPath: rider.profile.photoPath,
      );
      rider.verification = _mapApprovalStatus(approval);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient().get('/v1/delivery/settings');
      final s = await _decode(res) as Map<String, dynamic>;
      settings.orderAlertsEnabled = s['orderAlerts'] == true;
      settings.soundEnabled = s['sound'] == true;
      settings.vibrationEnabled = s['vibration'] == true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadTrips() async {
    try {
      final res = await ApiClient().get('/v1/delivery/trips');
      final list = (await _decode(res)) as List<dynamic>;
      earnings.trips.clear();
      for (final t in list) {
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        final cash = (t['cash_collected'] as num?)?.toInt() ?? 0;
        final created = DateTime.tryParse(t['created_at']?.toString() ?? '') ?? DateTime.now();
        earnings.addTrip(TripEarning(
          orderId: 0,
          createdAt: created,
          baseFare: amount,
          distanceFare: 0,
          surge: 0,
          tips: 0,
          incentive: 0,
          isCod: cash > 0,
          cashCollected: cash,
        ));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadMyOrders() async {
    try {
      final res = await ApiClient().get('/v1/delivery/orders/my-orders');
      final list = (await _decode(res)) as List<dynamic>;
      orders.history.clear();
      for (final o in list) {
        final rid = _idSeq++;
        _backendOrderId[rid] = o['id'].toString();
        final status = (o['status']?.toString() ?? '').toUpperCase() == 'DELIVERED' ? OrderStatus.delivered : OrderStatus.accepted;
        orders.history.add(OrderHistoryItem(
          orderId: rid,
          restaurantName: o['restaurant']?.toString() ?? '',
          dropArea: '',
          status: status,
          completedAt: DateTime.tryParse(o['created_at']?.toString() ?? '') ?? DateTime.now(),
          earning: (o['amount'] as num?)?.toDouble() ?? 0.0,
          cashCollected: o['payment_method']?.toString().toUpperCase() == 'CASH' ? (o['amount'] as num?)?.toInt() ?? 0 : 0,
          note: '',
        ));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<dynamic> _decode(dynamic res) async {
    return jsonDecode(res.body);
  }

  DocumentStatus _docStatus(String? v) {
    final s = (v ?? '').toLowerCase();
    return switch (s) {
      'verified' => DocumentStatus.verified,
      'pending' => DocumentStatus.pending,
      'rejected' => DocumentStatus.rejected,
      _ => DocumentStatus.missing,
    };
  }

  static VerificationStatus _mapApprovalStatus(String raw) {
    final s = raw.toLowerCase().trim();
    return switch (s) {
      'approved' => VerificationStatus.verified,
      'inreview' => VerificationStatus.inReview,
      'rejected' => VerificationStatus.rejected,
      'suspended' => VerificationStatus.pending,
      _ => VerificationStatus.pending,
    };
  }

  List<OrderItem> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final m = e is Map ? e.cast<String, dynamic>() : <String, dynamic>{};
      final name = m['name']?.toString() ?? m['title']?.toString() ?? 'Item';
      final qty = (m['quantity'] as num?)?.toInt() ?? (m['qty'] as num?)?.toInt() ?? 1;
      return OrderItem(name: name, quantity: qty);
    }).toList();
  }

  int _estimateEarning(int orderAmount, int itemCount) {
    if (orderAmount <= 0) return 30;
    final base = (orderAmount * 0.18).round();
    final bonus = (itemCount * 2);
    return (base + bonus).clamp(30, 250);
  }

  String _addressLabel(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final m = raw.cast<String, dynamic>();
      final line1 = m['address_line1']?.toString() ?? '';
      final line2 = m['address_line2']?.toString() ?? '';
      final city = m['city']?.toString() ?? '';
      final parts = [line1, line2, city].where((e) => e.trim().isNotEmpty).toList();
      return parts.isEmpty ? '' : parts.join(', ');
    }
    return '';
  }
}

class SettingsState {
  bool orderAlertsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool shareLiveLocationEnabled = false;
  bool weatherAlertsEnabled = true;
}

class RiderState {
  RiderSession session = const RiderSession(isLoggedIn: false, phone: '');
  RiderProfile profile = const RiderProfile.empty();
  VerificationStatus verification = VerificationStatus.pending;
  bool isOnline = true;
  AttendanceState attendance = AttendanceState();
  RiderMetrics metrics = const RiderMetrics(
    rating: 4.8,
    acceptanceRate: 0.86,
    completionRate: 0.93,
    completedTrips: 0,
  );
}

class AttendanceState {
  final Set<String> checkedInDays = {};
}

class OrdersState {
  final List<OrderRequest> requests = [];
  final List<ActiveOrder> active = [];
  final List<OrderHistoryItem> history = [];

  void addRequest(OrderRequest request) {
    requests.insert(0, request);
  }

  OrderRequest? removeRequest(int id) {
    final index = requests.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    return requests.removeAt(index);
  }

  ActiveOrder? findActive(int id) {
    final index = active.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    return active[index];
  }

  ActiveOrder? removeActive(int id) {
    final index = active.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    return active.removeAt(index);
  }
}

class EarningsState {
  final List<TripEarning> trips = [];

  void addTrip(TripEarning trip) {
    trips.insert(0, trip);
  }

  double get todayTotal {
    final now = DateTime.now();
    return trips
        .where(
          (t) =>
              t.createdAt.year == now.year &&
              t.createdAt.month == now.month &&
              t.createdAt.day == now.day,
        )
        .fold(0, (sum, t) => sum + t.total);
  }

  double get weekTotal {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return trips
        .where(
          (t) =>
              t.createdAt.isAfter(DateTime(start.year, start.month, start.day)),
        )
        .fold(0, (s, t) => s + t.total);
  }

  double get monthTotal {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return trips
        .where((t) => t.createdAt.isAfter(start))
        .fold(0, (s, t) => s + t.total);
  }

  int get codCashPending =>
      trips.where((t) => t.isCod).fold(0, (s, t) => s + t.cashCollected);
}

enum VerificationStatus { pending, inReview, verified, rejected }

enum VehicleType { unknown, bike, scooter, cycle }

class RiderSession {
  const RiderSession({required this.isLoggedIn, required this.phone});

  final bool isLoggedIn;
  final String phone;
}

class RiderProfile {
  const RiderProfile({
    required this.name,
    required this.email,
    required this.address,
    required this.city,
    required this.vehicle,
    required this.bank,
    required this.documents,
    required this.drivingLicenseNumber,
    required this.photoPath,
  });

  const RiderProfile.empty()
    : name = '',
      email = '',
      address = '',
      city = '',
      vehicle = const VehicleDetails(type: VehicleType.unknown, number: ''),
      bank = const BankDetails(holderName: '', accountNumber: '', ifsc: ''),
      documents = const DocumentsState.empty(),
      drivingLicenseNumber = '',
      photoPath = '';

  final String name;
  final String email;
  final String address;
  final String city;
  final VehicleDetails vehicle;
  final BankDetails bank;
  final DocumentsState documents;
  final String drivingLicenseNumber;
  final String photoPath;

  RiderProfile copyWith({
    String? name,
    String? email,
    String? address,
    String? city,
    VehicleDetails? vehicle,
    BankDetails? bank,
    DocumentsState? documents,
    String? drivingLicenseNumber,
    String? photoPath,
  }) {
    return RiderProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      vehicle: vehicle ?? this.vehicle,
      bank: bank ?? this.bank,
      documents: documents ?? this.documents,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

class VehicleDetails {
  const VehicleDetails({required this.type, required this.number});

  final VehicleType type;
  final String number;

  bool get isComplete => type != VehicleType.unknown && number.trim().isNotEmpty;

  VehicleDetails copyWith({VehicleType? type, String? number}) {
    return VehicleDetails(
      type: type ?? this.type,
      number: number ?? this.number,
    );
  }
}

class BankDetails {
  const BankDetails({
    required this.holderName,
    required this.accountNumber,
    required this.ifsc,
  });

  final String holderName;
  final String accountNumber;
  final String ifsc;

  bool get isComplete =>
      holderName.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty &&
      ifsc.trim().isNotEmpty;
}

enum DocumentType { idProof, drivingLicense, vehicleRc }

enum DocumentStatus { missing, pending, verified, rejected }

class DocumentsState {
  const DocumentsState({
    required this.idProof,
    required this.drivingLicense,
    required this.vehicleRc,
  });

  const DocumentsState.empty()
    : idProof = DocumentStatus.missing,
      drivingLicense = DocumentStatus.missing,
      vehicleRc = DocumentStatus.missing;

  final DocumentStatus idProof;
  final DocumentStatus drivingLicense;
  final DocumentStatus vehicleRc;

  bool get mandatoryComplete =>
      idProof != DocumentStatus.missing &&
      drivingLicense != DocumentStatus.missing &&
      vehicleRc != DocumentStatus.missing;

  DocumentsState copyWithStatus(DocumentType type, DocumentStatus status) {
    return switch (type) {
      DocumentType.idProof => DocumentsState(
        idProof: status,
        drivingLicense: drivingLicense,
        vehicleRc: vehicleRc,
      ),
      DocumentType.drivingLicense => DocumentsState(
        idProof: idProof,
        drivingLicense: status,
        vehicleRc: vehicleRc,
      ),
      DocumentType.vehicleRc => DocumentsState(
        idProof: idProof,
        drivingLicense: drivingLicense,
        vehicleRc: status,
      ),
    };
  }
}

class RiderMetrics {
  const RiderMetrics({
    required this.rating,
    required this.acceptanceRate,
    required this.completionRate,
    required this.completedTrips,
  });

  final double rating;
  final double acceptanceRate;
  final double completionRate;
  final int completedTrips;

  RiderMetrics copyWith({
    double? rating,
    double? acceptanceRate,
    double? completionRate,
    int? completedTrips,
  }) {
    return RiderMetrics(
      rating: rating ?? this.rating,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      completionRate: completionRate ?? this.completionRate,
      completedTrips: completedTrips ?? this.completedTrips,
    );
  }
}

enum OrderStatus { pending, accepted, delivered, rejected }

class OrderRequest {
  OrderRequest({
    required this.id,
    required this.restaurantName,
    required this.restaurantArea,
    required this.dropArea,
    required this.pickupDistanceKm,
    required this.deliveryDistanceKm,
    required this.etaMin,
    required this.expectedEarning,
    required this.cashToCollect,
    required this.createdAt,
    required this.expiresAt,
    this.pickupOtp = '',
    this.deliveryOtp = '',
    this.orderAmount = 0,
    this.items = const [],
  });

  final int id;
  final String restaurantName;
  final String restaurantArea;
  final String dropArea;
  final double pickupDistanceKm;
  final double deliveryDistanceKm;
  final int etaMin;
  final int expectedEarning;
  final int cashToCollect;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String pickupOtp;
  final String deliveryOtp;
  final int orderAmount;
  final List<OrderItem> items;

  double get totalDistanceKm => pickupDistanceKm + deliveryDistanceKm;

  static int _seq = 1000;

  static OrderRequest mock() {
    final rng = Random();
    final id = _seq++;
    final pickup = (rng.nextDouble() * 2.0) + 0.4;
    final delivery = (rng.nextDouble() * 4.0) + 0.8;
    final eta = 10 + rng.nextInt(20);
    final earn = 35 + rng.nextInt(60);
    final cod = rng.nextBool() ? 0 : 80 + rng.nextInt(240);
    final now = DateTime.now();
    return OrderRequest(
      id: id,
      restaurantName: [
        'Maa Sharda Fast Food',
        'South Spice',
        'Burger Box',
        'Cafe Chai',
      ][rng.nextInt(4)],
      restaurantArea: [
        'Main Road',
        'City Center',
        'Station',
        'Market',
      ][rng.nextInt(4)],
      dropArea: [
        'Sharda Nagar',
        'Green Park',
        'Civil Lines',
        'New Colony',
      ][rng.nextInt(4)],
      pickupDistanceKm: double.parse(pickup.toStringAsFixed(1)),
      deliveryDistanceKm: double.parse(delivery.toStringAsFixed(1)),
      etaMin: eta,
      expectedEarning: earn,
      cashToCollect: cod,
      createdAt: now,
      expiresAt: now.add(const Duration(seconds: 30)),
      orderAmount: 320,
      items: const [
        OrderItem(name: 'Paneer Wrap', quantity: 1),
        OrderItem(name: 'Lassi', quantity: 2),
      ],
    );
  }
}

class OrderItem {
  const OrderItem({required this.name, required this.quantity});
  final String name;
  final int quantity;
}

enum DeliveryProgress {
  navigateRestaurant,
  reachedRestaurant,
  pickedUp,
  navigateCustomer,
  arrivedCustomer,
  delivered,
}

class FareBreakdown {
  const FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.surge,
    required this.tips,
    required this.incentive,
  });

  final double baseFare;
  final double distanceFare;
  final double surge;
  final double tips;
  final double incentive;

  double get total => baseFare + distanceFare + surge + tips + incentive;

  static FareBreakdown fromRequest(OrderRequest req) {
    final base = 18.0;
    final distance = (req.totalDistanceKm * 6.5);
    final surge = req.etaMin < 15 ? 8.0 : 0.0;
    final tips = req.cashToCollect == 0 ? 5.0 : 0.0;
    final incentive = 4.0;
    return FareBreakdown(
      baseFare: base,
      distanceFare: distance,
      surge: surge,
      tips: tips,
      incentive: incentive,
    );
  }
}

class ActiveOrder {
  ActiveOrder({
    required this.id,
    required this.request,
    required this.progress,
    required this.pickupOtp,
    required this.deliveryOtp,
    required this.fareBreakdown,
  });

  final int id;
  final OrderRequest request;
  DeliveryProgress progress;
  final String pickupOtp;
  final String deliveryOtp;
  final FareBreakdown fareBreakdown;

  int get cashToCollect => request.cashToCollect;

  static ActiveOrder fromRequest(OrderRequest req) {
    return ActiveOrder(
      id: req.id,
      request: req,
      progress: DeliveryProgress.navigateRestaurant,
      pickupOtp: req.pickupOtp,
      deliveryOtp: req.deliveryOtp,
      fareBreakdown: FareBreakdown.fromRequest(req),
    );
  }
}

class OrderHistoryItem {
  OrderHistoryItem({
    required this.orderId,
    required this.restaurantName,
    required this.dropArea,
    required this.status,
    required this.completedAt,
    required this.earning,
    required this.cashCollected,
    required this.note,
  });

  final int orderId;
  final String restaurantName;
  final String dropArea;
  final OrderStatus status;
  final DateTime completedAt;
  final double earning;
  final int cashCollected;
  final String note;

  static OrderHistoryItem fromActive(ActiveOrder order) {
    return OrderHistoryItem(
      orderId: order.id,
      restaurantName: order.request.restaurantName,
      dropArea: order.request.dropArea,
      status: OrderStatus.delivered,
      completedAt: DateTime.now(),
      earning: order.fareBreakdown.total,
      cashCollected: order.cashToCollect,
      note: '',
    );
  }

  static OrderHistoryItem fromRequest(
    OrderRequest req, {
    required OrderStatus status,
    required String note,
  }) {
    return OrderHistoryItem(
      orderId: req.id,
      restaurantName: req.restaurantName,
      dropArea: req.dropArea,
      status: status,
      completedAt: DateTime.now(),
      earning: 0,
      cashCollected: 0,
      note: note,
    );
  }
}

class TripEarning {
  TripEarning({
    required this.orderId,
    required this.createdAt,
    required this.baseFare,
    required this.distanceFare,
    required this.surge,
    required this.tips,
    required this.incentive,
    required this.isCod,
    required this.cashCollected,
  });

  final int orderId;
  final DateTime createdAt;
  final double baseFare;
  final double distanceFare;
  final double surge;
  final double tips;
  final double incentive;
  final bool isCod;
  final int cashCollected;

  double get total => baseFare + distanceFare + surge + tips + incentive;
}
