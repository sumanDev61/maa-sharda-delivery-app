import React, { useState } from 'react';
import {
  Star,
  Edit2,
  Calendar,
  ChevronRight,
  CreditCard,
  FileText,
  Settings,
  HelpCircle,
  FileCheck,
  LogOut,
  Bike,
  QrCode,
  Flame,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useToast } from '../components/Toast';
import {
  GeneralInfoModal,
  VehicleDetailsModal,
  BankDetailsModal,
  DocumentsModal,
  SettingsModal,
  HelpSupportModal,
  PoliciesModal,
} from './ProfileModals';

interface ProfileTabProps {
  onNavigateToTab: (index: number) => void;
}

export const ProfileTab: React.FC<ProfileTabProps> = ({ onNavigateToTab }) => {
  const {
    profile,
    session,
    metrics,
    checkedInDays,
    toggleAttendanceForToday,
    logout,
  } = useApp();

  const { showToast } = useToast();
  const [activeModal, setActiveModal] = useState<string | null>(null);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showIdCard, setShowIdCard] = useState(false);

  const today = new Date().toISOString().split('T')[0];
  const isCheckedInToday = checkedInDays.includes(today);

  const handleAttendance = () => {
    const checked = toggleAttendanceForToday();
    showToast(checked ? 'Daily shift checked in! Attendance recorded.' : 'Daily shift checked out.', checked ? 'success' : 'info');
  };

  const displayName = profile.name || session.name || session.username || 'Partner';
  const displayPhone = session.phone ? `+91 ${session.phone}` : profile.email || 'Registered Partner';
  const displayId = session.riderId || 'MS-4921';

  return (
    <div className="pb-28 bg-slate-50 min-h-screen">
      {/* Top Banner: Compact Header */}
      <div className="bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 px-4 pt-5 pb-9 rounded-b-2xl text-white shadow-md border-b border-slate-800">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-extrabold tracking-tight text-white">Rider Account</h2>
            <span className="text-[11px] text-slate-400 font-semibold">Maa Sharda Partner Profile</span>
          </div>
          <button
            onClick={() => setShowIdCard(true)}
            className="px-2.5 py-1 rounded-xl bg-slate-800 text-[#00E676] border border-emerald-500/30 font-bold text-xs flex items-center gap-1 active:scale-95 transition"
          >
            <QrCode className="w-3.5 h-3.5" />
            <span>Digital ID</span>
          </button>
        </div>
      </div>

      <div className="px-3 -mt-6 space-y-3 max-w-md mx-auto">
        {/* Profile Card: Compact */}
        <div className="bg-white rounded-2xl p-3.5 border border-slate-200/90 shadow-sm">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-slate-900 text-[#00E676] flex items-center justify-center font-black text-lg shadow-sm border border-emerald-500/30">
                {displayName.charAt(0).toUpperCase()}
              </div>

              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="font-extrabold text-slate-900 text-sm leading-tight truncate max-w-[160px]">
                    {displayName}
                  </h3>
                  <span className="w-3.5 h-3.5 rounded-full bg-[#00E676] text-slate-950 flex items-center justify-center text-[9px] font-black">
                    ✓
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-semibold mt-0.5">
                  {displayPhone}
                </p>

                <div className="flex items-center gap-1.5 mt-1.5">
                  <span className="inline-flex items-center gap-0.5 px-2 py-0.2 rounded-full text-[10px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                    <Star className="w-2.5 h-2.5 fill-current text-amber-500" />
                    {metrics.rating.toFixed(1)}
                  </span>
                  <span className="text-[10px] font-bold text-slate-600">
                    {profile.vehicle.type.toUpperCase()} • ID: {displayId}
                  </span>
                </div>
              </div>
            </div>

            <button
              onClick={() => setActiveModal('general')}
              className="p-1.5 rounded-lg bg-slate-50 hover:bg-slate-100 text-slate-600 border border-slate-200 transition"
              title="Edit Profile"
            >
              <Edit2 className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="mt-3 pt-2.5 border-t border-slate-100 grid grid-cols-3 divide-x divide-slate-100 text-center text-xs">
            <div>
              <span className="text-[9px] font-bold text-slate-400 block uppercase">ACCEPTANCE</span>
              <strong className="text-xs font-black text-slate-900">{Math.round(metrics.acceptanceRate * 100)}%</strong>
            </div>
            <div>
              <span className="text-[9px] font-bold text-slate-400 block uppercase">COMPLETION</span>
              <strong className="text-xs font-black text-slate-900">{Math.round(metrics.completionRate * 100)}%</strong>
            </div>
            <div>
              <span className="text-[9px] font-bold text-slate-400 block uppercase">TRIPS</span>
              <strong className="text-xs font-black text-slate-900">{metrics.completedTrips}</strong>
            </div>
          </div>
        </div>

        {/* Attendance Check-in Card: Compact */}
        <div className="bg-white rounded-2xl p-3 border border-slate-200 shadow-sm flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-[#00E676] flex items-center justify-center shrink-0 border border-emerald-100">
              <Calendar className="w-4 h-4" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h4 className="font-bold text-slate-900 text-xs">Shift Attendance</h4>
                <span className="px-1.5 py-0.2 rounded-full text-[9px] font-bold bg-amber-50 text-amber-800 flex items-center gap-0.5">
                  <Flame className="w-2.5 h-2.5 text-amber-500 fill-current" />
                  <span>{checkedInDays.length}d streak</span>
                </span>
              </div>
              <p className="text-[10px] text-slate-400 font-medium">
                {isCheckedInToday ? 'Checked in • Shift active' : 'Mark daily shift to unlock bonuses'}
              </p>
            </div>
          </div>

          <button
            onClick={handleAttendance}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
              isCheckedInToday
                ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                : 'bg-slate-900 text-white hover:bg-slate-800'
            }`}
          >
            {isCheckedInToday ? '✓ Present' : 'Check In'}
          </button>
        </div>

        {/* Profile Management Links */}
        <div className="bg-white rounded-2xl p-1.5 border border-slate-200 shadow-sm divide-y divide-slate-100">
          <button
            onClick={() => setActiveModal('vehicle')}
            className="w-full p-2.5 flex items-center justify-between text-left hover:bg-slate-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
                <Bike className="w-3.5 h-3.5" />
              </div>
              <div>
                <span className="font-bold text-slate-900 text-xs block">Vehicle & RC Details</span>
                <span className="text-[10px] text-slate-400">{profile.vehicle.type.toUpperCase()} • {profile.vehicle.number || 'Not registered'}</span>
              </div>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('bank')}
            className="w-full p-2.5 flex items-center justify-between text-left hover:bg-slate-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
                <CreditCard className="w-3.5 h-3.5" />
              </div>
              <div>
                <span className="font-bold text-slate-900 text-xs block">Bank Account for Payouts</span>
                <span className="text-[10px] text-slate-400">
                  {profile.bank.holderName ? `${profile.bank.holderName} (A/C: ••••${profile.bank.accountNumber?.slice(-4) || '••••'})` : 'Configure Account'}
                </span>
              </div>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('documents')}
            className="w-full p-2.5 flex items-center justify-between text-left hover:bg-slate-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
                <FileCheck className="w-3.5 h-3.5" />
              </div>
              <div>
                <span className="font-bold text-slate-900 text-xs block">KYC Verification Documents</span>
                <span className="text-[10px] text-slate-400">Aadhaar, License, RC Card</span>
              </div>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('settings')}
            className="w-full p-2.5 flex items-center justify-between text-left hover:bg-slate-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
                <Settings className="w-3.5 h-3.5" />
              </div>
              <div>
                <span className="font-bold text-slate-900 text-xs block">App Settings & Alerts</span>
                <span className="text-[10px] text-slate-400">Notifications, Sounds, Language</span>
              </div>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('help')}
            className="w-full p-2.5 flex items-center justify-between text-left hover:bg-slate-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
                <HelpCircle className="w-3.5 h-3.5" />
              </div>
              <div>
                <span className="font-bold text-slate-900 text-xs block">Rider Support & Helpdesk</span>
                <span className="text-[10px] text-slate-400">Contact Dispatch Desk</span>
              </div>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('policies')}
            className="w-full p-2.5 flex items-center justify-between text-left hover:bg-slate-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
                <FileText className="w-3.5 h-3.5" />
              </div>
              <div>
                <span className="font-bold text-slate-900 text-xs block">Safety & Partner Guidelines</span>
                <span className="text-[10px] text-slate-400">Terms of Service</span>
              </div>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
          </button>

          {/* Secure Logout Action */}
          <button
            onClick={() => setShowLogoutConfirm(true)}
            className="w-full p-2.5 flex items-center justify-between text-left text-rose-600 hover:bg-rose-50 transition rounded-xl"
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-rose-100/70 text-rose-600 flex items-center justify-center">
                <LogOut className="w-3.5 h-3.5" />
              </div>
              <span className="font-bold text-xs">Sign Out from Device</span>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-rose-400" />
          </button>
        </div>
      </div>

      {/* Digital ID Modal */}
      {showIdCard && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 text-white rounded-2xl p-5 max-w-sm w-full shadow-2xl border border-emerald-500/40">
            <div className="text-center pb-3 border-b border-slate-800">
              <span className="text-[10px] font-black uppercase text-[#00E676] tracking-widest block">
                MAA SHARDA GO DELIVERY PARTNER
              </span>
              <h3 className="text-base font-extrabold mt-0.5">{displayName}</h3>
              <p className="text-[10px] text-slate-400">Partner ID: {displayId}</p>
            </div>

            <div className="py-4 flex flex-col items-center">
              <div className="w-32 h-32 bg-white p-2 rounded-xl flex items-center justify-center shadow-lg">
                <div className="w-full h-full border-2 border-slate-950 flex flex-col items-center justify-center text-slate-950 font-mono text-[10px] font-black text-center p-1">
                  <div className="w-16 h-16 border-2 border-slate-950 flex items-center justify-center">
                    QR CODE
                  </div>
                  <span className="mt-1">{displayId}</span>
                </div>
              </div>

              <div className="mt-4 w-full bg-slate-800/80 rounded-xl p-2.5 text-xs space-y-1.5">
                <div className="flex justify-between text-slate-400">
                  <span>Registered Mobile</span>
                  <strong className="text-white">{displayPhone}</strong>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Operating Zone</span>
                  <strong className="text-white">{profile.city || 'Bhopal'}</strong>
                </div>
              </div>
            </div>

            <button
              onClick={() => {
                showToast('Digital pass verified', 'success');
                setShowIdCard(false);
              }}
              className="w-full py-2.5 rounded-xl bg-[#00E676] text-slate-950 font-bold text-xs"
            >
              Done
            </button>
          </div>
        </div>
      )}

      {/* Logout confirmation */}
      {showLogoutConfirm && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-5 max-w-sm w-full shadow-2xl text-center">
            <div className="w-10 h-10 bg-rose-50 text-rose-600 rounded-full flex items-center justify-center mx-auto mb-2.5">
              <LogOut className="w-5 h-5" />
            </div>
            <h3 className="text-base font-bold text-slate-900">Sign Out?</h3>
            <p className="text-xs text-slate-500 mt-1">
              You will be signed out from your rider account. Without logging in, app access will be locked.
            </p>
            <div className="grid grid-cols-2 gap-2 mt-4">
              <button
                onClick={() => setShowLogoutConfirm(false)}
                className="py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-xs"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  setShowLogoutConfirm(false);
                  logout();
                }}
                className="py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs shadow-sm"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Sub Modals */}
      {activeModal === 'general' && <GeneralInfoModal isOpen={true} onClose={() => setActiveModal(null)} />}
      {activeModal === 'vehicle' && <VehicleDetailsModal isOpen={true} onClose={() => setActiveModal(null)} />}
      {activeModal === 'bank' && <BankDetailsModal isOpen={true} onClose={() => setActiveModal(null)} />}
      {activeModal === 'documents' && <DocumentsModal isOpen={true} onClose={() => setActiveModal(null)} />}
      {activeModal === 'settings' && <SettingsModal isOpen={true} onClose={() => setActiveModal(null)} />}
      {activeModal === 'help' && <HelpSupportModal isOpen={true} onClose={() => setActiveModal(null)} />}
      {activeModal === 'policies' && <PoliciesModal isOpen={true} onClose={() => setActiveModal(null)} />}
    </div>
  );
};
