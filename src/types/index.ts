export type VerificationStatus = 'pending' | 'inReview' | 'verified' | 'rejected';

export type VehicleType = 'unknown' | 'bike' | 'scooter' | 'cycle';

export type DocumentType = 'idProof' | 'drivingLicense' | 'vehicleRc';

export type DocumentStatus = 'missing' | 'pending' | 'verified' | 'rejected';

export type DeliveryProgress =
  | 'navigateRestaurant'
  | 'reachedRestaurant'
  | 'pickedUp'
  | 'navigateCustomer'
  | 'arrivedCustomer'
  | 'delivered';

export type OrderStatus = 'pending' | 'accepted' | 'delivered' | 'rejected';

export interface OrderItem {
  name: string;
  quantity: number;
}

export interface OrderRequest {
  id: number;
  restaurantName: string;
  restaurantArea: string;
  dropArea: string;
  pickupDistanceKm: number;
  deliveryDistanceKm: number;
  totalDistanceKm: number;
  etaMin: number;
  expectedEarning: number;
  cashToCollect: number;
  createdAt: string; // ISO string
  expiresAt: string; // ISO string
  pickupOtp: string;
  deliveryOtp: string;
  orderAmount: number;
  items: OrderItem[];
}

export interface FareBreakdown {
  baseFare: number;
  distanceFare: number;
  surge: number;
  tips: number;
  incentive: number;
  total: number;
}

export interface ActiveOrder {
  id: number;
  request: OrderRequest;
  progress: DeliveryProgress;
  pickupOtp: string;
  deliveryOtp: string;
  fareBreakdown: FareBreakdown;
  cashToCollect: number;
}

export interface OrderHistoryItem {
  orderId: number;
  restaurantName: string;
  dropArea: string;
  status: OrderStatus;
  completedAt: string;
  earning: number;
  cashCollected: number;
  note: string;
}

export interface TripEarning {
  orderId: number;
  createdAt: string;
  baseFare: number;
  distanceFare: number;
  surge: number;
  tips: number;
  incentive: number;
  isCod: boolean;
  cashCollected: number;
  total: number;
}

export interface DocumentsState {
  idProof: DocumentStatus;
  drivingLicense: DocumentStatus;
  vehicleRc: DocumentStatus;
}

export interface VehicleDetails {
  type: VehicleType;
  number: string;
}

export interface BankDetails {
  holderName: string;
  accountNumber: string;
  ifsc: string;
}

export interface RiderProfile {
  name: string;
  email: string;
  address: string;
  city: string;
  vehicle: VehicleDetails;
  bank: BankDetails;
  documents: DocumentsState;
  drivingLicenseNumber: string;
  photoPath: string;
}

export interface RiderSession {
  isLoggedIn: boolean;
  phone: string;
  username?: string;
  name?: string;
  riderId?: string;
  token?: string;
}

export interface RiderMetrics {
  rating: number;
  acceptanceRate: number;
  completionRate: number;
  completedTrips: number;
}

export interface SettingsState {
  orderAlertsEnabled: boolean;
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  shareLiveLocationEnabled: boolean;
  weatherAlertsEnabled: boolean;
  language: 'English' | 'Hindi';
}
