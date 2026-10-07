import React, { useState } from 'react';
import {
  Bike,
  CheckCircle2,
  XCircle,
  ChevronRight,
  Clock,
  MapPin,
  X,
  FileText,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { OrderHistoryItem, DeliveryProgress } from '../types';

export const OrdersTab: React.FC = () => {
  const {
    activeOrders,
    orderHistory,
    setActiveDeliveryOrder,
  } = useApp();

  const [selectedHistory, setSelectedHistory] = useState<OrderHistoryItem | null>(null);
  const [activeFilter, setActiveFilter] = useState<'all' | 'delivered' | 'rejected'>('all');

  const getProgressLabel = (p: DeliveryProgress): string => {
    switch (p) {
      case 'navigateRestaurant':
        return 'Heading to Store';
      case 'reachedRestaurant':
        return 'At Store (Pickup OTP)';
      case 'pickedUp':
        return 'Heading to Customer';
      case 'arrivedCustomer':
        return 'At Customer Door';
      case 'delivered':
        return 'Delivered';
      default:
        return 'In progress';
    }
  };

  const formatTime = (isoString: string): string => {
    try {
      const dt = new Date(isoString);
      return dt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
    } catch (_) {
      return '';
    }
  };

  const filteredHistory = orderHistory.filter((item) => {
    if (activeFilter === 'delivered') return item.status === 'delivered';
    if (activeFilter === 'rejected') return item.status === 'rejected';
    return true;
  });

  return (
    <div className="pb-24 bg-slate-50 min-h-screen">
      {/* Sleek Compact Header (No refresh button) */}
      <header className="sticky top-0 z-30 bg-slate-900 text-white px-4 py-2.5 flex items-center justify-between shadow-md border-b border-slate-800">
        <div>
          <h2 className="text-sm font-extrabold text-white tracking-tight">Orders Hub</h2>
          <span className="text-[10px] text-slate-400 font-semibold">Active & past deliveries</span>
        </div>
      </header>

      <div className="p-3 space-y-4 max-w-md mx-auto">
        {/* Active In-Flight Orders */}
        <div>
          <div className="flex items-center justify-between mb-2 px-1">
            <h3 className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
              Active Deliveries ({activeOrders.length})
            </h3>
          </div>

          {activeOrders.length === 0 ? (
            <div className="bg-white rounded-2xl p-4 border border-slate-200/90 text-center shadow-sm">
              <div className="w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 mx-auto mb-1.5">
                <Bike className="w-4 h-4" />
              </div>
              <h4 className="font-bold text-slate-800 text-xs">No active delivery in progress</h4>
              <p className="text-[11px] text-slate-400 mt-0.5">
                Go to the Home tab and accept an incoming order request.
              </p>
            </div>
          ) : (
            <div className="space-y-2.5">
              {activeOrders.map((order) => (
                <div
                  key={order.id}
                  onClick={() => setActiveDeliveryOrder(order)}
                  className="bg-white rounded-2xl p-3 border border-[#00E676] shadow-sm hover:shadow-md cursor-pointer transition flex items-center justify-between gap-2.5 active:scale-[0.99]"
                >
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-xl bg-emerald-50 text-[#00E676] flex items-center justify-center shrink-0 border border-emerald-100">
                      <Bike className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-900 text-xs line-clamp-1">
                        {order.request.restaurantName}
                      </h4>
                      <p className="text-[10px] text-slate-500 flex items-center gap-1 mt-0.5">
                        <MapPin className="w-2.5 h-2.5 text-slate-400 shrink-0" />
                        <span className="truncate max-w-[150px]">{order.request.dropArea}</span>
                      </p>
                      <span className="inline-block mt-1 px-2 py-0.2 rounded-full text-[9px] font-bold bg-emerald-50 text-[#00E676] border border-emerald-200/60">
                        {getProgressLabel(order.progress)}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5 text-right">
                    <div>
                      <span className="text-xs font-extrabold text-slate-900 block">
                        ₹ {order.fareBreakdown.total}
                      </span>
                      <span className="text-[10px] font-bold text-emerald-600">Resume</span>
                    </div>
                    <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* History Section with Filter Tabs */}
        <div>
          <div className="flex items-center justify-between mb-2 px-1">
            <h3 className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
              Trip History
            </h3>
            {/* Filter pills */}
            <div className="flex items-center gap-1 bg-slate-200/70 p-0.5 rounded-lg text-[10px] font-bold">
              <button
                onClick={() => setActiveFilter('all')}
                className={`px-2 py-0.5 rounded transition ${
                  activeFilter === 'all' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600'
                }`}
              >
                All
              </button>
              <button
                onClick={() => setActiveFilter('delivered')}
                className={`px-2 py-0.5 rounded transition ${
                  activeFilter === 'delivered' ? 'bg-white text-emerald-700 shadow-xs' : 'text-slate-600'
                }`}
              >
                Delivered
              </button>
              <button
                onClick={() => setActiveFilter('rejected')}
                className={`px-2 py-0.5 rounded transition ${
                  activeFilter === 'rejected' ? 'bg-white text-rose-700 shadow-xs' : 'text-slate-600'
                }`}
              >
                Declined
              </button>
            </div>
          </div>

          {filteredHistory.length === 0 ? (
            <div className="bg-white rounded-2xl p-5 border border-slate-200/90 text-center shadow-sm">
              <Clock className="w-8 h-8 text-slate-300 mx-auto mb-1.5" />
              <h4 className="font-bold text-slate-800 text-xs">No records found</h4>
              <p className="text-[11px] text-slate-400 mt-0.5">
                Completed or declined orders will be archived here.
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredHistory.map((item, idx) => (
                <div
                  key={`${item.orderId}-${idx}`}
                  onClick={() => setSelectedHistory(item)}
                  className="bg-white rounded-xl p-3 border border-slate-200/90 shadow-xs hover:border-slate-300 cursor-pointer transition flex items-center justify-between gap-2.5 active:scale-[0.99]"
                >
                  <div className="flex items-center gap-2.5">
                    <div
                      className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 ${
                        item.status === 'delivered'
                          ? 'bg-emerald-50 text-emerald-600 border border-emerald-100'
                          : 'bg-red-50 text-red-500 border border-red-100'
                      }`}
                    >
                      {item.status === 'delivered' ? (
                        <CheckCircle2 className="w-4 h-4" />
                      ) : (
                        <XCircle className="w-4 h-4" />
                      )}
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-900 text-xs line-clamp-1">
                        {item.restaurantName || `Order #${item.orderId}`}
                      </h4>
                      <p className="text-[10px] text-slate-400">
                        {formatTime(item.completedAt)} • {item.dropArea || 'Drop location'}
                      </p>
                    </div>
                  </div>

                  <div className="text-right flex items-center gap-1.5">
                    <div>
                      {item.status === 'delivered' ? (
                        <span className="text-xs font-bold text-slate-900 block">
                          ₹ {item.earning}
                        </span>
                      ) : (
                        <span className="text-[11px] font-bold text-red-500 block">Declined</span>
                      )}
                      <span className="text-[9px] text-slate-400 font-semibold">#{item.orderId}</span>
                    </div>
                    <ChevronRight className="w-3.5 h-3.5 text-slate-300" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* History Detail Modal */}
      {selectedHistory && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-4 max-w-sm w-full shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-2 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <FileText className="w-4 h-4 text-emerald-600" />
                <h3 className="text-xs font-bold text-slate-900">
                  Order #{selectedHistory.orderId} Details
                </h3>
              </div>
              <button
                onClick={() => setSelectedHistory(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-800"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="py-3 space-y-2 text-xs">
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span className="text-slate-500 text-[11px]">Restaurant</span>
                <span className="text-slate-900 font-bold text-[11px]">{selectedHistory.restaurantName}</span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span className="text-slate-500 text-[11px]">Customer Drop Area</span>
                <span className="text-slate-900 font-bold text-[11px]">{selectedHistory.dropArea || 'N/A'}</span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span className="text-slate-500 text-[11px]">Status</span>
                <span className={`font-bold text-[11px] ${selectedHistory.status === 'delivered' ? 'text-[#00E676]' : 'text-rose-600'}`}>
                  {selectedHistory.status.toUpperCase()}
                </span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span className="text-slate-500 text-[11px]">Rider Earning</span>
                <span className="text-slate-900 font-bold text-xs">₹ {selectedHistory.earning}</span>
              </div>
              {selectedHistory.cashCollected > 0 && (
                <div className="p-2.5 rounded-xl bg-amber-50 border border-amber-200/60 flex items-center justify-between text-amber-900">
                  <span className="font-semibold text-[11px]">COD Cash Collected</span>
                  <span className="font-bold text-xs">₹ {selectedHistory.cashCollected}</span>
                </div>
              )}
            </div>

            <button
              onClick={() => setSelectedHistory(null)}
              className="w-full py-2 rounded-xl bg-slate-900 text-white font-bold text-xs"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
