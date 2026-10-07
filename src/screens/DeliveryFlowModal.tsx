import React, { useState, useEffect } from 'react';
import {
  ArrowLeft,
  Navigation,
  Phone,
  MessageSquare,
  AlertTriangle,
  CheckCircle2,
  Clock,
  ShieldAlert,
  X,
  MapPin,
  Send,
  Check,
  ChevronRight,
  Bike,
  Sparkles,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ActiveOrder, DeliveryProgress } from '../types';
import { useToast } from '../components/Toast';

export const DeliveryFlowModal: React.FC = () => {
  const {
    activeDeliveryOrder,
    setActiveDeliveryOrder,
    markReachedRestaurant,
    confirmPickupOtp,
    markArrivedCustomer,
    confirmDeliveryOtp,
  } = useApp();

  const { showToast } = useToast();

  const [pickupOtp, setPickupOtp] = useState('');
  const [deliveryOtp, setDeliveryOtp] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [loading, setLoading] = useState(false);
  const [showIssueSheet, setShowIssueSheet] = useState(false);
  const [showChatModal, setShowChatModal] = useState(false);
  const [chatMessages, setChatMessages] = useState<Array<{ sender: 'rider' | 'customer' | 'system'; text: string; time: string }>>([
    { sender: 'system', text: 'Live communication channel opened for Order', time: 'Now' },
    { sender: 'customer', text: 'Please ring the doorbell when you arrive at Flat 402.', time: 'Just now' },
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [orderCompletedSuccess, setOrderCompletedSuccess] = useState(false);

  if (!activeDeliveryOrder) return null;

  const order = activeDeliveryOrder;

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputMessage.trim()) return;
    setChatMessages((prev) => [
      ...prev,
      { sender: 'rider', text: inputMessage.trim(), time: 'Just now' },
    ]);
    setInputMessage('');
    showToast('Message sent to customer', 'info');
  };

  const handleSimulateNavigation = () => {
    showToast(`Navigating to ${order.progress === 'navigateRestaurant' || order.progress === 'reachedRestaurant' ? order.request.restaurantName : order.request.dropArea} via turn-by-turn route`, 'info');
  };

  const handleReachedRestaurant = async () => {
    setLoading(true);
    await markReachedRestaurant(order.id);
    setLoading(false);
    showToast('Marked arrived at restaurant. Enter pickup OTP.', 'success');
  };

  const handleConfirmPickup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pickupOtp.trim()) return;
    setLoading(true);
    setErrorMsg('');
    const ok = await confirmPickupOtp(order.id, pickupOtp);
    setLoading(false);
    if (!ok) {
      setErrorMsg(`Invalid Pickup OTP. (Hint: ${order.pickupOtp || '1234'})`);
      showToast('Invalid Pickup OTP! Check with merchant.', 'error');
    } else {
      setPickupOtp('');
      showToast('Order Picked Up! Head to customer delivery location.', 'success');
    }
  };

  const handleArrivedCustomer = async () => {
    setLoading(true);
    await markArrivedCustomer(order.id);
    setLoading(false);
    showToast('Arrived at customer doorstep. Ask for delivery OTP.', 'success');
  };

  const handleConfirmDelivery = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!deliveryOtp.trim()) return;
    setLoading(true);
    setErrorMsg('');
    const ok = await confirmDeliveryOtp(order.id, deliveryOtp);
    setLoading(false);
    if (!ok) {
      setErrorMsg(`Invalid Delivery OTP. (Hint: ${order.deliveryOtp || '5678'})`);
      showToast('Invalid Delivery OTP! Ask customer for 4-digit code.', 'error');
    } else {
      setDeliveryOtp('');
      setOrderCompletedSuccess(true);
      showToast(`Order delivered! Earning +₹${order.fareBreakdown.total} added.`, 'success');
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900 flex flex-col justify-between max-w-md mx-auto shadow-2xl overflow-hidden">
      {/* Top Map & Simulated Navigation View */}
      <div className="relative h-[42%] bg-slate-800 flex items-center justify-center overflow-hidden">
        {/* Animated Map Grid Background */}
        <div className="absolute inset-0 bg-slate-950 opacity-95" />
        <div className="absolute inset-0 bg-[radial-gradient(#00E676_1px,transparent_1px)] [background-size:20px_20px] opacity-25" />

        {/* Route visualization line */}
        <div className="absolute inset-x-8 top-1/2 -translate-y-1/2 h-0.5 bg-gradient-to-r from-emerald-500 via-emerald-400 to-rose-500 opacity-60" />

        <div className="relative z-10 text-center p-4">
          <div className="w-16 h-16 rounded-full bg-[#00E676]/20 border-2 border-[#00E676] flex items-center justify-center text-[#00E676] mx-auto mb-2 shadow-lg shadow-emerald-500/20 animate-pulse">
            <Bike className="w-8 h-8" />
          </div>
          <span className="text-white font-black text-sm block">
            {order.progress === 'navigateRestaurant' || order.progress === 'reachedRestaurant'
              ? `Route to: ${order.request.restaurantName}`
              : `Route to: ${order.request.dropArea}`}
          </span>
          <span className="text-xs text-slate-400 font-bold block mt-0.5">
            {order.request.totalDistanceKm} km total • Est. ~{order.request.etaMin} mins
          </span>
        </div>

        {/* Top Floating Controls */}
        <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between">
          <button
            onClick={() => setActiveDeliveryOrder(null)}
            className="w-11 h-11 rounded-full bg-slate-900/90 text-white border border-slate-700 shadow-lg flex items-center justify-center active:scale-95 transition"
            title="Minimize"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>

          <button
            onClick={handleSimulateNavigation}
            className="px-4 py-2.5 rounded-full bg-[#00E676] text-slate-950 font-black text-xs shadow-lg shadow-emerald-500/20 hover:bg-[#00c864] transition active:scale-95 flex items-center gap-1.5"
          >
            <Navigation className="w-4 h-4 fill-current" />
            <span>Turn-by-Turn GPS</span>
          </button>
        </div>
      </div>

      {/* Bottom Action Sheet */}
      <div className="h-[60%] bg-[#111827] text-white rounded-t-3xl p-6 flex flex-col justify-between overflow-y-auto border-t border-slate-700/80 shadow-2xl">
        <div className="space-y-4">
          <div className="w-10 h-1 bg-white/20 rounded-full mx-auto" />

          {/* Restaurant & Order Info */}
          <div className="flex items-start justify-between gap-3 pt-1">
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-black text-white text-xl line-clamp-1">
                  {order.request.restaurantName}
                </h3>
                <span className="w-5 h-5 rounded-full bg-[#00E676]/20 text-[#00E676] flex items-center justify-center text-xs font-black">
                  ✓
                </span>
              </div>
              <p className="text-xs text-slate-400 font-semibold mt-0.5">
                Order #{order.id} • Payout: <strong className="text-[#00E676]">₹{order.fareBreakdown.total}</strong>
              </p>
            </div>

            <div className="flex items-center gap-2">
              <a
                href="tel:9876543210"
                className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition"
                title="Call Customer"
              >
                <Phone className="w-4 h-4" />
              </a>
              <button
                onClick={() => setShowChatModal(true)}
                className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition"
                title="Chat Customer"
              >
                <MessageSquare className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Step Progress Tracker */}
          <div className="bg-slate-800/80 p-3.5 rounded-2xl border border-slate-700/60">
            <span className="text-[10px] font-black uppercase text-slate-400 tracking-wider block mb-2">
              DELIVERY WORKFLOW
            </span>
            <div className="grid grid-cols-4 gap-1 text-center text-[10px] font-black">
              <div className={`p-1.5 rounded-xl ${order.progress === 'navigateRestaurant' ? 'bg-[#00E676] text-slate-950' : 'bg-slate-700 text-slate-300'}`}>
                1. To Store
              </div>
              <div className={`p-1.5 rounded-xl ${order.progress === 'reachedRestaurant' ? 'bg-[#00E676] text-slate-950' : 'bg-slate-700 text-slate-300'}`}>
                2. Pickup OTP
              </div>
              <div className={`p-1.5 rounded-xl ${order.progress === 'pickedUp' ? 'bg-[#00E676] text-slate-950' : 'bg-slate-700 text-slate-300'}`}>
                3. To Door
              </div>
              <div className={`p-1.5 rounded-xl ${order.progress === 'arrivedCustomer' ? 'bg-[#00E676] text-slate-950' : 'bg-slate-700 text-slate-300'}`}>
                4. Drop OTP
              </div>
            </div>
          </div>

          {/* Step 1: Heading to Restaurant */}
          {order.progress === 'navigateRestaurant' && (
            <div className="space-y-3 pt-2">
              <div className="bg-slate-800/60 p-4 rounded-2xl border border-slate-700 text-xs text-slate-300 space-y-1">
                <span className="font-bold text-white block">Pickup Directions:</span>
                <p>Reach {order.request.restaurantName} at {order.request.restaurantArea || 'City Center'}.</p>
                <p className="text-slate-400">Items: {order.request.items.map((i) => `${i.quantity}x ${i.name}`).join(', ') || 'Food items'}</p>
              </div>

              <button
                onClick={handleReachedRestaurant}
                disabled={loading}
                className="w-full py-4 rounded-2xl bg-[#EF4444] hover:bg-red-600 text-white font-black text-base shadow-lg shadow-red-500/20 active:scale-95 transition"
              >
                {loading ? 'Updating...' : 'I Have Reached Restaurant'}
              </button>
            </div>
          )}

          {/* Step 2: Reached Restaurant -> Enter Pickup OTP */}
          {order.progress === 'reachedRestaurant' && (
            <form onSubmit={handleConfirmPickup} className="space-y-3 pt-2">
              <div className="bg-slate-800/80 p-4 rounded-2xl border border-slate-700">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-bold text-xs text-slate-300">Enter Pickup OTP from Merchant</span>
                  <span className="text-[11px] font-bold text-emerald-400 bg-emerald-950/60 px-2 py-0.5 rounded-full border border-emerald-500/30">
                    Hint: {order.pickupOtp || '1234'}
                  </span>
                </div>
                <input
                  type="text"
                  maxLength={4}
                  value={pickupOtp}
                  onChange={(e) => setPickupOtp(e.target.value)}
                  placeholder="4-digit OTP"
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl p-3 text-center text-white font-mono font-black text-xl tracking-[0.4em] outline-none focus:border-[#00E676]"
                  autoFocus
                />
              </div>

              {errorMsg && (
                <div className="p-2.5 rounded-xl bg-red-950/60 text-red-300 text-xs text-center border border-red-500/30 font-semibold">
                  {errorMsg}
                </div>
              )}

              <button
                type="submit"
                disabled={loading || pickupOtp.length < 4}
                className="w-full py-4 rounded-2xl bg-[#00E676] hover:bg-[#00c864] text-slate-950 font-black text-base shadow-lg shadow-emerald-500/20 active:scale-95 transition disabled:opacity-50"
              >
                {loading ? 'Verifying...' : 'Verify & Confirm Pickup'}
              </button>
            </form>
          )}

          {/* Step 3: Picked Up -> Heading to Customer */}
          {order.progress === 'pickedUp' && (
            <div className="space-y-3 pt-2">
              <div className="bg-slate-800/60 p-4 rounded-2xl border border-slate-700 text-xs text-slate-300 space-y-1.5">
                <span className="font-bold text-white block">Drop Location:</span>
                <p className="text-white font-semibold flex items-center gap-1.5">
                  <MapPin className="w-4 h-4 text-[#00E676]" />
                  <span>{order.request.dropArea}</span>
                </p>
                {order.cashToCollect > 0 ? (
                  <div className="p-2.5 rounded-xl bg-amber-950/50 border border-amber-500/40 text-amber-300 font-bold text-xs mt-2">
                    💵 Collect Cash on Delivery: ₹{order.cashToCollect}
                  </div>
                ) : (
                  <div className="p-2.5 rounded-xl bg-emerald-950/50 border border-emerald-500/40 text-emerald-300 font-bold text-xs mt-2">
                    ✓ Prepaid Order (Do not collect cash)
                  </div>
                )}
              </div>

              <button
                onClick={handleArrivedCustomer}
                disabled={loading}
                className="w-full py-4 rounded-2xl bg-[#EF4444] hover:bg-red-600 text-white font-black text-base shadow-lg shadow-red-500/20 active:scale-95 transition"
              >
                {loading ? 'Updating...' : 'I Have Arrived at Customer Door'}
              </button>
            </div>
          )}

          {/* Step 4: Arrived Customer -> Enter Delivery OTP */}
          {order.progress === 'arrivedCustomer' && (
            <form onSubmit={handleConfirmDelivery} className="space-y-3 pt-2">
              <div className="bg-slate-800/80 p-4 rounded-2xl border border-slate-700">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-bold text-xs text-slate-300">Customer Delivery OTP</span>
                  <span className="text-[11px] font-bold text-emerald-400 bg-emerald-950/60 px-2 py-0.5 rounded-full border border-emerald-500/30">
                    Hint: {order.deliveryOtp || '5678'}
                  </span>
                </div>
                <input
                  type="text"
                  maxLength={4}
                  value={deliveryOtp}
                  onChange={(e) => setDeliveryOtp(e.target.value)}
                  placeholder="4-digit OTP"
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl p-3 text-center text-white font-mono font-black text-xl tracking-[0.4em] outline-none focus:border-[#00E676]"
                  autoFocus
                />
              </div>

              {errorMsg && (
                <div className="p-2.5 rounded-xl bg-red-950/60 text-red-300 text-xs text-center border border-red-500/30 font-semibold">
                  {errorMsg}
                </div>
              )}

              <button
                type="submit"
                disabled={loading || deliveryOtp.length < 4}
                className="w-full py-4 rounded-2xl bg-gradient-to-r from-emerald-500 to-[#00E676] hover:from-emerald-400 hover:to-[#00c864] text-slate-950 font-black text-base shadow-lg shadow-emerald-500/20 active:scale-95 transition disabled:opacity-50"
              >
                {loading ? 'Completing...' : 'Confirm Delivery & Collect Earning'}
              </button>
            </form>
          )}

          {/* Report an Issue trigger */}
          <div className="pt-2 text-center">
            <button
              onClick={() => setShowIssueSheet(true)}
              className="text-xs text-slate-400 hover:text-white font-semibold flex items-center justify-center gap-1 mx-auto"
            >
              <AlertTriangle className="w-3.5 h-3.5 text-amber-400" />
              <span>Report an Issue (Delay, Address, Emergency)</span>
            </button>
          </div>
        </div>
      </div>

      {/* Customer Chat Sheet */}
      {showChatModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 text-white rounded-3xl p-5 max-w-sm w-full h-[500px] shadow-2xl border border-slate-800 flex flex-col justify-between">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div>
                <h4 className="font-black text-sm text-white">Live Customer Chat</h4>
                <span className="text-[10px] text-slate-400 font-semibold">Order #{order.id}</span>
              </div>
              <button
                onClick={() => setShowChatModal(false)}
                className="p-1 rounded-full text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Chat Body */}
            <div className="flex-1 overflow-y-auto py-3 space-y-2.5 text-xs">
              {chatMessages.map((msg, i) => (
                <div
                  key={i}
                  className={`flex flex-col ${
                    msg.sender === 'rider'
                      ? 'items-end'
                      : msg.sender === 'customer'
                      ? 'items-start'
                      : 'items-center'
                  }`}
                >
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl ${
                      msg.sender === 'rider'
                        ? 'bg-[#00E676] text-slate-950 font-semibold'
                        : msg.sender === 'customer'
                        ? 'bg-slate-800 text-white'
                        : 'bg-slate-800/40 text-slate-400 text-[11px] text-center'
                    }`}
                  >
                    {msg.text}
                  </div>
                  <span className="text-[9px] text-slate-500 mt-0.5 px-1">{msg.time}</span>
                </div>
              ))}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendMessage} className="pt-2 border-t border-slate-800 flex items-center gap-2">
              <input
                type="text"
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                placeholder="Type a message to customer..."
                className="flex-1 bg-slate-800 text-white placeholder:text-slate-500 text-xs rounded-xl px-3.5 py-2.5 outline-none border border-slate-700 focus:border-[#00E676]"
              />
              <button
                type="submit"
                className="w-9 h-9 rounded-xl bg-[#00E676] text-slate-950 flex items-center justify-center shrink-0"
              >
                <Send className="w-4 h-4" />
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Report Issue Sheet */}
      {showIssueSheet && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-end sm:items-center justify-center p-4">
          <div className="bg-slate-900 text-white rounded-3xl p-6 max-w-sm w-full shadow-2xl border border-slate-800">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <h4 className="font-black text-sm text-white flex items-center gap-1.5">
                <AlertTriangle className="w-4 h-4 text-amber-400" />
                <span>Report Delivery Issue</span>
              </h4>
              <button
                onClick={() => setShowIssueSheet(false)}
                className="p-1 rounded-full text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="py-4 space-y-2">
              {[
                'Restaurant is taking too long to prepare food',
                'Customer delivery address unreachable / no answer',
                'Customer requested order cancellation',
                'Damaged or missing packaging',
                'Bike breakdown / puncture',
              ].map((issue, idx) => (
                <button
                  key={idx}
                  onClick={() => {
                    showToast(`Issue logged: "${issue}". Dispatch helpline notified.`, 'info');
                    setShowIssueSheet(false);
                  }}
                  className="w-full p-3 rounded-2xl bg-slate-800 hover:bg-slate-750 text-left text-xs font-semibold text-slate-200 transition"
                >
                  {issue}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Delivery Success Modal */}
      {orderCompletedSuccess && (
        <div className="fixed inset-0 z-[60] bg-black/90 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-slate-900 text-white rounded-3xl p-6 max-w-sm w-full text-center border border-emerald-500/40 shadow-2xl space-y-4">
            <div className="w-16 h-16 rounded-full bg-emerald-500/20 text-[#00E676] flex items-center justify-center mx-auto animate-bounce">
              <CheckCircle2 className="w-9 h-9" />
            </div>

            <div>
              <h3 className="text-2xl font-black text-white">Delivery Completed!</h3>
              <p className="text-xs text-slate-400 mt-1">
                Delivered safely to <strong>{order.request.dropArea}</strong>
              </p>
            </div>

            <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 space-y-2 text-xs">
              <div className="flex justify-between text-slate-400">
                <span>Trip Earning</span>
                <strong className="text-[#00E676] text-base">+₹{order.fareBreakdown.total}</strong>
              </div>
              <div className="flex justify-between text-slate-400">
                <span>Distance Covered</span>
                <strong className="text-white">{order.request.totalDistanceKm} km</strong>
              </div>
              {order.cashToCollect > 0 && (
                <div className="flex justify-between text-amber-400 font-bold pt-1 border-t border-slate-800">
                  <span>COD Cash Collected</span>
                  <span>₹{order.cashToCollect}</span>
                </div>
              )}
            </div>

            <button
              onClick={() => {
                setOrderCompletedSuccess(false);
                setActiveDeliveryOrder(null);
              }}
              className="w-full py-3.5 bg-[#00E676] hover:bg-[#00c864] text-slate-950 font-black rounded-2xl text-sm transition shadow-lg shadow-emerald-500/20"
            >
              Back to Home Screen
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
