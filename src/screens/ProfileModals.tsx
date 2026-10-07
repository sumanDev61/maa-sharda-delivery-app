import React, { useState } from 'react';
import {
  X,
  User,
  Phone,
  Mail,
  MapPin,
  CheckCircle2,
  FileText,
  Upload,
  Lock,
  Headphones,
  FileCheck,
  ChevronRight,
  ChevronDown,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { VehicleType, DocumentType } from '../types';
import { PrimaryButton } from '../components/PrimaryButton';
import { useToast } from '../components/Toast';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const GeneralInfoModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  const { profile, session, updateGeneralInfo } = useApp();
  const [name, setName] = useState(profile.name);
  const [email, setEmail] = useState(profile.email);
  const [address, setAddress] = useState(profile.address);
  const [saving, setSaving] = useState(false);

  if (!isOpen) return null;

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    await updateGeneralInfo({ name, email, address });
    setSaving(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">General Info</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSave} className="mt-4 space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Full Name</label>
            <div className="flex items-center rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3">
              <User className="w-5 h-5 text-slate-400 mr-2" />
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-transparent font-bold text-slate-900 outline-none"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Phone Number</label>
            <div className="flex items-center rounded-2xl bg-slate-100 border border-slate-200 px-4 py-3">
              <Phone className="w-5 h-5 text-slate-400 mr-2" />
              <input
                type="text"
                readOnly
                value={session.phone || '9876543210'}
                className="w-full bg-transparent font-bold text-slate-600 outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Email</label>
            <div className="flex items-center rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3">
              <Mail className="w-5 h-5 text-slate-400 mr-2" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-transparent font-bold text-slate-900 outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Current Address</label>
            <div className="flex items-start rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3">
              <MapPin className="w-5 h-5 text-slate-400 mr-2 mt-0.5" />
              <textarea
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                rows={2}
                className="w-full bg-transparent font-medium text-slate-900 outline-none resize-none"
              />
            </div>
          </div>

          <div className="pt-2">
            <PrimaryButton label="Save Changes" type="submit" isLoading={saving} />
          </div>
        </form>
      </div>
    </div>
  );
};

export const VehicleDetailsModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  const { profile, updateVehicle } = useApp();
  const [type, setType] = useState<VehicleType>(profile.vehicle.type || 'bike');
  const [number, setNumber] = useState(profile.vehicle.number || '');
  const [dlNumber, setDlNumber] = useState(profile.drivingLicenseNumber || '');
  const [saving, setSaving] = useState(false);

  if (!isOpen) return null;

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    await updateVehicle({ type, number, drivingLicenseNumber: dlNumber });
    setSaving(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">Vehicle Details</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSave} className="mt-4 space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Vehicle Type</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value as VehicleType)}
              className="w-full rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3 font-bold text-slate-900 outline-none"
            >
              <option value="bike">Bike</option>
              <option value="scooter">Electric / Scooter</option>
              <option value="cycle">Cycle</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Registration Number</label>
            <input
              type="text"
              value={number}
              onChange={(e) => setNumber(e.target.value.toUpperCase())}
              placeholder="MP 04 AB 1234"
              className="w-full rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3 font-bold text-slate-900 uppercase outline-none"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Driving License Number</label>
            <input
              type="text"
              value={dlNumber}
              onChange={(e) => setDlNumber(e.target.value.toUpperCase())}
              placeholder="MP-04-2022-0049182"
              className="w-full rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3 font-bold text-slate-900 uppercase outline-none"
              required
            />
          </div>

          <div className="pt-2">
            <PrimaryButton label="Update Vehicle" type="submit" isLoading={saving} />
          </div>
        </form>
      </div>
    </div>
  );
};

export const BankDetailsModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  const { profile, updateBank } = useApp();
  const [holder, setHolder] = useState(profile.bank.holderName || '');
  const [account, setAccount] = useState(profile.bank.accountNumber || '');
  const [ifsc, setIfsc] = useState(profile.bank.ifsc || '');
  const [saving, setSaving] = useState(false);

  if (!isOpen) return null;

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    await updateBank({ holder, account, ifsc });
    setSaving(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">Bank Details</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSave} className="mt-4 space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Account Holder Name</label>
            <input
              type="text"
              value={holder}
              onChange={(e) => setHolder(e.target.value)}
              className="w-full rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3 font-bold text-slate-900 outline-none"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">Account Number</label>
            <input
              type="text"
              value={account}
              onChange={(e) => setAccount(e.target.value)}
              className="w-full rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3 font-bold text-slate-900 outline-none"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 mb-1">IFSC Code</label>
            <input
              type="text"
              value={ifsc}
              onChange={(e) => setIfsc(e.target.value.toUpperCase())}
              className="w-full rounded-2xl bg-slate-50 border border-slate-200 px-4 py-3 font-bold text-slate-900 uppercase outline-none"
              required
            />
          </div>

          <div className="pt-2">
            <PrimaryButton label="Save Bank Details" type="submit" isLoading={saving} />
          </div>
        </form>
      </div>
    </div>
  );
};

