import React, { useState } from 'react';
import {
  Wallet,
  Truck,
  Heart,
  Flame,
  Bike,
  X,
  ArrowUpRight,
  TrendingUp,
  CheckCircle2,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useToast } from '../components/Toast';

export const EarningsTab: React.FC = () => {
  const { session, trips, todayTotal, weekTotal, profile } = useApp();
  const { showToast } = useToast();

  const [selectedMonth, setSelectedMonth] = useState('October 2026');
  const [showAllTrips, setShowAllTrips] = useState(false);
  const [showCashOutModal, setShowCashOutModal] = useState(false);
  const [payoutSuccess, setPayoutSuccess] = useState(false);
  const [selectedDayIdx, setSelectedDayIdx] = useState<number>(() => (new Date().getDay() + 6) % 7);

  const handleExecutePayout = () => {
    if (todayTotal <= 0) {
      showToast('Available balance is ₹0. Complete orders to earn.', 'error');
      return;
    }
    setPayoutSuccess(true);
    showToast(`₹${todayTotal.toFixed(0)} sent to ${profile.bank.holderName || profile.name || 'bank'} via IMPS`, 'success');
  };

  // Week breakdown (Mon - Sun)
  const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const todayDayIdx = (new Date().getDay() + 6) % 7; // 0 = Mon, 6 = Sun

  const weekBars = daysOfWeek.map((day, idx) => {
    const isToday = idx === todayDayIdx;
    let val = isToday ? todayTotal : Math.max(0, (weekTotal / 5) * (0.6 + (idx % 3) * 0.28));
    if (idx > todayDayIdx) val = 0; // future days
    return {
      label: day,
      value: val,
      isToday,
      isSelected: idx === selectedDayIdx,
    };
  });

  const maxVal = Math.max(1, ...weekBars.map((b) => b.value));
  const activeDayBar = weekBars[selectedDayIdx];

  // Today's breakdown
  const todayTrips = trips.filter(
    (t) => new Date(t.createdAt).toDateString() === new Date().toDateString()
  );
  const basePayTotal = todayTrips.reduce((s, t) => s + t.baseFare + t.distanceFare, 0) || Math.round(todayTotal * 0.7);
  const tipsTotal = todayTrips.reduce((s, t) => s + t.tips, 0) || Math.round(todayTotal * 0.12);
  const incentivesTotal = todayTrips.reduce((s, t) => s + t.incentive + t.surge, 0) || Math.round(todayTotal * 0.18);
  const codCashPending = trips.filter((t) => t.isCod).reduce((s, t) => s + t.cashCollected, 0);

  const formatTripTime = (iso: string) => {
    try {
      const dt = new Date(iso);
      return dt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
    } catch (_) {
      return '';
    }
  };

  const displayName = profile.name || session.name || session.username || 'Partner';

  return (
    <div className="min-h-screen bg-[#0A120D] text-white pb-28">
      {/* Sleek Compact Header (No refresh button) */}
      <header className="sticky top-0 z-30 bg-[#0A120D]/95 backdrop-blur-md px-4 py-2.5 flex items-center justify-between border-b border-white/5">
        <div>
          <h2 className="text-sm font-extrabold tracking-wide text-white">Earnings Hub</h2>
          <span className="text-[10px] text-slate-400 font-semibold">{displayName} • Shift Payouts</span>
        </div>
        <select
          value={selectedMonth}
          onChange={(e) => setSelectedMonth(e.target.value)}
          className="bg-slate-900 text-[10px] text-slate-300 font-bold border border-white/10 rounded-lg px-2 py-1 outline-none cursor-pointer"
        >
          <option value="October 2026">Oct 2026</option>
          <option value="September 2026">Sep 2026</option>
          <option value="August 2026">Aug 2026</option>
        </select>
      </header>

      <div className="p-3 space-y-3.5 max-w-md mx-auto">
        {/* Available Balance Hero: Compact */}
        <div className="bg-gradient-to-b from-[#142319] to-[#0E1A12] rounded-2xl p-4 border border-emerald-500/20 text-center shadow-lg relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-[#00E676]/10 rounded-full blur-xl pointer-events-none" />

          <span className="text-[9px] font-black uppercase text-emerald-400 tracking-widest block">
            AVAILABLE BALANCE
          </span>
          <h1 className="text-3xl font-black text-white mt-1 tracking-tight">
            ₹ {todayTotal.toFixed(0)}
          </h1>
          <p className="text-[10px] text-slate-400 font-medium mt-0.5">
            Settled instantly to {profile.bank.holderName || displayName}'s bank account
          </p>

          <div className="mt-3">
            <button
              onClick={() => {
                setPayoutSuccess(false);
                setShowCashOutModal(true);
              }}
              className="w-full h-10 bg-[#00E676] hover:bg-[#00c864] text-slate-950 font-black rounded-xl flex items-center justify-center gap-1.5 shadow-md shadow-emerald-500/20 active:scale-[0.99] transition cursor-pointer text-xs"
            >
              <Wallet className="w-4 h-4 text-slate-950" />
              <span>Cash Out Now</span>
              <ArrowUpRight className="w-3.5 h-3.5 text-slate-950" />
            </button>
          </div>
        </div>

        {/* Weekly Earnings Chart: Compact */}
        <div className="bg-[#121E15] rounded-2xl p-3.5 border border-white/5 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-bold text-white text-xs">Weekly Overview</h3>
              <p className="text-[10px] text-slate-400 font-medium">
                {activeDayBar.label}: <strong className="text-white">₹{activeDayBar.value.toFixed(0)}</strong>
              </p>
            </div>
            <span className="px-2 py-0.5 rounded-lg bg-emerald-500/10 text-[#00E676] text-[10px] font-bold border border-emerald-500/20">
              Week: ₹ {weekTotal.toFixed(0)}
            </span>
          </div>

          <div className="h-20 mt-4 flex items-end justify-between gap-1.5 px-1">
            {weekBars.map((bar, idx) => {
              const heightPct = bar.value > 0 ? Math.max(15, Math.round((bar.value / maxVal) * 100)) : 8;
              return (
                <button
                  key={bar.label}
                  onClick={() => setSelectedDayIdx(idx)}
                  className="flex-1 flex flex-col items-center gap-1.5 cursor-pointer group"
                >
                  <div className="w-full flex justify-center h-14 items-end">
                    <div
                      style={{ height: `${heightPct}%` }}
                      className={`w-2.5 rounded-full transition-all duration-300 ${
                        bar.isSelected
                          ? 'bg-[#00E676] ring-1 ring-emerald-400/40 shadow-sm'
                          : bar.isToday
                          ? 'bg-[#00E676]/60'
                          : 'bg-[#243528]'
                      }`}
                    />
                  </div>
                  <span
                    className={`text-[10px] font-bold ${
                      bar.isSelected
                        ? 'text-[#00E676] font-black'
                        : 'text-slate-400'
                    }`}
                  >
                    {bar.label}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Breakdown Grid: Compact */}
        <div>
          <h3 className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2 px-1">
            Today's Pay Breakdown
          </h3>
          <div className="grid grid-cols-2 gap-2">
            <div className="bg-[#121E15] p-3 rounded-xl border border-white/5">
              <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1">
                <Truck className="w-3 h-3 text-blue-400" /> Base & Distance
              </span>
              <p className="text-base font-extrabold text-white mt-1">₹ {basePayTotal}</p>
            </div>

            <div className="bg-[#121E15] p-3 rounded-xl border border-white/5">
              <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1">
                <Heart className="w-3 h-3 text-pink-400" /> Customer Tips
              </span>
              <p className="text-base font-extrabold text-white mt-1">₹ {tipsTotal}</p>
            </div>

            <div className="bg-[#121E15] p-3 rounded-xl border border-white/5">
              <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1">
                <Flame className="w-3 h-3 text-amber-400" /> Surge & Targets
              </span>
              <p className="text-base font-extrabold text-white mt-1">₹ {incentivesTotal}</p>
            </div>

            <div className="bg-[#121E15] p-3 rounded-xl border border-white/5">
              <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1">
                <TrendingUp className="w-3 h-3 text-[#00E676]" /> Target Bonus
              </span>
              <p className="text-base font-extrabold text-[#00E676] mt-1">₹ 400</p>
            </div>
          </div>
        </div>

        {/* COD Cash Pending Card */}
        {codCashPending > 0 && (
          <div className="bg-amber-950/30 border border-amber-500/30 rounded-xl p-3 flex items-center justify-between text-xs">
            <div>
              <span className="font-bold text-amber-400 block text-xs">Pending COD Cash In Hand</span>
              <span className="text-slate-300 text-[10px]">To be deposited at nearest partner hub</span>
            </div>
            <span className="text-sm font-extrabold text-amber-300">₹ {codCashPending}</span>
          </div>
        )}

        {/* Recent Completed Trips */}
        <div>
          <div className="flex items-center justify-between mb-2 px-1">
            <h3 className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
              Recent Trips ({trips.length})
            </h3>
            {trips.length > 3 && (
              <button
                onClick={() => setShowAllTrips(!showAllTrips)}
                className="text-[10px] font-bold text-[#00E676] hover:underline"
              >
                {showAllTrips ? 'Show Less' : 'See All'}
              </button>
            )}
          </div>

          {trips.length === 0 ? (
            <div className="bg-[#121E15] p-4 rounded-xl border border-white/5 text-center text-xs text-slate-400">
              No trips recorded for this shift yet. Accept orders to build earnings!
            </div>
          ) : (
            <div className="space-y-2">
              {(showAllTrips ? trips : trips.slice(0, 4)).map((trip, idx) => (
                <div
                  key={`${trip.orderId}-${idx}`}
                  className="bg-[#121E15] p-2.5 rounded-xl border border-white/5 flex items-center justify-between"
                >
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-[#00E676] flex items-center justify-center">
                      <Bike className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="font-bold text-white text-xs">
                        {trip.orderId === 0 ? 'Delivery Trip' : `Order #${trip.orderId}`}
                      </h4>
                      <span className="text-[10px] text-slate-400">
                        {formatTripTime(trip.createdAt)} • {trip.isCod ? 'COD collected' : 'Prepaid'}
                      </span>
                    </div>
                  </div>

                  <div className="text-right">
                    <span className="text-xs font-bold text-white block">
                      ₹ {trip.total.toFixed(0)}
                    </span>
                    <span className="text-[9px] font-bold text-[#00E676]">Completed</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Cash Out Modal: Compact */}
      {showCashOutModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#142319] text-white rounded-2xl p-4 max-w-sm w-full shadow-2xl border border-emerald-500/30">
            <div className="flex items-center justify-between pb-2 border-b border-white/10">
              <h3 className="text-xs font-bold text-white flex items-center gap-1.5">
                <Wallet className="w-4 h-4 text-[#00E676]" />
                <span>Instant Cash Out</span>
              </h3>
              <button
                onClick={() => setShowCashOutModal(false)}
                className="p-1 rounded-full text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {!payoutSuccess ? (
              <div className="py-3 space-y-3">
                <div className="text-center py-1">
                  <span className="text-[10px] text-slate-400 font-bold uppercase">Payout Amount</span>
                  <h2 className="text-2xl font-black text-[#00E676] mt-0.5">₹ {todayTotal.toFixed(0)}</h2>
                </div>

                <div className="bg-[#0A120D] p-3 rounded-xl border border-white/5 space-y-1.5 text-[11px]">
                  <div className="flex justify-between text-slate-400">
                    <span>Beneficiary Name</span>
                    <strong className="text-white">{profile.bank.holderName || displayName}</strong>
                  </div>
                  <div className="flex justify-between text-slate-400">
                    <span>Bank Account</span>
                    <strong className="text-white">•••• {profile.bank.accountNumber?.slice(-4) || '9128'}</strong>
                  </div>
                  <div className="flex justify-between text-slate-400">
                    <span>Transfer Mode</span>
                    <strong className="text-emerald-400">IMPS / Instant (Free)</strong>
                  </div>
                </div>

                <button
                  onClick={handleExecutePayout}
                  className="w-full py-2.5 bg-[#00E676] hover:bg-[#00c864] text-slate-950 font-bold rounded-xl text-xs transition shadow-md active:scale-95"
                >
                  Confirm & Transfer to Bank
                </button>
              </div>
            ) : (
              <div className="py-4 text-center space-y-2">
                <div className="w-12 h-12 rounded-full bg-emerald-500/20 text-[#00E676] flex items-center justify-center mx-auto animate-bounce">
                  <CheckCircle2 className="w-6 h-6" />
                </div>
                <h4 className="text-base font-bold text-white">Payout Initiated!</h4>
                <p className="text-[11px] text-slate-400 max-w-xs mx-auto">
                  ₹{todayTotal.toFixed(0)} has been credited to your bank account via instant IMPS transfer.
                </p>
                <button
                  onClick={() => setShowCashOutModal(false)}
                  className="w-full py-2 bg-white/10 hover:bg-white/20 text-white font-bold rounded-xl text-xs transition mt-2"
                >
                  Done
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
