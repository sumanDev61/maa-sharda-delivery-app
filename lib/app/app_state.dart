import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  AppState() {
    _seedData();
  }

  final settings = SettingsState();
  RiderState rider = RiderState();
  OrdersState orders = OrdersState();
  EarningsState earnings = EarningsState();

  bool get isLoggedIn => rider.session.isLoggedIn;

  void login({required String phone}) {
    rider.session = RiderSession(isLoggedIn: true, phone: phone);
    notifyListeners();
  }

  void logout() {
    rider = RiderState();
    orders = OrdersState();
    earnings = EarningsState();
    notifyListeners();
  }

  bool get isOnboardingComplete {
    final profile = rider.profile;
    return profile.name.trim().isNotEmpty &&
        profile.vehicle.type != VehicleType.unknown &&
        profile.bank.isComplete &&
        rider.profile.documents.mandatoryComplete;
  }

  void setOnline(bool value) {
    rider.isOnline = value;
    notifyListeners();
  }

  Future<void> simulateIncomingOrder() async {
    final request = OrderRequest.mock();
    orders.addRequest(request);
    notifyListeners();
    if (settings.orderAlertsEnabled) {
      if (settings.soundEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
    }
    if (settings.vibrationEnabled) {
      HapticFeedback.vibrate();
    }
  }

  void rejectOrder(int requestId, {String reason = 'Rejected'}) {
    final req = orders.removeRequest(requestId);
    if (req != null) {
      orders.history.insert(
        0,
        OrderHistoryItem.fromRequest(
          req,
          status: OrderStatus.rejected,
          note: reason,
        ),
      );
    }
    notifyListeners();
  }

  bool acceptOrder(int requestId) {
    final req = orders.removeRequest(requestId);
    if (req == null) return false;
    if (orders.active.length >= 2) {
      orders.requests.insert(0, req);
      return false;
    }
    final active = ActiveOrder.fromRequest(req);
    orders.active.insert(0, active);
    notifyListeners();
    return true;
  }

  void markReachedRestaurant(int orderId) {
    final order = orders.findActive(orderId);
    if (order == null) return;
    order.progress = DeliveryProgress.reachedRestaurant;
    notifyListeners();
  }

  bool confirmPickupOtp(int orderId, String otp) {
    final order = orders.findActive(orderId);
    if (order == null) return false;
    if (otp.trim() != order.pickupOtp) return false;
    order.progress = DeliveryProgress.pickedUp;
    notifyListeners();
    return true;
  }

  void markArrivedCustomer(int orderId) {
    final order = orders.findActive(orderId);
    if (order == null) return;
    order.progress = DeliveryProgress.arrivedCustomer;
    notifyListeners();
  }

  bool confirmDeliveryOtp(int orderId, String otp) {
    final order = orders.findActive(orderId);
    if (order == null) return false;
    if (otp.trim() != order.deliveryOtp) return false;
    order.progress = DeliveryProgress.delivered;
    completeOrder(orderId);
    return true;
  }

  void completeOrder(int orderId) {
    final order = orders.removeActive(orderId);
    if (order == null) return;
    orders.history.insert(0, OrderHistoryItem.fromActive(order));
    earnings.addTrip(
      TripEarning(
        orderId: order.id,
        createdAt: DateTime.now(),
        baseFare: order.fareBreakdown.baseFare,
        distanceFare: order.fareBreakdown.distanceFare,
        surge: order.fareBreakdown.surge,
        tips: order.fareBreakdown.tips,
        incentive: order.fareBreakdown.incentive,
        isCod: order.cashToCollect > 0,
        cashCollected: order.cashToCollect,
      ),
    );
    rider.metrics = rider.metrics.copyWith(
      completedTrips: rider.metrics.completedTrips + 1,
      rating: min(5, rider.metrics.rating + 0.01),
    );
    notifyListeners();
  }

  void updateGeneralInfo({
    required String name,
    String? email,
    String? address,
  }) {
    rider.profile = rider.profile.copyWith(
      name: name,
      email: email ?? rider.profile.email,
      address: address ?? rider.profile.address,
    );
    notifyListeners();
  }

  void updateVehicle({required VehicleType type, String? number}) {
    rider.profile = rider.profile.copyWith(
      vehicle: rider.profile.vehicle.copyWith(type: type, number: number),
    );
    notifyListeners();
  }

  void updateBank({
    required String holder,
    required String account,
    required String ifsc,
  }) {
    rider.profile = rider.profile.copyWith(
      bank: BankDetails(holderName: holder, accountNumber: account, ifsc: ifsc),
    );
    notifyListeners();
  }

  void setDocumentStatus(DocumentType type, DocumentStatus status) {
    final docs = rider.profile.documents.copyWithStatus(type, status);
    rider.profile = rider.profile.copyWith(documents: docs);
    notifyListeners();
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

  void _seedData() {
    final now = DateTime.now();
    
    // 1. Rider Profile & Verification
    rider.session = const RiderSession(isLoggedIn: true, phone: '+91 9876543210');
    rider.profile = const RiderProfile(
      name: 'Vaibhav',
      email: 'vaibhav@example.com',
      address: '123, Sharda Nagar, Jabalpur',
      vehicle: VehicleDetails(type: VehicleType.bike, number: 'MP 20 MS 1234'),
      bank: BankDetails(
        holderName: 'Vaibhav S',
        accountNumber: '123456789012',
        ifsc: 'SBIN0001234',
      ),
      documents: DocumentsState(
        idProof: DocumentStatus.verified,
        drivingLicense: DocumentStatus.verified,
        vehicleRc: DocumentStatus.pending,
      ),
      photoPath: 'https://i.pravatar.cc/150?u=rider',
    );
    rider.verification = VerificationStatus.verified;
    rider.isOnline = true;
    
    // 2. Earnings & Trip History
    final rng = Random();
    for (int i = 0; i < 15; i++) {
      final tripDate = now.subtract(Duration(days: rng.nextInt(7), hours: rng.nextInt(12)));
      final earning = TripEarning(
        orderId: 2000 + i,
        createdAt: tripDate,
        baseFare: 20.0,
        distanceFare: 15.0 + rng.nextInt(30),
        surge: rng.nextBool() ? 10.0 : 0.0,
        tips: rng.nextBool() ? 5.0 : 0.0,
        incentive: 4.0,
        isCod: rng.nextBool(),
        cashCollected: rng.nextBool() ? 150 + rng.nextInt(200) : 0,
      );
      earnings.addTrip(earning);
      
      // Also add to orders history
      orders.history.add(OrderHistoryItem(
        orderId: earning.orderId,
        restaurantName: ['Maa Sharda Fast Food', 'South Spice', 'Burger Box'][rng.nextInt(3)],
        dropArea: ['Sharda Nagar', 'Green Park', 'Civil Lines'][rng.nextInt(3)],
        status: OrderStatus.delivered,
        completedAt: tripDate,
        earning: earning.total,
        cashCollected: earning.cashCollected,
        note: '',
      ));
    }
    
    // 3. Active Order
    final activeReq = OrderRequest(
      id: 3001,
      restaurantName: 'South Spice',
      restaurantArea: 'Central Market',
      dropArea: 'Green Park colony',
      pickupDistanceKm: 1.2,
      deliveryDistanceKm: 3.5,
      etaMin: 15,
      expectedEarning: 55,
      cashToCollect: 0,
      createdAt: now.subtract(const Duration(minutes: 5)),
      expiresAt: now.add(const Duration(minutes: 25)),
    );
    orders.active.add(ActiveOrder.fromRequest(activeReq));
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
    required this.vehicle,
    required this.bank,
    required this.documents,
    required this.photoPath,
  });

  const RiderProfile.empty()
    : name = '',
      email = '',
      address = '',
      vehicle = const VehicleDetails(type: VehicleType.unknown, number: ''),
      bank = const BankDetails(holderName: '', accountNumber: '', ifsc: ''),
      documents = const DocumentsState.empty(),
      photoPath = '';

  final String name;
  final String email;
  final String address;
  final VehicleDetails vehicle;
  final BankDetails bank;
  final DocumentsState documents;
  final String photoPath;

  RiderProfile copyWith({
    String? name,
    String? email,
    String? address,
    VehicleDetails? vehicle,
    BankDetails? bank,
    DocumentsState? documents,
    String? photoPath,
  }) {
    return RiderProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      vehicle: vehicle ?? this.vehicle,
      bank: bank ?? this.bank,
      documents: documents ?? this.documents,
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
    );
  }
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
    final rng = Random();
    final pickupOtp = (1000 + rng.nextInt(9000)).toString();
    final deliveryOtp = (1000 + rng.nextInt(9000)).toString();
    return ActiveOrder(
      id: req.id,
      request: req,
      progress: DeliveryProgress.navigateRestaurant,
      pickupOtp: pickupOtp,
      deliveryOtp: deliveryOtp,
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