export const DocumentsModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  const { profile, setDocumentStatus } = useApp();
  const [uploading, setUploading] = useState<string | null>(null);

  if (!isOpen) return null;

  const docs = [
    { type: 'idProof' as DocumentType, label: 'Aadhar Card', status: profile.documents.idProof },
    { type: 'drivingLicense' as DocumentType, label: 'Driving License', status: profile.documents.drivingLicense },
    { type: 'vehicleRc' as DocumentType, label: 'Vehicle RC', status: profile.documents.vehicleRc },
  ];

  const handleUpload = async (type: DocumentType) => {
    setUploading(type);
    await new Promise((r) => setTimeout(r, 600));
    await setDocumentStatus(type, 'verified');
    setUploading(null);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">Partner Documents</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="mt-4 space-y-3">
          {docs.map((d) => (
            <div
              key={d.type}
              className="p-3.5 bg-slate-50 border border-slate-200 rounded-2xl flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-slate-500" />
                <div>
                  <h5 className="font-bold text-slate-900 text-sm">{d.label}</h5>
                  <span
                    className={`text-xs font-semibold ${
                      d.status === 'verified'
                        ? 'text-emerald-600'
                        : d.status === 'pending'
                        ? 'text-amber-600'
                        : 'text-red-500'
                    }`}
                  >
                    {d.status === 'verified'
                      ? '✓ Verified'
                      : d.status === 'pending'
                      ? '⏳ In Review'
                      : 'Missing'}
                  </span>
                </div>
              </div>

              <button
                disabled={uploading === d.type}
                onClick={() => handleUpload(d.type)}
                className="px-3 py-1.5 rounded-xl bg-white border border-slate-200 text-xs font-bold text-slate-800 hover:bg-slate-100 transition"
              >
                {uploading === d.type ? 'Uploading...' : 'Re-upload'}
              </button>
            </div>
          ))}
        </div>

        <button
          onClick={onClose}
          className="mt-6 w-full py-3 bg-slate-900 text-white rounded-2xl font-bold text-sm"
        >
          Done
        </button>
      </div>
    </div>
  );
};

export const SettingsModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  const { settings, updateSettings } = useApp();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">App Settings</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="mt-4 space-y-4">
          <div className="flex items-center justify-between py-2 border-b border-slate-100">
            <div>
              <h5 className="font-bold text-slate-900 text-sm">Order Alerts</h5>
              <p className="text-xs text-slate-400">Receive alert popups on new requests</p>
            </div>
            <input
              type="checkbox"
              checked={settings.orderAlertsEnabled}
              onChange={(e) => updateSettings({ orderAlertsEnabled: e.target.checked })}
              className="w-5 h-5 accent-[#00E676] cursor-pointer"
            />
          </div>

          <div className="flex items-center justify-between py-2 border-b border-slate-100">
            <div>
              <h5 className="font-bold text-slate-900 text-sm">Sound Alert</h5>
              <p className="text-xs text-slate-400">Play chime tone for new incoming orders</p>
            </div>
            <input
              type="checkbox"
              checked={settings.soundEnabled}
              onChange={(e) => updateSettings({ soundEnabled: e.target.checked })}
              className="w-5 h-5 accent-[#00E676] cursor-pointer"
            />
          </div>

          <div className="flex items-center justify-between py-2 border-b border-slate-100">
            <div>
              <h5 className="font-bold text-slate-900 text-sm">Vibration</h5>
              <p className="text-xs text-slate-400">Haptic vibration feedback</p>
            </div>
            <input
              type="checkbox"
              checked={settings.vibrationEnabled}
              onChange={(e) => updateSettings({ vibrationEnabled: e.target.checked })}
              className="w-5 h-5 accent-[#00E676] cursor-pointer"
            />
          </div>

          <div className="flex items-center justify-between py-2 border-b border-slate-100">
            <div>
              <h5 className="font-bold text-slate-900 text-sm">Language</h5>
              <p className="text-xs text-slate-400">App interface language</p>
            </div>
            <select
              value={settings.language}
              onChange={(e) => updateSettings({ language: e.target.value as any })}
              className="text-xs font-bold text-slate-800 bg-slate-100 p-2 rounded-xl outline-none"
            >
              <option value="English">English</option>
              <option value="Hindi">हिंदी (Hindi)</option>
            </select>
          </div>
        </div>

        <button
          onClick={onClose}
          className="mt-6 w-full py-3 bg-slate-900 text-white rounded-2xl font-bold text-sm"
        >
          Save & Close
        </button>
      </div>
    </div>
  );
};

