import React, { useState, useEffect } from 'react';
import {
  Bike,
  Wallet,
  Package,
  Navigation,
  Flame,
  AlertTriangle,
  Clock,
  MapPin,
  Star,
  ArrowRight,
  ShieldAlert,
  ChevronRight,
  Compass,
  X,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { OrderRequest } from '../types';
import { useToast } from '../components/Toast';

export const HomeTab: React.FC = () => {
  const {
    session,
    isOnline,
    setOnline,
    todayTotal,
    activeOrders,
    trips,
    requests,
    acceptOrder,
    rejectOrder,
    profile,
    setActiveDeliveryOrder,
  } = useApp();

  const { showToast } = useToast();
  const [showSosDialog, setShowSosDialog] = useState(false);
  const [showRadarModal, setShowRadarModal] = useState(false);

  const handleToggleOnline = async () => {
    const next = !isOnline;
    await setOnline(next);
    showToast(next ? 'Shift Online • Receiving nearby delivery requests.' : 'Shift Paused • You are offline.', next ? 'success' : 'info');
  };

  const weekTripCount = trips.length;
  const incentiveTarget = 12;
  const incentiveProgress = Math.min(100, Math.round((weekTripCount / incentiveTarget) * 100));

  const activeInFlight = activeOrders[0];
  const displayName = profile.name || session.name || session.username || 'Partner';

  return (
    <div className="pb-24 bg-slate-50 min-h-screen">
      {/* Sleek Compact Header (No refresh button, no API Connected banner) */}
      <header className="sticky top-0 z-30 bg-slate-900 text-white px-4 py-2.5 flex items-center justify-between shadow-md border-b border-slate-800">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-emerald-400 to-[#00E676] text-slate-950 font-black text-xs flex items-center justify-center shadow-sm">
            {displayName.charAt(0).toUpperCase()}
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold text-white text-xs tracking-tight truncate max-w-[150px]">
                {displayName}
              </span>
              <span className="px-1 py-0.2 rounded text-[9px] font-black bg-emerald-500/20 text-[#00E676] border border-emerald-500/30">
                PRO
              </span>
            </div>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span
                className={`w-1.5 h-1.5 rounded-full ${
                  isOnline ? 'bg-[#00E676] animate-pulse ring-2 ring-emerald-500/30' : 'bg-slate-500'
                }`}
              />
              <span className="font-semibold text-[10px] text-slate-300">
                {isOnline ? 'Online • Ready for dispatch' : 'Offline • Shift paused'}
              </span>
            </div>
          </div>
        </div>

        {/* Compact Online Toggle Switch */}
        <button
          onClick={handleToggleOnline}
          className={`w-11 h-6 rounded-full p-0.5 transition-colors duration-300 flex items-center cursor-pointer ${
            isOnline ? 'bg-[#00E676]' : 'bg-slate-700'
          }`}
          title={isOnline ? 'Click to go offline' : 'Click to go online'}
        >
          <div
            className={`w-5 h-5 rounded-full bg-slate-950 shadow transform transition-transform duration-300 flex items-center justify-center ${
              isOnline ? 'translate-x-5' : 'translate-x-0'
            }`}
          >
            <div className={`w-1.5 h-1.5 rounded-full ${isOnline ? 'bg-[#00E676]' : 'bg-slate-500'}`} />
          </div>
        </button>
      </header>

      {/* Main Content Area: Compact & High Viewing Space */}
      <div className="p-3 space-y-3 max-w-md mx-auto">
        {/* IN-FLIGHT ORDER BANNER (If Active) */}
        {activeInFlight && (
          <div
            onClick={() => setActiveDeliveryOrder(activeInFlight)}
            className="rounded-2xl p-3 bg-gradient-to-r from-emerald-950 via-slate-900 to-slate-950 text-white border border-[#00E676] shadow-lg cursor-pointer active:scale-[0.99] transition animate-pulse"
          >
            <div className="flex items-center justify-between">
              <span className="px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider bg-[#00E676] text-slate-950">
                ACTIVE DELIVERY RUNNING
              </span>
              <span className="text-[11px] font-extrabold text-[#00E676]">Order #{activeInFlight.id}</span>
            </div>
            <div className="flex items-center justify-between mt-2">
              <div>
                <h4 className="font-bold text-white text-xs truncate max-w-[200px]">
                  {activeInFlight.request.restaurantName}
                </h4>
                <p className="text-[11px] text-slate-300 font-medium mt-0.5 flex items-center gap-1">
                  <MapPin className="w-3 h-3 text-[#00E676] shrink-0" />
                  <span className="truncate max-w-[200px]">Drop: {activeInFlight.request.dropArea}</span>
                </p>
              </div>
              <button className="px-2.5 py-1.5 rounded-xl bg-[#00E676] text-slate-950 font-black text-xs flex items-center gap-1 shadow-sm">
                <span>Resume</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        )}

        {/* Quick Stats Grid: Minimal & Crisp */}
        <div className="grid grid-cols-2 gap-2.5">
          <div className="bg-white rounded-2xl p-3 border border-slate-200/90 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <div className="w-7 h-7 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <Wallet className="w-4 h-4 text-[#00E676]" />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wide">TODAY</span>
            </div>
            <div className="mt-2">
              <span className="text-xl font-extrabold text-slate-900 tracking-tight">
                ₹ {todayTotal.toFixed(0)}
              </span>
              <span className="text-[11px] text-slate-500 font-semibold block mt-0.5">Shift Earnings</span>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-3 border border-slate-200/90 shadow-sm flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <div className="w-7 h-7 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                <Package className="w-4 h-4 text-blue-600" />
              </div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wide">ACTIVE</span>
            </div>
            <div className="mt-2">
              <span className="text-xl font-extrabold text-slate-900 tracking-tight">
                {activeOrders.length}
              </span>
              <span className="text-[11px] text-slate-500 font-semibold block mt-0.5">Orders in-flight</span>
            </div>
          </div>
        </div>

        {/* Live Delivery Zone Widget (Compact) */}
        <div className="rounded-2xl overflow-hidden bg-slate-900 text-white border border-slate-800 p-3.5 shadow-md relative">
          <div className="relative z-10 flex items-center justify-between">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-slate-800/90 border border-slate-700 text-[10px] font-bold text-slate-200">
              <span className={`w-1.5 h-1.5 rounded-full ${isOnline ? 'bg-[#00E676] animate-pulse' : 'bg-slate-500'}`} />
              {isOnline ? 'Live Dispatch Radar' : 'Radar Standby'}
            </span>

            <button
              onClick={() => setShowRadarModal(true)}
              className="text-[11px] font-bold text-[#00E676] hover:underline flex items-center gap-1"
            >
              <span>GPS Info</span>
              <Compass className="w-3 h-3" />
            </button>
          </div>

          <div className="relative z-10 mt-2.5">
            <h3 className="text-sm font-extrabold text-white tracking-tight">
              {profile.city || 'Bhopal'} Dispatch Zone
            </h3>
            <p className="text-[11px] text-slate-400 mt-0.5 font-medium leading-tight">
              Auto-routing tuned for short pickup ETA across City Center & Sharda Nagar.
            </p>
          </div>

          <div className="relative z-10 mt-3 pt-2.5 border-t border-slate-800/80 flex items-center justify-between text-[11px] text-slate-300">
            <span className="flex items-center gap-1">
              <Flame className="w-3 h-3 text-amber-400" />
              <span>Surge active: <strong>+₹15/trip</strong></span>
            </span>
            <button
              onClick={() => setShowSosDialog(true)}
              className="px-2 py-0.5 rounded-full bg-rose-500/20 text-rose-300 border border-rose-500/30 font-bold text-[10px] flex items-center gap-1 active:scale-95 transition"
            >
              <ShieldAlert className="w-3 h-3" />
              <span>SOS</span>
            </button>
          </div>
        </div>

        {/* Weekly Incentives Card: Compact */}
        <div className="bg-white rounded-2xl p-3 border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <h4 className="font-bold text-slate-900 text-xs">Weekly Shift Target</h4>
              <p className="text-[10px] text-slate-400 font-medium">Earn ₹400 bonus payout</p>
            </div>
            <span className="text-[11px] font-bold text-[#00E676] bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200/60">
              {weekTripCount} / {incentiveTarget} trips
            </span>
          </div>

          <div className="w-full bg-slate-100 rounded-full h-2 mt-2 overflow-hidden">
            <div
              className="bg-gradient-to-r from-emerald-500 to-[#00E676] h-full rounded-full transition-all duration-700"
              style={{ width: `${incentiveProgress}%` }}
            />
          </div>

          <p className="text-[10px] text-slate-500 mt-1.5 font-medium">
            {weekTripCount >= incentiveTarget
              ? '🎉 Target unlocked! ₹400 bonus added to your payouts.'
              : `Complete ${incentiveTarget - weekTripCount} more deliveries this week to unlock incentive.`}
          </p>
        </div>

        {/* Order Requests Section */}
        <div className="pt-1">
          <div className="flex items-center justify-between mb-2 px-1">
            <div className="flex items-center gap-1.5">
              <h3 className="text-xs font-bold text-slate-900">New Delivery Requests</h3>
              {requests.length > 0 && (
                <span className="px-2 py-0.2 rounded-full text-[10px] font-black bg-emerald-50 text-emerald-800 border border-emerald-200">
                  {requests.length} Available
                </span>
              )}
            </div>
          </div>

          {!isOnline ? (
            <div className="bg-white rounded-2xl p-5 border border-slate-200 text-center shadow-sm">
              <div className="w-10 h-10 bg-slate-100 text-slate-400 rounded-full flex items-center justify-center mx-auto mb-2">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <h4 className="font-bold text-slate-800 text-xs">You are currently offline</h4>
              <p className="text-[11px] text-slate-400 mt-1 max-w-xs mx-auto">
                Turn on the Online switch at top right to start receiving live delivery dispatch calls.
              </p>
              <button
                onClick={handleToggleOnline}
                className="mt-3 px-4 py-1.5 rounded-xl bg-[#00E676] text-slate-950 font-bold text-xs shadow-sm active:scale-95 transition"
              >
                Go Online
              </button>
            </div>
          ) : requests.length === 0 ? (
            <div className="bg-white rounded-2xl p-5 border border-slate-200 text-center shadow-sm">
              <div className="w-10 h-10 rounded-full bg-emerald-50 text-[#00E676] flex items-center justify-center mx-auto mb-2 animate-pulse">
                <Bike className="w-5 h-5" />
              </div>
              <h4 className="font-bold text-slate-800 text-xs">Scanning for nearby orders...</h4>
              <p className="text-[11px] text-slate-400 mt-0.5 max-w-xs mx-auto">
                Orders dispatched by Maa Sharda partner stores will appear here.
              </p>
            </div>
          ) : (
            <div className="space-y-2.5">
              {requests.map((order) => (
                <OrderCard
                  key={order.id}
                  order={order}
                  onAccept={() => acceptOrder(order.id)}
                  onReject={(reason) => rejectOrder(order.id, reason)}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Radar Inspection Modal */}
      {showRadarModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 text-white rounded-2xl p-4 max-w-sm w-full shadow-2xl border border-slate-800">
            <div className="flex items-center justify-between pb-2 border-b border-slate-800">
              <div className="flex items-center gap-1.5">
                <Compass className="w-4 h-4 text-[#00E676]" />
                <h3 className="text-sm font-bold text-white">Live GPS Dispatch Radar</h3>
              </div>
              <button
                onClick={() => setShowRadarModal(false)}
                className="p-1 rounded-full text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="py-3 space-y-2 text-xs">
              <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/80 flex items-center justify-between">
                <span className="text-slate-400 text-[11px]">GPS Coordinates</span>
                <span className="text-white font-mono font-bold text-[11px]">23.2599° N, 77.4126° E</span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/80 flex items-center justify-between">
                <span className="text-slate-400 text-[11px]">Zone</span>
                <span className="text-white font-bold text-[11px]">{profile.city || 'Bhopal'} (Sector 2)</span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/80 flex items-center justify-between">
                <span className="text-slate-400 text-[11px]">GPS Accuracy</span>
                <span className="text-[#00E676] font-bold text-[11px]">± 4 meters (High)</span>
              </div>
            </div>

            <button
              onClick={() => {
                showToast('GPS recalibrated successfully', 'success');
                setShowRadarModal(false);
              }}
              className="w-full py-2 rounded-xl bg-[#00E676] hover:bg-[#00c864] text-slate-950 font-bold text-xs transition"
            >
              Recalibrate Location
            </button>
          </div>
        </div>
      )}

      {/* SOS Dialog */}
      {showSosDialog && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-5 max-w-sm w-full shadow-2xl text-center">
            <div className="w-12 h-12 bg-red-100 text-red-600 rounded-full flex items-center justify-center mx-auto mb-3 animate-pulse">
              <ShieldAlert className="w-6 h-6" />
            </div>
            <h3 className="text-base font-bold text-slate-900">Emergency SOS</h3>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              Assistance will dispatch to your live GPS coordinates in {profile.city || 'Bhopal'}.
            </p>
            <div className="mt-4 space-y-2">
              <a
                href="tel:112"
                className="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white rounded-xl font-bold text-xs block transition shadow-sm text-center"
              >
                Call Emergency Police (112)
              </a>
              <a
                href="tel:108"
                className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl font-bold text-xs block transition text-center"
              >
                Medical Ambulance (108)
              </a>
              <button
                onClick={() => setShowSosDialog(false)}
                className="w-full py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl font-bold text-xs transition"
              >
                Dismiss
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

interface OrderCardProps {
  order: OrderRequest;
  onAccept: () => void;
  onReject: (reason?: string) => void;
}

const OrderCard: React.FC<OrderCardProps> = ({ order, onAccept, onReject }) => {
  const [secondsLeft, setSecondsLeft] = useState<number>(() => {
    const diff = Math.floor((new Date(order.expiresAt).getTime() - Date.now()) / 1000);
    return Math.max(0, diff);
  });

  useEffect(() => {
    const interval = setInterval(() => {
      const diff = Math.floor((new Date(order.expiresAt).getTime() - Date.now()) / 1000);
      if (diff <= 0) {
        setSecondsLeft(0);
        clearInterval(interval);
        onReject('Expired');
      } else {
        setSecondsLeft(diff);
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [order.expiresAt, onReject]);

  const progressPercent = Math.max(0, Math.min(100, (secondsLeft / 45) * 100));

  return (
    <div className="bg-slate-900 text-white rounded-2xl p-3.5 border border-slate-800 shadow-md relative overflow-hidden transition-all">
      {/* Top countdown bar */}
      <div className="absolute top-0 left-0 right-0 h-1 bg-slate-800">
        <div
          className={`h-full transition-all duration-1000 ${
            secondsLeft < 15 ? 'bg-rose-500' : 'bg-[#00E676]'
          }`}
          style={{ width: `${progressPercent}%` }}
        />
      </div>

      {/* Header with Restaurant & Earning */}
      <div className="flex items-start justify-between gap-2 pt-1">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0 border border-amber-500/30 text-base">
            🍲
          </div>
          <div>
            <h4 className="font-bold text-white text-xs leading-snug line-clamp-1">
              {order.restaurantName}
            </h4>
            <div className="flex items-center gap-1.5 mt-0.5 text-[10px] text-slate-400 font-medium">
              <span className="flex items-center gap-0.5 text-amber-400 font-bold">
                <Star className="w-2.5 h-2.5 fill-current" />
                4.8
              </span>
              <span>•</span>
              <span>{order.items.length} items</span>
              <span>•</span>
              <span>~{order.etaMin} mins</span>
            </div>
          </div>
        </div>

        <div className="text-right">
          <span className="text-base font-extrabold text-[#00E676] tracking-tight block">
            ₹ {order.expectedEarning}
          </span>
          <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wider block">
            Rider Pay
          </span>
          {order.cashToCollect > 0 ? (
            <span className="text-[10px] font-bold text-amber-400 block">
              COD: ₹{order.cashToCollect}
            </span>
          ) : (
            <span className="text-[9px] font-bold text-emerald-400 block">
              Prepaid
            </span>
          )}
        </div>
      </div>

      {/* Route step line */}
      <div className="bg-slate-800/70 rounded-xl p-2.5 mt-2.5 space-y-1.5 border border-slate-700/60 text-[11px]">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-emerald-400 shrink-0" />
          <span className="text-slate-300 font-medium truncate">
            <strong>Pickup:</strong> {order.restaurantArea || 'City Center'} ({order.pickupDistanceKm} km)
          </span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-rose-400 shrink-0" />
          <span className="text-slate-300 font-medium truncate">
            <strong>Drop:</strong> {order.dropArea} ({order.deliveryDistanceKm} km)
          </span>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center gap-2 mt-3">
        <button
          onClick={() => onReject('Declined by rider')}
          className="flex-1 py-2 rounded-xl border border-slate-700 hover:bg-slate-800 text-slate-300 font-bold text-xs transition active:scale-95"
        >
          Decline ({secondsLeft}s)
        </button>

        <button
          onClick={onAccept}
          className="flex-2 py-2 rounded-xl bg-gradient-to-r from-emerald-500 to-[#00E676] hover:from-emerald-400 hover:to-[#00c864] text-slate-950 font-black text-xs flex items-center justify-center gap-1.5 shadow-md shadow-emerald-500/20 transition active:scale-95"
        >
          <span>Accept Delivery</span>
          <ArrowRight className="w-3.5 h-3.5 text-slate-950" />
        </button>
      </div>
    </div>
  );
};
