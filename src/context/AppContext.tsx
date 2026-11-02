import React, { createContext, useContext, useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  ActiveOrder,
  DeliveryProgress,
  DocumentStatus,
  DocumentType,
  OrderHistoryItem,
  OrderRequest,
  RiderMetrics,
  RiderProfile,
  RiderSession,
  SettingsState,
  TripEarning,
  VehicleType,
  VerificationStatus,
  FareBreakdown,
} from '../types';
import { api } from '../services/api';
import { useToast } from '../components/Toast';

interface RegisterData {
  name: string;
  phone: string;
  email: string;
  password?: string;
  vehicleType?: VehicleType;
  city?: string;
}

interface AppContextType {
  // Session & Auth
  session: RiderSession;
  isLoggedIn: boolean;
  isOnboardingComplete: boolean;
  isOnline: boolean;
  loginWithPassword: (identifier: string, password: string) => Promise<{ ok: boolean; error?: string }>;
  login: (phone: string, riderId?: string, token?: string) => Promise<void>;
  requestOtp: (phone: string) => Promise<{ ok: boolean; riderId?: string; error?: string }>;
  register: (data: RegisterData) => Promise<{ ok: boolean; riderId?: string; error?: string }>;
  verifyOtp: (phone: string, riderId: string, otp: string) => Promise<{ ok: boolean; isExistingUser?: boolean; error?: string }>;
  logout: () => void;

  // Profile & Verification
  profile: RiderProfile;
  verification: VerificationStatus;
  metrics: RiderMetrics;
  updateGeneralInfo: (info: { name: string; email?: string; address?: string; city?: string }) => Promise<void>;
  updateVehicle: (details: { type: VehicleType; number?: string; drivingLicenseNumber?: string }) => Promise<void>;
  updateBank: (details: { holder: string; account: string; ifsc: string }) => Promise<void>;
  setDocumentStatus: (type: DocumentType, status: DocumentStatus) => Promise<void>;
  uploadDocument: (type: DocumentType, fileData: string | File) => Promise<void>;
  setBackgroundVerification: (status: VerificationStatus) => void;
  refreshProfile: () => Promise<void>;

  // Attendance (local check-in diary)
  checkedInDays: string[];
  toggleAttendanceForToday: () => boolean;

  // Orders
  requests: OrderRequest[];
  activeOrders: ActiveOrder[];
  orderHistory: OrderHistoryItem[];
  fetchAvailableOrders: () => Promise<void>;
  acceptOrder: (requestId: string) => Promise<boolean>;
  rejectOrder: (requestId: string, reason?: string) => Promise<void>;
  markReachedRestaurant: (orderId: string) => Promise<void>;
  confirmPickupOtp: (orderId: string, otp: string) => Promise<boolean>;
  markArrivedCustomer: (orderId: string) => Promise<void>;
  confirmDeliveryOtp: (orderId: string, otp: string) => Promise<boolean>;
  completeOrder: (orderId: string) => Promise<void>;
  activeDeliveryOrder: ActiveOrder | null;
  setActiveDeliveryOrder: (order: ActiveOrder | null) => void;

  // Earnings
  trips: TripEarning[];
  todayTotal: number;
  weekTotal: number;
  monthTotal: number;
  codCashPending: number;
  refreshEarnings: (month?: Date) => Promise<void>;

  // Settings & Status
  settings: SettingsState;
  updateSettings: (newSettings: Partial<SettingsState>) => void;
  setOnline: (value: boolean) => Promise<void>;
  refreshOrders: () => Promise<void>;
}

const emptyProfile: RiderProfile = {
  name: '',
  email: '',
  address: '',
  city: '',
  vehicle: { type: 'unknown', number: '' },
  bank: { holderName: '', accountNumber: '', ifsc: '' },
  documents: { idProof: 'missing', drivingLicense: 'missing', vehicleRc: 'missing' },
  drivingLicenseNumber: '',
  photoPath: '',
};

// App document names <-> backend document keys
const DOC_KEY: Record<DocumentType, string> = { idProof: 'aadhar', drivingLicense: 'license', vehicleRc: 'rc' };
const mapDocStatus = (s: string): DocumentStatus =>
  s === 'approved' || s === 'verified' ? 'verified' : s === 'rejected' ? 'rejected' : s === 'pending' ? 'pending' : 'missing';
