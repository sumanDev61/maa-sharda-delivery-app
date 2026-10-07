import React, { useState } from 'react';
import {
  ArrowLeft,
  ArrowRight,
  CheckCircle,
  Clock,
  FileText,
  Lock,
  MapPin,
  Upload,
  User,
  Shield,
  Search,
  Check,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { VehicleType, DocumentType } from '../types';
import { PrimaryButton } from '../components/PrimaryButton';

const CITIES = [
  'Bhopal',
  'Indore',
  'Jabalpur',
  'Gwalior',
  'Ujjain',
  'Sagar',
  'Satna',
  'Rewa',
];

export const OnboardingScreen: React.FC = () => {
  const {
    profile,
    session,
    updateGeneralInfo,
    updateVehicle,
    updateBank,
    setDocumentStatus,
    setBackgroundVerification,
  } = useApp();

  const [step, setStep] = useState<number>(1);
  const [name, setName] = useState(profile.name || session.name || '');
  const [city, setCity] = useState(profile.city || 'Bhopal');
  const [showCityPicker, setShowCityPicker] = useState(false);
  const [citySearch, setCitySearch] = useState('');

  // Step 2
  const [vehicleType, setVehicleType] = useState<VehicleType>(profile.vehicle.type !== 'unknown' ? profile.vehicle.type : 'bike');
  const [regNumber, setRegNumber] = useState(profile.vehicle.number || '');
  const [dlNumber, setDlNumber] = useState(profile.drivingLicenseNumber || '');

  // Step 3
  const [bankHolder, setBankHolder] = useState(profile.bank.holderName || profile.name || session.name || '');
  const [bankAccount, setBankAccount] = useState(profile.bank.accountNumber || '');
  const [bankIfsc, setBankIfsc] = useState(profile.bank.ifsc || '');

  // Step 4
  const [uploadingDoc, setUploadingDoc] = useState<DocumentType | null>(null);

  const filteredCities = CITIES.filter((c) =>
    c.toLowerCase().includes(citySearch.toLowerCase().trim())
  );

  const handleStep1Submit = async () => {
    if (!name.trim() || !city.trim()) return;
    await updateGeneralInfo({ name, city });
    setStep(2);
  };

  const handleStep2Submit = async () => {
    if (!regNumber.trim() || !dlNumber.trim()) return;
    await updateVehicle({
      type: vehicleType,
      number: regNumber,
      drivingLicenseNumber: dlNumber,
    });
    setStep(3);
  };

  const handleStep3Submit = async () => {
    if (!bankHolder.trim() || !bankAccount.trim() || !bankIfsc.trim()) return;
    await updateBank({
      holder: bankHolder,
      account: bankAccount,
      ifsc: bankIfsc,
    });
    setStep(4);
  };

  const handleDocUpload = async (docType: DocumentType) => {
    setUploadingDoc(docType);
    await new Promise((r) => setTimeout(r, 600));
    await setDocumentStatus(docType, 'pending');
    setUploadingDoc(null);
  };

  const handleFinish = () => {
    // If not all uploaded, mark them pending for demo so user is not blocked
    if (profile.documents.idProof === 'missing') setDocumentStatus('idProof', 'pending');
    if (profile.documents.drivingLicense === 'missing') setDocumentStatus('drivingLicense', 'pending');
    if (profile.documents.vehicleRc === 'missing') setDocumentStatus('vehicleRc', 'pending');

    setBackgroundVerification('inReview');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-between max-w-md mx-auto shadow-2xl relative">
      {/* Top Header & Stepper */}
      <div className="bg-white border-b border-slate-200 px-6 py-4">
        <div className="flex items-center justify-between">
          {step > 1 ? (
            <button
              onClick={() => setStep(step - 1)}
              className="w-9 h-9 rounded-full hover:bg-slate-100 flex items-center justify-center text-slate-700"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
          ) : (
            <div className="w-9" />
          )}
          <span className="font-black text-slate-900 tracking-wider text-sm uppercase">
            Maa Sharda Go
          </span>
          <span className="text-xs font-bold text-slate-400">Step {step} of 4</span>
        </div>

        {/* Progress Bar */}
        <div className="flex items-center gap-2 mt-4">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className={`h-1.5 flex-1 rounded-full transition-all duration-300 ${
                i <= step ? 'bg-[#00E676]' : 'bg-slate-200'
              }`}
            />
          ))}
        </div>
      </div>

      {/* Step Content */}
      <div className="p-6 flex-1 flex flex-col justify-between overflow-y-auto">
        {step === 1 && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-black text-slate-900 leading-tight">
                Deliver with <br />
                <span className="text-[#00E676]">Maa Sharda Go</span>
              </h2>
              <p className="text-slate-500 text-sm mt-1">
                Join our community of riders and start earning today.
              </p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Full Name
                </label>
                <div className="flex items-center rounded-2xl bg-white border border-slate-200 px-4 py-3.5 shadow-sm">
                  <User className="w-5 h-5 text-slate-400 mr-2.5" />
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Rahul Sharma"
                    className="w-full bg-transparent text-slate-900 font-bold outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Mobile Number
                </label>
                <div className="flex items-center rounded-2xl bg-slate-100 border border-slate-200 px-4 py-3.5 shadow-sm">
                  <span className="text-slate-500 font-bold mr-2">+91</span>
                  <input
                    type="text"
                    readOnly
                    value={session.phone || '9876543210'}
                    className="w-full bg-transparent text-slate-700 font-bold outline-none"
                  />
                  <span className="flex items-center gap-1 text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
                    <CheckCircle className="w-3.5 h-3.5" />
                    Verified
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Select City
                </label>
                <button
                  type="button"
                  onClick={() => setShowCityPicker(true)}
                  className="w-full flex items-center justify-between rounded-2xl bg-white border border-slate-200 px-4 py-3.5 shadow-sm text-left hover:border-slate-300 transition"
                >
                  <div className="flex items-center gap-2.5">
                    <MapPin className="w-5 h-5 text-slate-400" />
                    <span className="font-bold text-slate-900">{city || 'Choose city'}</span>
                  </div>
                  <span className="text-xs font-bold text-[#00E676]">Change</span>
                </button>
              </div>
            </div>
          </div>
        )}

        {step === 2 && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-black text-slate-900">Vehicle Details</h2>
              <p className="text-slate-500 text-sm mt-1">Tell us what you drive to receive delivery orders.</p>
            </div>

            <div className="space-y-5">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-2.5">
                  Select Vehicle Type
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { type: 'cycle' as VehicleType, label: 'Cycle', icon: '🚲' },
                    { type: 'bike' as VehicleType, label: 'Bike', icon: '🏍️' },
                    { type: 'scooter' as VehicleType, label: 'Electric / Scooter', icon: '🛵' },
                  ].map((v) => (
                    <button
                      key={v.type}
                      type="button"
                      onClick={() => setVehicleType(v.type)}
                      className={`p-3.5 rounded-2xl border-2 flex flex-col items-center justify-center transition-all ${
                        vehicleType === v.type
                          ? 'border-[#00E676] bg-emerald-50/50 shadow-sm'
                          : 'border-slate-200 bg-white hover:border-slate-300'
                      }`}
                    >
                      <span className="text-2xl mb-1.5">{v.icon}</span>
                      <span className="text-xs font-black text-slate-800 text-center leading-tight">
                        {v.label}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Vehicle Registration Number
                </label>
                <input
                  type="text"
                  value={regNumber}
                  onChange={(e) => setRegNumber(e.target.value.toUpperCase())}
                  placeholder="MP 04 AB 1234"
                  className="w-full rounded-2xl bg-white border border-slate-200 px-4 py-3.5 text-slate-900 font-bold outline-none uppercase tracking-wide focus:border-[#00E676] shadow-sm"
                />
                <span className="text-xs text-slate-400 mt-1 block">
                  Standard format (e.g. MP 04 AB 1234)
                </span>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Driving License Number
                </label>
                <input
                  type="text"
                  value={dlNumber}
                  onChange={(e) => setDlNumber(e.target.value.toUpperCase())}
                  placeholder="MP-04-2022-0049182"
                  className="w-full rounded-2xl bg-white border border-slate-200 px-4 py-3.5 text-slate-900 font-bold outline-none uppercase tracking-wide focus:border-[#00E676] shadow-sm"
                />
              </div>

              <div className="p-3.5 bg-emerald-50 border border-emerald-100 rounded-2xl flex items-start gap-3">
                <Shield className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                <p className="text-xs text-emerald-800 font-medium leading-relaxed">
                  Please ensure your vehicle and license details match your official documents.
                </p>
              </div>
            </div>
          </div>
        )}

        {step === 3 && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-black text-slate-900">Bank Details</h2>
              <p className="text-slate-500 text-sm mt-1">Your weekly payouts will be deposited to this account.</p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Account Holder Name
                </label>
                <input
                  type="text"
                  value={bankHolder}
                  onChange={(e) => setBankHolder(e.target.value)}
                  placeholder="Account holder name"
                  className="w-full rounded-2xl bg-white border border-slate-200 px-4 py-3.5 text-slate-900 font-bold outline-none focus:border-[#00E676] shadow-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  Bank Account Number
                </label>
                <input
                  type="text"
                  value={bankAccount}
                  onChange={(e) => setBankAccount(e.target.value)}
                  placeholder="e.g. 918237461928"
                  className="w-full rounded-2xl bg-white border border-slate-200 px-4 py-3.5 text-slate-900 font-bold outline-none focus:border-[#00E676] shadow-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
                  IFSC Code
                </label>
                <input
                  type="text"
                  value={bankIfsc}
                  onChange={(e) => setBankIfsc(e.target.value.toUpperCase())}
                  placeholder="e.g. SBIN0001234"
                  className="w-full rounded-2xl bg-white border border-slate-200 px-4 py-3.5 text-slate-900 font-bold outline-none uppercase focus:border-[#00E676] shadow-sm"
                />
              </div>

              <div className="p-4 bg-slate-100 rounded-2xl flex items-center gap-3">
                <Lock className="w-5 h-5 text-slate-500 shrink-0" />
                <p className="text-xs text-slate-600 font-medium">
                  Your bank details are encrypted and securely used solely for automatic rider payouts.
                </p>
              </div>
            </div>
          </div>
        )}

        {step === 4 && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-black text-slate-900">Upload Documents</h2>
              <p className="text-slate-500 text-sm mt-1">Upload photos or documents to verify your profile.</p>
            </div>

            <div className="space-y-3.5">
              {[
                { type: 'idProof' as DocumentType, label: 'Aadhar / ID Proof', status: profile.documents.idProof },
                { type: 'drivingLicense' as DocumentType, label: 'Driving License', status: profile.documents.drivingLicense },
                { type: 'vehicleRc' as DocumentType, label: 'Vehicle RC', status: profile.documents.vehicleRc },
              ].map((doc) => (
                <div
                  key={doc.type}
                  className="p-4 bg-white rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700">
                      <FileText className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm">{doc.label}</h4>
                      <span
                        className={`text-xs font-semibold ${
                          doc.status === 'verified'
                            ? 'text-emerald-600'
                            : doc.status === 'pending'
                            ? 'text-amber-600'
                            : 'text-red-500'
                        }`}
                      >
                        {doc.status === 'verified'
                          ? '✓ Verified'
                          : doc.status === 'pending'
                          ? '⏳ Pending Review'
                          : 'Not Uploaded'}
                      </span>
                    </div>
                  </div>

                  <button
                    type="button"
                    disabled={uploadingDoc === doc.type}
                    onClick={() => handleDocUpload(doc.type)}
                    className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-xl text-xs font-bold transition flex items-center gap-1.5"
                  >
                    {uploadingDoc === doc.type ? (
                      <span className="w-4 h-4 border-2 border-slate-600 border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <>
                        <Upload className="w-3.5 h-3.5" />
                        {doc.status === 'missing' ? 'Upload' : 'Update'}
                      </>
                    )}
                  </button>
                </div>
              ))}

              <div className="p-3.5 bg-amber-50 border border-amber-200/80 rounded-2xl flex items-center gap-3">
                <Clock className="w-5 h-5 text-amber-600 shrink-0" />
                <p className="text-xs text-amber-800 font-medium">
                  Document verification usually completes within 24 hours of submission.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Footer Actions */}
        <div className="mt-8 pt-4">
          {step === 1 && (
            <PrimaryButton
              label="Next: Vehicle Details"
              onClick={handleStep1Submit}
              disabled={!name.trim() || !city.trim()}
              leading={<ArrowRight className="w-5 h-5" />}
            />
          )}

          {step === 2 && (
            <PrimaryButton
              label="Next: Bank Details"
              onClick={handleStep2Submit}
              disabled={!regNumber.trim() || !dlNumber.trim()}
              leading={<ArrowRight className="w-5 h-5" />}
            />
          )}

          {step === 3 && (
            <PrimaryButton
              label="Next: Upload Documents"
              onClick={handleStep3Submit}
              disabled={!bankHolder.trim() || !bankAccount.trim() || !bankIfsc.trim()}
              leading={<ArrowRight className="w-5 h-5" />}
            />
          )}

          {step === 4 && (
            <PrimaryButton
              label="Finish & Submit Application"
              onClick={handleFinish}
              leading={<CheckCircle className="w-5 h-5" />}
            />
          )}
        </div>
      </div>

      {/* City Picker Modal */}
      {showCityPicker && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl p-6 shadow-2xl max-h-[80vh] flex flex-col animate-in slide-in-from-bottom-5">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="font-black text-slate-900 text-lg">Select Operating City</h3>
              <button
                onClick={() => setShowCityPicker(false)}
                className="text-sm font-bold text-slate-500 hover:text-slate-800"
              >
                Close
              </button>
            </div>

            <div className="mt-4 flex items-center bg-slate-100 rounded-2xl px-4 py-2.5">
              <Search className="w-4 h-4 text-slate-400 mr-2" />
              <input
                type="text"
                placeholder="Search city..."
                value={citySearch}
                onChange={(e) => setCitySearch(e.target.value)}
                className="w-full bg-transparent text-sm font-semibold outline-none text-slate-800"
              />
            </div>

            <div className="mt-4 overflow-y-auto space-y-1 flex-1">
              {filteredCities.map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => {
                    setCity(c);
                    setShowCityPicker(false);
                  }}
                  className={`w-full p-3.5 rounded-xl font-bold text-sm text-left flex items-center justify-between transition ${
                    city === c
                      ? 'bg-emerald-50 text-[#00E676]'
                      : 'hover:bg-slate-100 text-slate-800'
                  }`}
                >
                  <span>{c}</span>
                  {city === c && <Check className="w-4 h-4 text-[#00E676]" />}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
