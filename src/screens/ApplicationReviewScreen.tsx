import React, { useState } from 'react';
import { CheckCircle2, Clock, LogOut, Sparkles } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { PrimaryButton } from '../components/PrimaryButton';

export const ApplicationReviewScreen: React.FC = () => {
  const { setBackgroundVerification, logout, profile, session } = useApp();
  const [checking, setChecking] = useState(false);

  const handleRefresh = async () => {
    setChecking(true);
    await new Promise((r) => setTimeout(r, 600));
    // Re-check saved verification status for this rider
    const saved = localStorage.getItem(`rider_verification_${session.riderId}`) || 'inReview';
    if (saved === 'verified') {
      setBackgroundVerification('verified');
    }
    setChecking(false);
  };

  const handleInstantApprove = () => {
    setBackgroundVerification('verified');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-between max-w-md mx-auto shadow-2xl p-4 text-slate-900">
      <div className="flex flex-col items-center text-center pt-4">
        <span className="font-extrabold text-slate-800 tracking-wider text-xs uppercase mb-6">
          MAA SHARDA GO
        </span>

        <div className="w-16 h-16 rounded-full bg-emerald-50 border-2 border-emerald-100 flex items-center justify-center text-[#00E676] mb-4 shadow-inner animate-pulse">
          <Clock className="w-8 h-8" />
        </div>

        <h1 className="text-lg font-extrabold text-slate-900">Application Under Review</h1>
        <p className="text-slate-500 text-xs mt-1 max-w-xs leading-relaxed">
          Thank you for registering, <strong>{profile.name || 'Partner'}</strong>. Dispatch team is validating your submitted documents.
        </p>

        {/* Review Timeline */}
        <div className="w-full bg-white rounded-2xl p-4 border border-slate-200 shadow-sm mt-5 text-left space-y-4">
          <div className="flex items-center justify-between pb-1.5 border-b border-slate-100">
            <span className="font-bold text-slate-800 text-xs">Review Timeline</span>
            <span className="px-2 py-0.2 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700">
              In Progress
            </span>
          </div>

          <div className="space-y-3">
            <div className="flex items-start gap-2.5">
              <div className="w-5 h-5 rounded-full bg-[#00E676] text-slate-900 flex items-center justify-center shrink-0 mt-0.5 shadow-sm">
                <CheckCircle2 className="w-3.5 h-3.5" />
              </div>
              <div>
                <h4 className="font-bold text-slate-900 text-xs">Profile & Vehicle Registered</h4>
                <p className="text-[10px] text-slate-400">Details logged in Maa Sharda system.</p>
              </div>
            </div>

            <div className="flex items-start gap-2.5">
              <div className="w-5 h-5 rounded-full bg-amber-500 text-white flex items-center justify-center shrink-0 mt-0.5 shadow-sm">
                <Clock className="w-3 h-3" />
              </div>
              <div>
                <h4 className="font-bold text-slate-900 text-xs">Document Verification</h4>
                <p className="text-[10px] text-slate-400">Verifying Aadhaar & Driving License.</p>
              </div>
            </div>

            <div className="flex items-start gap-2.5 opacity-40">
              <div className="w-5 h-5 rounded-full border border-slate-300 flex items-center justify-center shrink-0 mt-0.5" />
              <div>
                <h4 className="font-bold text-slate-700 text-xs">Final Dispatch Activation</h4>
                <p className="text-[10px] text-slate-400">Full activation for taking food deliveries.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Estimated Wait Card */}
        <div className="w-full bg-emerald-50/60 border border-emerald-100 rounded-xl p-3 mt-3 flex items-center gap-3 text-left">
          <Clock className="w-6 h-6 text-[#00E676] shrink-0" />
          <div>
            <span className="text-[9px] font-bold uppercase text-slate-500 tracking-wider">
              ESTIMATED ACTIVATION
            </span>
            <p className="text-sm font-extrabold text-slate-900">24-48 Hours</p>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="space-y-2 pt-4">
        <PrimaryButton
          label="Check Verification Status"
          onClick={handleRefresh}
          isLoading={checking}
        />

        {/* Fast-track button so reviewer can immediately enter app */}
        <button
          onClick={handleInstantApprove}
          className="w-full py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-[#00E676] font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm transition active:scale-[0.99]"
        >
          <Sparkles className="w-3.5 h-3.5" />
          <span>Approve & Enter Shift Dashboard</span>
        </button>

        <button
          onClick={logout}
          className="w-full py-2 text-slate-500 hover:text-slate-800 font-semibold text-xs flex items-center justify-center gap-1.5 transition"
        >
          <LogOut className="w-3.5 h-3.5" />
          <span>Log Out</span>
        </button>
      </div>
    </div>
  );
};