const mapApproval = (s: string): VerificationStatus =>
  s === 'approved' ? 'verified' : s === 'rejected' || s === 'suspended' ? 'rejected' : 'inReview';

const ACTIVE_STATUSES = ['DRIVER_ASSIGNED', 'DRIVER_ARRIVED_AT_MERCHANT', 'PICKED_UP', 'EN_ROUTE_TO_CUSTOMER', 'ARRIVED_AT_CUSTOMER'];
const progressFor = (status: string): DeliveryProgress => {
  switch (status) {
    case 'DRIVER_ARRIVED_AT_MERCHANT':
      return 'reachedRestaurant';
    case 'PICKED_UP':
      return 'pickedUp';
    case 'EN_ROUTE_TO_CUSTOMER':
      return 'navigateCustomer';
    case 'ARRIVED_AT_CUSTOMER':
      return 'arrivedCustomer';
    case 'DELIVERED':
      return 'delivered';
    default:
      return 'navigateRestaurant';
  }
};

const fareFrom = (o: any): FareBreakdown => {
  const b = o.earning_breakdown || {};
  return {
    baseFare: Number(b.base_pay || 0),
    distanceFare: Number(b.distance_pay || 0),
    surge: Number(b.surge || 0),
    tips: Number(b.tips || 0),
    incentive: Number(b.incentive || 0),
    total: Number(o.earning ?? b.total ?? 0),
  };
};

const formatAddress = (a: any) =>
  a ? [a.full_address, a.city, a.pincode].filter(Boolean).join(', ') : '';

/** Backend order -> rider app request (pool view or assigned view). */
const mapRequest = (o: any): OrderRequest => ({
  id: String(o.id),
  restaurantName: o.restaurant_name || o.restaurant || '',
  restaurantArea: o.restaurant_address || '',
  dropArea: o.delivery_address ? formatAddress(o.delivery_address) : o.drop_area || '',
  pickupDistanceKm: Number(o.pickup_distance_km ?? 0),
  deliveryDistanceKm: Number(o.delivery_distance_km ?? 0),
  totalDistanceKm: Number(o.total_distance_km ?? o.delivery_distance_km ?? 0),
  etaMin: Number(o.eta_minutes ?? 0),
  expectedEarning: Number(o.earning ?? 0),
  cashToCollect: Number(o.cash_to_collect ?? 0),
  createdAt: o.created_at || new Date().toISOString(),
  expiresAt: new Date(Date.now() + 5 * 60000).toISOString(),
  pickupOtp: '', // OTPs are never sent to the rider app; they are verified on the server
  deliveryOtp: '',
  orderAmount: Number(o.amount ?? 0),
  items: Array.isArray(o.items) ? o.items.map((it: any) => ({ name: it.name, quantity: it.quantity })) : [],
  // The dispatch pool hides line items (privacy) and only sends a count.
  itemsCount: Number(
    o.items_count ??
      (Array.isArray(o.items) ? o.items.reduce((s: number, it: any) => s + Number(it.quantity || 0), 0) : 0)
  ),
  foodReady: Boolean(o.ready),
  noContactDelivery: Boolean(o.no_contact_delivery),
  restaurantLat: o.restaurant_lat ?? null,
  restaurantLng: o.restaurant_lng ?? null,
  customerName: o.customer_name || '',
  customerPhone: o.customer_phone || '',
  dropLat: o.delivery_address?.lat ?? null,
  dropLng: o.delivery_address?.lng ?? null,
  instructions: o.instructions || '',
  paymentMethod: o.payment_method || '',
});

const mapActive = (o: any): ActiveOrder => {
  const req = mapRequest(o);
  return {
    id: req.id,
    request: req,
    progress: progressFor(o.status),
    pickupOtp: '',
    deliveryOtp: '',
    fareBreakdown: fareFrom(o),
    cashToCollect: req.cashToCollect,
  };
};