export const HelpSupportModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  const { showToast } = useToast();
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  if (!isOpen) return null;

  const faqs = [
    {
      q: 'How do I go online to receive orders?',
      a: 'Toggle the switch in the top right corner of the Home screen to Online. Ensure your GPS location is active.',
    },
    {
      q: 'How are delivery payouts calculated?',
      a: 'Earnings include base pay, per-kilometer distance fee, customer tips, surge bonus during peak hours, and weekly milestone incentives.',
    },
    {
      q: 'What should I do if the customer is unreachable?',
      a: 'Use the in-app Call or Chat buttons. If no response after 5 minutes, mark the issue via the "Report Issue" sheet to alert support.',
    },
  ];

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl max-h-[85vh] flex flex-col animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">Help & Support</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="mt-4 space-y-4 overflow-y-auto flex-1 pr-1">
          {/* Quick contact buttons */}
          <div className="grid grid-cols-2 gap-3">
            <a
              href="tel:1800123456"
              className="p-3 bg-emerald-50 text-emerald-800 rounded-2xl font-bold text-xs flex items-center justify-center gap-2 border border-emerald-100"
            >
              <Headphones className="w-4 h-4" />
              <span>Call Helpline</span>
            </a>
            <button
              onClick={() => showToast('Support Live Chat connected! Support agent online.', 'info')}
              className="p-3 bg-blue-50 text-blue-800 rounded-2xl font-bold text-xs flex items-center justify-center gap-2 border border-blue-100 cursor-pointer"
            >
              <span>💬 Live Chat</span>
            </button>
          </div>

          <h4 className="font-bold text-slate-800 text-xs uppercase tracking-wider pt-2">
            Frequently Asked Questions
          </h4>

          <div className="space-y-2">
            {faqs.map((f, i) => (
              <div key={i} className="border border-slate-200 rounded-2xl overflow-hidden">
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full p-3.5 text-left font-bold text-slate-800 text-xs flex items-center justify-between"
                >
                  <span>{f.q}</span>
                  <ChevronDown
                    className={`w-4 h-4 text-slate-400 transform transition ${
                      openFaq === i ? 'rotate-180' : ''
                    }`}
                  />
                </button>
                {openFaq === i && (
                  <div className="p-3.5 bg-slate-50 text-xs text-slate-600 border-t border-slate-100 leading-relaxed font-medium">
                    {f.a}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        <button
          onClick={onClose}
          className="mt-6 w-full py-3 bg-slate-900 text-white rounded-2xl font-bold text-sm"
        >
          Close
        </button>
      </div>
    </div>
  );
};

export const PoliciesModal: React.FC<ModalProps> = ({ isOpen, onClose }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl max-h-[85vh] flex flex-col animate-in slide-in-from-bottom-5">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <h3 className="font-black text-slate-900 text-lg">Policies & Terms</h3>
          <button onClick={onClose} className="p-1 rounded-full text-slate-400 hover:text-slate-700">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="mt-4 space-y-4 overflow-y-auto flex-1 pr-1 text-xs text-slate-600 leading-relaxed">
          <div>
            <h5 className="font-bold text-slate-900 text-sm mb-1">Partner Terms</h5>
            <p>
              Use this app strictly for official Maa Sharda Go food delivery operations. Adhere to all local traffic laws and road safety regulations. Never disclose customer phone numbers or order security OTPs.
            </p>
          </div>

          <div>
            <h5 className="font-bold text-slate-900 text-sm mb-1">Privacy & Location</h5>
            <p>
              We collect background and foreground location data to assign nearby orders, estimate accurate delivery arrival times, and guarantee rider safety during active deliveries.
            </p>
          </div>

          <div>
            <h5 className="font-bold text-slate-900 text-sm mb-1">Cancellation Policy</h5>
            <p>
              Avoid frequent order rejections after accepting. Repeated cancellations after pickup may lead to temporary account suspension and forfeiture of weekly incentives.
            </p>
          </div>
        </div>

        <button
          onClick={onClose}
          className="mt-6 w-full py-3 bg-slate-900 text-white rounded-2xl font-bold text-sm"
        >
          I Understand
        </button>
      </div>
    </div>
  );
};