const AppContext = createContext<AppContextType | null>(null);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { showToast } = useToast();

  // Session: only a server-issued token counts as logged in
  const [session, setSession] = useState<RiderSession>(() => {
    const savedToken = localStorage.getItem('rider_token');
    const savedRiderId = localStorage.getItem('rider_id');
    if (savedToken && savedRiderId) {
      return {
        isLoggedIn: true,
        phone: localStorage.getItem('rider_phone') || '',
        riderId: savedRiderId,
        username: localStorage.getItem('rider_username') || '',
        name: localStorage.getItem('rider_name') || '',
        token: savedToken,
      };
    }
    return { isLoggedIn: false, phone: '' };
  });

  const [profile, setProfile] = useState<RiderProfile>(emptyProfile);
  const [verification, setVerification] = useState<VerificationStatus>('inReview');
  const [serverRating, setServerRating] = useState(0);
  const [serverDeliveries, setServerDeliveries] = useState(0);
  const [isOnline, setIsOnline] = useState<boolean>(false);

  const [checkedInDays, setCheckedInDays] = useState<string[]>(() => {
    const rid = localStorage.getItem('rider_id');
    try {
      return rid ? JSON.parse(localStorage.getItem(`rider_attendance_${rid}`) || '[]') : [];
    } catch {
      return [];
    }
  });

  const [settings, setSettings] = useState<SettingsState>(() => {
    try {
      const saved = localStorage.getItem('rider_settings');
      if (saved) return JSON.parse(saved);
    } catch {}
    return {
      orderAlertsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      shareLiveLocationEnabled: true,
      weatherAlertsEnabled: true,
      language: 'English',
    };
  });

  const [requests, setRequests] = useState<OrderRequest[]>([]);
  const [activeOrders, setActiveOrders] = useState<ActiveOrder[]>([]);
  const [orderHistory, setOrderHistory] = useState<OrderHistoryItem[]>([]);
  const [activeDeliveryOrder, setActiveDeliveryOrder] = useState<ActiveOrder | null>(null);
  const [trips, setTrips] = useState<TripEarning[]>([]);
  const [declined, setDeclined] = useState(0);

  useEffect(() => {
    if (session.riderId) localStorage.setItem(`rider_attendance_${session.riderId}`, JSON.stringify(checkedInDays));
  }, [checkedInDays, session.riderId]);

  useEffect(() => {
    localStorage.setItem('rider_settings', JSON.stringify(settings));
  }, [settings]);

  // ── Server sync ──

  const handleUnauthorized = useCallback(
    (status: number) => {
      if (status === 401 && session.isLoggedIn) {
        api.clearSession();
        setSession({ isLoggedIn: false, phone: '' });
        showToast('Session expired. Please login again.', 'error');
        return true;
      }
      return false;
    },
    [session.isLoggedIn, showToast]
  );

  const refreshProfile = useCallback(async () => {
    const res = await api.get('/v1/delivery/profile');
    if (!res.ok) {
      handleUnauthorized(res.status);
      return;
    }
    const p = res.data || {};
    setProfile({
      name: p.general?.name || '',
      email: p.general?.email || '',
      address: p.general?.address || '',
      city: p.general?.city || '',
      vehicle: { type: (p.vehicle?.type as VehicleType) || 'unknown', number: p.vehicle?.number || '' },
      bank: { holderName: p.bank?.account_name || '', accountNumber: p.bank?.account_number || '', ifsc: p.bank?.ifsc || '' },
      documents: {
        idProof: mapDocStatus(p.documents?.aadhar),
        drivingLicense: mapDocStatus(p.documents?.license),
        vehicleRc: mapDocStatus(p.documents?.rc),
      },
      drivingLicenseNumber: p.vehicle?.driving_license_number || '',
      photoPath: p.general?.photo_url || '',
    });
    setVerification(mapApproval(p.approval_status));
    setIsOnline(Boolean(p.is_online));
    setServerRating(Number(p.rating || 0));
    setServerDeliveries(Number(p.deliveries || 0));
  }, [handleUnauthorized]);

  const refreshMyOrders = useCallback(async () => {
    const res = await api.get('/v1/delivery/orders/my-orders');
    if (!res.ok || !Array.isArray(res.data)) {
      handleUnauthorized(res.status);
      return;
    }
    const active = res.data.filter((o: any) => ACTIVE_STATUSES.includes(o.status)).map(mapActive);
    setActiveOrders(active);
    setActiveDeliveryOrder((cur) => (cur ? active.find((a) => a.id === cur.id) || null : cur));
    setOrderHistory(
      res.data
        .filter((o: any) => !ACTIVE_STATUSES.includes(o.status))
        .map((o: any) => ({
          orderId: String(o.id),
          restaurantName: o.restaurant_name || '',
          dropArea: o.delivery_address ? formatAddress(o.delivery_address) : '',
          status: o.status === 'DELIVERED' ? 'delivered' : 'rejected',
          completedAt: o.delivered_at || o.updated_at || o.created_at,
          earning: o.status === 'DELIVERED' ? Number(o.earning || 0) : 0,
          cashCollected: o.status === 'DELIVERED' ? Number(o.cash_to_collect || 0) : 0,
          note:
            o.status === 'DELIVERED'
              ? o.payment_method === 'COD'
                ? `COD cash collected: ₹${o.cash_to_collect || 0}`
                : 'Prepaid online order'
              : String(o.status || '').replace(/_/g, ' ').toLowerCase(),
        }))
    );
  }, [handleUnauthorized]);

  const refreshEarnings = useCallback(async () => {
    const res = await api.get('/v1/delivery/trips');
    if (!res.ok || !Array.isArray(res.data)) return;
    setTrips(
      res.data.map((t: any) => ({
        orderId: String(t.order_id),
        createdAt: t.created_at,
        baseFare: Number(t.base_pay || 0),
        distanceFare: Number(t.distance_pay || 0),
        surge: Number(t.surge || 0),
        tips: Number(t.tips || 0),
        incentive: Number(t.incentive || 0),
        isCod: Number(t.cash_collected || 0) > 0,
        cashCollected: Number(t.cash_collected || 0),
        total: Number(t.amount || 0),
      }))
    );
  }, []);

  const fetchAvailableOrders = useCallback(async () => {
    if (!session.isLoggedIn || !isOnline || verification !== 'verified') {
      setRequests([]);
      return;
    }
    const res = await api.get('/v1/delivery/orders/available');
    if (res.ok && Array.isArray(res.data)) setRequests(res.data.map(mapRequest));
    else {
      handleUnauthorized(res.status);
      setRequests([]);
    }
  }, [session.isLoggedIn, isOnline, verification, handleUnauthorized]);

  // Initial load after login
  useEffect(() => {
    if (!session.isLoggedIn) return;
    refreshProfile();
    refreshMyOrders();
    refreshEarnings();
  }, [session.isLoggedIn, refreshProfile, refreshMyOrders, refreshEarnings]);

  // Pool: live via SSE, with a slow polling fallback
  useEffect(() => {
    if (!session.isLoggedIn) return;
    fetchAvailableOrders();
    const poll = setInterval(() => {
      fetchAvailableOrders();
      refreshMyOrders();
    }, 20000);
    let es: EventSource | null = null;
    const token = api.getToken();
    if (token && typeof EventSource !== 'undefined') {
      try {
        es = new EventSource(`${api.baseUrl}/v1/sse/delivery?token=${encodeURIComponent(token)}`);
        es.addEventListener('pool', () => fetchAvailableOrders());
        es.addEventListener('order', () => refreshMyOrders());
      } catch {}
    }
    return () => {
      clearInterval(poll);
      es?.close();
    };
  }, [session.isLoggedIn, fetchAvailableOrders, refreshMyOrders]);

  // Live location: sent while online (needed for dispatch radius and customer tracking)
  const lastSentRef = useRef(0);
  useEffect(() => {
    if (!session.isLoggedIn || !isOnline || !settings.shareLiveLocationEnabled || !('geolocation' in navigator)) return;
    const id = navigator.geolocation.watchPosition(
      (pos) => {
        const now = Date.now();
        if (now - lastSentRef.current < 15000) return;
        lastSentRef.current = now;
        api.put('/v1/delivery/location', { lat: pos.coords.latitude, lng: pos.coords.longitude });
      },
      () => showToast('Location permission is needed to receive nearby orders.', 'error'),
      { enableHighAccuracy: true, maximumAge: 10000, timeout: 20000 }
    );
    return () => navigator.geolocation.clearWatch(id);
  }, [session.isLoggedIn, isOnline, settings.shareLiveLocationEnabled, showToast]);

  const isOnboardingComplete = useMemo(
    () => profile.name.trim().length > 0 && profile.city.trim().length > 0 && profile.vehicle.type !== 'unknown',
    [profile]
  );

  // ── Auth ──

  // Riders authenticate with mobile OTP only; there is no password stored on the server.
  const loginWithPassword = async (): Promise<{ ok: boolean; error?: string }> => ({
    ok: false,
    error: 'Password login is not available. Please use Mobile OTP.',
  });

  const login = async (phone: string, riderId?: string, token?: string) => {
    if (!riderId || !token) {
      showToast('Login failed: missing server session.', 'error');
      return;
    }
    api.setAuthSession(token, riderId);
    localStorage.setItem('rider_phone', phone);
    setSession({ isLoggedIn: true, phone, riderId, token });
  };

  const requestOtp = async (phone: string): Promise<{ ok: boolean; riderId?: string; error?: string }> => {
    const cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone.length !== 10) return { ok: false, error: 'Please enter a valid 10-digit mobile number' };
    const res = await api.post('/v1/delivery/login', { phone: cleanPhone });
    if (!res.ok) return { ok: false, error: res.error || 'Rider account not found. Please register first.' };
    const riderId = res.data?.data?.rider_id;
    if (!riderId) return { ok: false, error: 'Unexpected server response' };
    return { ok: true, riderId };
  };

  /** Creates the rider account and sends an OTP; the rider is logged in only after verifyOtp(). */
  const register = async (data: RegisterData): Promise<{ ok: boolean; riderId?: string; error?: string }> => {
    const cleanPhone = data.phone.replace(/\D/g, '');
    const res = await api.post('/v1/delivery/register', { name: data.name, phone: cleanPhone, city: data.city || '' });
    if (!res.ok) return { ok: false, error: res.error || 'Registration failed. Phone may already be registered.' };
    const riderId = res.data?.data?.rider_id;
    if (!riderId) return { ok: false, error: 'Unexpected server response' };
    localStorage.setItem(`rider_pending_profile_${riderId}`, JSON.stringify({ email: data.email, vehicleType: data.vehicleType }));
    return { ok: true, riderId };
  };

  const verifyOtp = async (phone: string, riderId: string, otp: string): Promise<{ ok: boolean; isExistingUser?: boolean; error?: string }> => {
    if (!/^\d{4,6}$/.test(otp)) return { ok: false, error: 'Please enter the OTP' };
    if (!riderId) return { ok: false, error: 'Please request a new OTP' };
    const cleanPhone = phone.replace(/\D/g, '');
    const res = await api.post('/v1/delivery/verify-otp', { rider_id: riderId, otp });
    if (!res.ok) return { ok: false, error: res.error || 'Invalid OTP code. Verification failed.' };
    const token = res.data?.token || res.data?.data?.token;
    const riderObj = res.data?.rider || res.data?.data?.rider || {};
    if (!token || !riderObj.id) return { ok: false, error: 'Verification failed' };
    await login(cleanPhone, riderObj.id, token);
    localStorage.setItem('rider_name', riderObj.name || '');
    setVerification(mapApproval(riderObj.approval_status));

    // Apply details captured on the registration form (email / vehicle) once we have a session
    const pending = localStorage.getItem(`rider_pending_profile_${riderObj.id}`);
    if (pending) {
      try {
        const p = JSON.parse(pending);
        if (p.email) await api.put('/v1/delivery/profile', { email: p.email });
        if (p.vehicleType) await api.put('/v1/delivery/profile/vehicle', { type: p.vehicleType });
      } catch {}
      localStorage.removeItem(`rider_pending_profile_${riderObj.id}`);
    }
    return { ok: true, isExistingUser: true };
  };

  const logout = () => {
    if (isOnline) api.put('/v1/delivery/status', { online: false });
    api.clearSession();
    setSession({ isLoggedIn: false, phone: '' });
    setProfile(emptyProfile);
    setActiveOrders([]);
    setRequests([]);
    setTrips([]);
    setOrderHistory([]);
    setActiveDeliveryOrder(null);
    setIsOnline(false);
    showToast('Logged out securely.', 'info');
  };

  // ── Profile ──

  const ensureOk = (res: { ok: boolean; status: number; error?: string }, fallback: string) => {
    if (!res.ok) {
      handleUnauthorized(res.status);
      throw new Error(res.error || fallback);
    }
  };

  const updateGeneralInfo = async (info: { name: string; email?: string; address?: string; city?: string }) => {
    ensureOk(await api.put('/v1/delivery/profile', info), 'Could not update profile');
    await refreshProfile();
  };

  const updateVehicle = async (details: { type: VehicleType; number?: string; drivingLicenseNumber?: string }) => {
    ensureOk(
      await api.put('/v1/delivery/profile/vehicle', {
        type: details.type,
        number: details.number,
        driving_license_number: details.drivingLicenseNumber,
      }),
      'Could not update vehicle'
    );
    await refreshProfile();
  };

  const updateBank = async (details: { holder: string; account: string; ifsc: string }) => {
    ensureOk(
      await api.put('/v1/delivery/profile/bank', { account_name: details.holder, account_number: details.account, ifsc: details.ifsc }),
      'Could not update bank details'
    );
    await refreshProfile();
  };

  /** Riders can only submit a document for review; approval is done by admin. */
  const setDocumentStatus = async (type: DocumentType, _status: DocumentStatus) => {
    ensureOk(await api.post('/v1/delivery/profile/documents', { doc: DOC_KEY[type] }), 'Could not submit document');
    await refreshProfile();
  };

  const uploadDocument = async (type: DocumentType, fileData: string | File) => {
    if (typeof fileData === 'string') {
      // Already-hosted URL
      ensureOk(await api.post('/v1/delivery/profile/documents', { doc: DOC_KEY[type], url: fileData }), 'Upload failed');
    } else {
      ensureOk(await api.upload('/v1/delivery/profile/documents/upload', fileData, { doc: DOC_KEY[type] }), 'Upload failed');
    }
    await refreshProfile();
  };

  // Verification can only change on the server; this just re-reads it.
  const setBackgroundVerification = (_status: VerificationStatus) => {
    refreshProfile();
  };

  const toggleAttendanceForToday = () => {
    const today = new Date().toISOString().split('T')[0];
    const isNowCheckedIn = !checkedInDays.includes(today);
    setCheckedInDays(isNowCheckedIn ? [...checkedInDays, today] : checkedInDays.filter((d) => d !== today));
    return isNowCheckedIn;
  };

  const setOnline = async (value: boolean) => {
    const res = await api.put('/v1/delivery/status', { online: value });
    if (!res.ok) {
      handleUnauthorized(res.status);
      showToast(res.error || 'Could not change status', 'error');
      return;
    }
    setIsOnline(Boolean(res.data?.is_online));
    if (!value) setRequests([]);
  };

  const updateSettings = (newSettings: Partial<SettingsState>) => {
    setSettings((s) => ({ ...s, ...newSettings }));
    api.put('/v1/delivery/settings', {
      ...(newSettings.orderAlertsEnabled !== undefined ? { orderAlerts: newSettings.orderAlertsEnabled } : {}),
      ...(newSettings.soundEnabled !== undefined ? { sound: newSettings.soundEnabled } : {}),
      ...(newSettings.vibrationEnabled !== undefined ? { vibration: newSettings.vibrationEnabled } : {}),
      ...(newSettings.language ? { language: newSettings.language === 'Hindi' ? 'hi' : 'en' } : {}),
    });
  };

  // ── Order flow ──

  const replaceActive = (o: any) => {
    const mapped = mapActive(o);
    setActiveOrders((prev) => {
      const others = prev.filter((a) => a.id !== mapped.id);
      return ACTIVE_STATUSES.includes(o.status) ? [...others, mapped] : others;
    });
    setActiveDeliveryOrder((cur) => (cur && cur.id === mapped.id ? (ACTIVE_STATUSES.includes(o.status) ? mapped : null) : cur));
    return mapped;
  };

  const acceptOrder = async (requestId: string): Promise<boolean> => {
    const res = await api.post(`/v1/delivery/orders/${requestId}/accept`);
    setRequests((prev) => prev.filter((r) => r.id !== requestId));
    if (!res.ok) {
      handleUnauthorized(res.status);
      showToast(res.error || 'Order is no longer available', 'error');
      fetchAvailableOrders();
      return false;
    }
    const mapped = replaceActive(res.data);
    setActiveDeliveryOrder(mapped);
    showToast(`Order accepted! Head to ${mapped.request.restaurantName}`, 'success');
    return true;
  };

  const rejectOrder = async (requestId: string) => {
    const res = await api.post(`/v1/delivery/orders/${requestId}/reject`);
    if (!res.ok) {
      showToast(res.error || 'Could not decline order', 'error');
      return;
    }
    setDeclined((d) => d + 1);
    setRequests((prev) => prev.filter((r) => r.id !== requestId));
    setActiveOrders((prev) => prev.filter((o) => o.id !== requestId));
    setActiveDeliveryOrder((cur) => (cur?.id === requestId ? null : cur));
  };

  const moveTo = async (orderId: string, status: string, otp?: string) => {
    const res = await api.put(`/v1/delivery/orders/${orderId}/status`, { status, ...(otp ? { otp: otp.trim() } : {}) });
    if (!res.ok) {
      handleUnauthorized(res.status);
      return { ok: false, error: res.error || 'Update failed' };
    }
    replaceActive(res.data);
    return { ok: true };
  };

  const markReachedRestaurant = async (orderId: string) => {
    const r = await moveTo(orderId, 'DRIVER_ARRIVED_AT_MERCHANT');
    if (!r.ok) showToast(r.error!, 'error');
  };

  const confirmPickupOtp = async (orderId: string, otp: string): Promise<boolean> => {
    const r = await moveTo(orderId, 'PICKED_UP', otp);
    if (!r.ok) showToast(r.error!, 'error');
    return r.ok;
  };

  const markArrivedCustomer = async (orderId: string) => {
    const r = await moveTo(orderId, 'ARRIVED_AT_CUSTOMER');
    if (!r.ok) showToast(r.error!, 'error');
  };

  const confirmDeliveryOtp = async (orderId: string, otp: string): Promise<boolean> => {
    const r = await moveTo(orderId, 'DELIVERED', otp);
    if (!r.ok) {
      showToast(r.error!, 'error');
      return false;
    }
    await completeOrder(orderId);
    return true;
  };

  const completeOrder = async (_orderId?: string) => {
    await Promise.all([refreshMyOrders(), refreshEarnings(), refreshProfile()]);
    showToast('Order delivered! Earnings updated.', 'success');
  };

  const refreshOrders = async () => {
    await Promise.all([fetchAvailableOrders(), refreshMyOrders()]);
  };

  // ── Totals (from server trips) ──
  const sumWhere = (pred: (t: TripEarning) => boolean) => trips.filter(pred).reduce((s, t) => s + t.total, 0);
  const todayTotal = useMemo(() => sumWhere((t) => new Date(t.createdAt).toDateString() === new Date().toDateString()), [trips]);
  const weekTotal = useMemo(() => {
    const start = new Date();
    const day = start.getDay() || 7;
    start.setDate(start.getDate() - (day - 1));
    start.setHours(0, 0, 0, 0);
    return sumWhere((t) => new Date(t.createdAt) >= start);
  }, [trips]);
  const monthTotal = useMemo(() => {
    const n = new Date();
    return sumWhere((t) => {
      const d = new Date(t.createdAt);
      return d.getMonth() === n.getMonth() && d.getFullYear() === n.getFullYear();
    });
  }, [trips]);
  const codCashPending = useMemo(() => trips.filter((t) => t.isCod).reduce((s, t) => s + t.cashCollected, 0), [trips]);

  const metrics: RiderMetrics = useMemo(() => {
    const delivered = orderHistory.filter((h) => h.status === 'delivered').length;
    const accepted = delivered + activeOrders.length;
    return {
      rating: serverRating,
      acceptanceRate: accepted + declined > 0 ? accepted / (accepted + declined) : 0,
      completionRate: orderHistory.length > 0 ? delivered / orderHistory.length : 0,
      completedTrips: serverDeliveries,
    };
  }, [orderHistory, activeOrders.length, declined, serverRating, serverDeliveries]);

  const value: AppContextType = {
    session,
    isLoggedIn: session.isLoggedIn,
    isOnboardingComplete,
    isOnline,
    loginWithPassword,
    login,
    requestOtp,
    register,
    verifyOtp,
    logout,
    profile,
    verification,
    metrics,
    updateGeneralInfo,
    updateVehicle,
    updateBank,
    setDocumentStatus,
    uploadDocument,
    setBackgroundVerification,
    refreshProfile,
    checkedInDays,
    toggleAttendanceForToday,
    requests,
    activeOrders,
    orderHistory,
    fetchAvailableOrders,
    acceptOrder,
    rejectOrder,
    markReachedRestaurant,
    confirmPickupOtp,
    markArrivedCustomer,
    confirmDeliveryOtp,
    completeOrder,
    activeDeliveryOrder,
    setActiveDeliveryOrder,
    trips,
    todayTotal,
    weekTotal,
    monthTotal,
    codCashPending,
    refreshEarnings,
    settings,
    updateSettings,
    setOnline,
    refreshOrders,
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
};

export const useApp = (): AppContextType => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};
