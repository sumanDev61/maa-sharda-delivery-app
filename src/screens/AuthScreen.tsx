import React, { useState } from 'react';
import { Bike, Phone, ArrowLeft, Lock, Eye, EyeOff, ShieldCheck, User, Mail } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { PrimaryButton } from '../components/PrimaryButton';
import { useToast } from '../components/Toast';
import { VehicleType } from '../types';

type AuthMode = 'password' | 'otp' | 'register';

export const AuthScreen: React.FC = () => {
  const { loginWithPassword, register, verifyOtp } = useApp();
  const { showToast } = useToast();

  const [mode, setMode] = useState<AuthMode>('password');

  // Password Login state
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  // OTP Login state
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [riderIdForOtp, setRiderIdForOtp] = useState('');
  const [otpSent, setOtpSent] = useState(false);

  // Registration state
  const [regName, setRegName] = useState('');
  const [regPhone, setRegPhone] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regVehicle, setRegVehicle] = useState<VehicleType>('bike');

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  // Password submit
  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier.trim()) {
      setErrorMsg('Please enter your Partner ID or Registered Mobile');
      return;
    }
    if (!password) {
      setErrorMsg('Please enter your password');
      return;
    }

    setErrorMsg('');
    setLoading(true);
    const res = await loginWithPassword(identifier, password);
    setLoading(false);

    if (res.ok) {
      showToast('Login successful! Welcome back.', 'success');
    } else {
      setErrorMsg(res.error || 'Authentication failed. Please verify credentials.');
    }
  };

  // OTP flow
  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone.length !== 10) {
      setErrorMsg('Please enter a valid 10-digit mobile number');
      return;
    }
    setErrorMsg('');
    setLoading(true);

    const generatedRiderId = `MS-${cleanPhone.slice(-4)}`;
    setRiderIdForOtp(generatedRiderId);
    setLoading(false);
    setOtpSent(true);
    showToast('6-digit OTP sent to +91 ' + cleanPhone, 'info');
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (otp.length !== 6) {
      setErrorMsg('Please enter the 6-digit verification code');
      return;
    }
    setErrorMsg('');
    setLoading(true);
    const res = await verifyOtp(phone, riderIdForOtp, otp);
    setLoading(false);
    if (res.ok) {
      showToast('Phone verified! Logged in successfully.', 'success');
    } else {
      setErrorMsg(res.error || 'Invalid OTP code. Please retry.');
    }
  };

  // Registration submit
  const handleRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!regName.trim()) {
      setErrorMsg('Please enter your Full Name');
      return;
    }
    const cleanPhone = regPhone.replace(/\D/g, '');
    if (cleanPhone.length !== 10) {
      setErrorMsg('Please enter a valid 10-digit mobile number');
      return;
    }
    if (!regEmail.trim() || !regEmail.includes('@')) {
      setErrorMsg('Please enter a valid email address');
      return;
    }
    if (!regPassword || regPassword.length < 4) {
      setErrorMsg('Password must be at least 4 characters');
      return;
    }

    setErrorMsg('');
    setLoading(true);
    const res = await register({
      name: regName.trim(),
      phone: cleanPhone,
      email: regEmail.trim(),
      password: regPassword,
      vehicleType: regVehicle,
    });
    setLoading(false);

    if (res.ok) {
      showToast('Registration successful! Please login with your password.', 'success');
      setIdentifier(cleanPhone);
      setPassword(regPassword);
      setMode('password');
    } else {
      setErrorMsg(res.error || 'Registration failed');
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 flex justify-center text-slate-900">
      <main className="w-full max-w-md bg-white min-h-screen flex flex-col justify-between shadow-2xl relative">
        {/* Sleek Compact Header */}
        <div className="bg-slate-950 text-white px-5 pt-7 pb-6 rounded-b-3xl shadow-lg border-b border-slate-800">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-500 to-[#00E676] flex items-center justify-center text-slate-950 shadow-md">
                <Bike className="w-5 h-5" />
              </div>
              <div>
                <h1 className="text-base font-extrabold tracking-tight text-white leading-tight">
                  Maa Sharda Go
                </h1>
                <p className="text-[11px] font-semibold text-emerald-400">Rider Partner Portal</p>
              </div>
            </div>

            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-800 text-slate-300 border border-slate-700">
              v2.4
            </span>
          </div>

          {/* Mode Switcher */}
          <div className="mt-5 grid grid-cols-3 gap-1 p-1 bg-slate-900 rounded-xl border border-slate-800 text-xs">
            <button
              type="button"
              onClick={() => {
                setMode('password');
                setErrorMsg('');
              }}
              className={`py-1.5 rounded-lg font-bold transition text-[11px] ${
                mode === 'password'
                  ? 'bg-[#00E676] text-slate-950 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Password
            </button>
            <button
              type="button"
              onClick={() => {
                setMode('otp');
                setErrorMsg('');
              }}
              className={`py-1.5 rounded-lg font-bold transition text-[11px] ${
                mode === 'otp'
                  ? 'bg-[#00E676] text-slate-950 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Mobile OTP
            </button>
            <button
              type="button"
              onClick={() => {
                setMode('register');
                setErrorMsg('');
              }}
              className={`py-1.5 rounded-lg font-bold transition text-[11px] ${
                mode === 'register'
                  ? 'bg-[#00E676] text-slate-950 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Register
            </button>
          </div>
        </div>

        {/* Form Body */}
        <div className="p-5 flex-1 flex flex-col justify-between">
          {/* Error Message banner */}
          {errorMsg && (
            <div className="mb-4 p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-semibold flex items-center justify-between animate-shake">
              <span>{errorMsg}</span>
              <button onClick={() => setErrorMsg('')} className="text-rose-500 font-bold ml-2">
                ✕
              </button>
            </div>
          )}

          {/* MODE 1: USER ID & PASSWORD LOGIN */}
          {mode === 'password' && (
            <form onSubmit={handlePasswordSubmit} className="flex-1 flex flex-col justify-between">
              <div className="space-y-4">
                <div>
                  <h2 className="text-lg font-extrabold text-slate-900 tracking-tight">Partner Sign In</h2>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Enter your Registered Mobile or Rider ID and Password to start your shift.
                  </p>
                </div>

                <div className="space-y-3 pt-1">
                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      User ID / Mobile Number
                    </label>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white focus-within:ring-2 focus-within:ring-emerald-500/20 px-3 py-2.5 transition">
                      <User className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                      <input
                        type="text"
                        value={identifier}
                        onChange={(e) => setIdentifier(e.target.value)}
                        placeholder="e.g. 9876543210 or MS-4921"
                        className="w-full bg-transparent text-xs text-slate-900 font-semibold outline-none placeholder:text-slate-400"
                        autoFocus
                      />
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500">
                        Password
                      </label>
                      <button
                        type="button"
                        onClick={() => {
                          showToast('Contact dispatch admin or use Mobile OTP to reset.', 'info');
                        }}
                        className="text-[11px] font-bold text-emerald-600 hover:underline"
                      >
                        Forgot?
                      </button>
                    </div>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white focus-within:ring-2 focus-within:ring-emerald-500/20 px-3 py-2.5 transition">
                      <Lock className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                      <input
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="Enter password"
                        className="w-full bg-transparent text-xs text-slate-900 font-semibold outline-none placeholder:text-slate-400"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="text-slate-400 hover:text-slate-600 ml-1 p-0.5"
                      >
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>
                </div>

                <div className="p-2.5 rounded-xl bg-emerald-50/70 border border-emerald-100 flex items-start gap-2 text-[11px] text-emerald-900">
                  <ShieldCheck className="w-4 h-4 text-[#00E676] shrink-0 mt-0.5" />
                  <span>
                    Secured by Maa Sharda API. No access without authorized partner login.
                  </span>
                </div>
              </div>

              <div className="mt-6 space-y-2.5">
                <PrimaryButton
                  label="Sign In with Password"
                  type="submit"
                  isLoading={loading}
                  disabled={!identifier.trim() || !password}
                />
                <button
                  type="button"
                  onClick={() => setMode('register')}
                  className="w-full py-1.5 text-center text-xs font-bold text-slate-500 hover:text-slate-800"
                >
                  New delivery partner? <span className="text-emerald-600">Register account</span>
                </button>
              </div>
            </form>
          )}

          {/* MODE 2: MOBILE OTP LOGIN */}
          {mode === 'otp' && (
            <div className="flex-1 flex flex-col justify-between">
              {!otpSent ? (
                <form onSubmit={handleRequestOtp} className="space-y-4">
                  <div>
                    <h2 className="text-lg font-extrabold text-slate-900 tracking-tight">Mobile OTP Verification</h2>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Receive an SMS verification code on your registered mobile number.
                    </p>
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      10-Digit Mobile Number
                    </label>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white focus-within:ring-2 focus-within:ring-emerald-500/20 px-3 py-2.5 transition">
                      <span className="text-xs font-bold text-slate-600 pr-2 border-r border-slate-200">
                        +91
                      </span>
                      <input
                        type="tel"
                        maxLength={10}
                        value={phone}
                        onChange={(e) => setPhone(e.target.value.replace(/\D/g, ''))}
                        placeholder="9876543210"
                        className="w-full bg-transparent text-xs text-slate-900 font-bold outline-none pl-2.5 tracking-wider placeholder:tracking-normal placeholder:font-normal placeholder:text-slate-400"
                        autoFocus
                      />
                      <Phone className="w-4 h-4 text-slate-400 shrink-0" />
                    </div>
                  </div>

                  <PrimaryButton
                    label="Send OTP Code"
                    type="submit"
                    isLoading={loading}
                    disabled={phone.replace(/\D/g, '').length !== 10}
                  />
                </form>
              ) : (
                <form onSubmit={handleVerifyOtp} className="flex-1 flex flex-col justify-between">
                  <div className="space-y-4">
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => setOtpSent(false)}
                        className="p-1 rounded-lg hover:bg-slate-100 text-slate-600"
                      >
                        <ArrowLeft className="w-4 h-4" />
                      </button>
                      <div>
                        <h2 className="text-lg font-extrabold text-slate-900 tracking-tight">Enter 6-Digit OTP</h2>
                        <p className="text-xs text-slate-500">Sent to +91 {phone}</p>
                      </div>
                    </div>

                    <div>
                      <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white focus-within:ring-2 focus-within:ring-emerald-500/20 px-3 py-2.5 transition">
                        <Lock className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                        <input
                          type="text"
                          maxLength={6}
                          value={otp}
                          onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                          placeholder="••••••"
                          className="w-full bg-transparent text-base text-slate-900 font-extrabold tracking-widest outline-none placeholder:text-slate-300"
                          autoFocus
                        />
                      </div>
                      <div className="flex items-center justify-between mt-2 text-[11px] text-slate-400">
                        <span>Didn't receive SMS?</span>
                        <button
                          type="button"
                          onClick={() => {
                            showToast('New code sent via SMS: 123456', 'info');
                          }}
                          className="font-bold text-emerald-600 hover:underline"
                        >
                          Resend Code
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="mt-6">
                    <PrimaryButton
                      label="Verify & Sign In"
                      type="submit"
                      isLoading={loading}
                      disabled={otp.length !== 6}
                    />
                  </div>
                </form>
              )}
            </div>
          )}

          {/* MODE 3: REGISTRATION */}
          {mode === 'register' && (
            <form onSubmit={handleRegisterSubmit} className="flex-1 flex flex-col justify-between">
              <div className="space-y-3">
                <div>
                  <h2 className="text-lg font-extrabold text-slate-900 tracking-tight">Join As Delivery Partner</h2>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Register with your details to receive orders in Bhopal.
                  </p>
                </div>

                <div className="space-y-2.5 pt-1">
                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Full Name
                    </label>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white px-3 py-2 transition">
                      <User className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                      <input
                        type="text"
                        value={regName}
                        onChange={(e) => setRegName(e.target.value)}
                        placeholder="e.g. Sumit Kumar"
                        className="w-full bg-transparent text-xs text-slate-900 font-semibold outline-none placeholder:text-slate-400"
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Mobile Number (+91)
                    </label>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white px-3 py-2 transition">
                      <Phone className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                      <input
                        type="tel"
                        maxLength={10}
                        value={regPhone}
                        onChange={(e) => setRegPhone(e.target.value.replace(/\D/g, ''))}
                        placeholder="10-digit mobile number"
                        className="w-full bg-transparent text-xs text-slate-900 font-semibold outline-none placeholder:text-slate-400"
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Email Address
                    </label>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white px-3 py-2 transition">
                      <Mail className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                      <input
                        type="email"
                        value={regEmail}
                        onChange={(e) => setRegEmail(e.target.value)}
                        placeholder="partner@example.com"
                        className="w-full bg-transparent text-xs text-slate-900 font-semibold outline-none placeholder:text-slate-400"
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Create Password
                    </label>
                    <div className="flex items-center rounded-xl bg-slate-50 border border-slate-200 focus-within:border-[#00E676] focus-within:bg-white px-3 py-2 transition">
                      <Lock className="w-4 h-4 text-slate-400 mr-2 shrink-0" />
                      <input
                        type="password"
                        value={regPassword}
                        onChange={(e) => setRegPassword(e.target.value)}
                        placeholder="Min 4 characters"
                        className="w-full bg-transparent text-xs text-slate-900 font-semibold outline-none placeholder:text-slate-400"
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Vehicle Type
                    </label>
                    <div className="grid grid-cols-3 gap-2">
                      {(['bike', 'scooter', 'cycle'] as VehicleType[]).map((vt) => (
                        <button
                          key={vt}
                          type="button"
                          onClick={() => setRegVehicle(vt)}
                          className={`py-1.5 rounded-xl border text-xs font-bold capitalize transition ${
                            regVehicle === vt
                              ? 'bg-emerald-50 border-[#00E676] text-emerald-900'
                              : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100'
                          }`}
                        >
                          {vt}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-5 space-y-2">
                <PrimaryButton
                  label="Create Partner Account"
                  type="submit"
                  isLoading={loading}
                />
                <button
                  type="button"
                  onClick={() => setMode('password')}
                  className="w-full py-1 text-center text-xs font-bold text-slate-500 hover:text-slate-800"
                >
                  Already have an account? <span className="text-emerald-600">Sign in</span>
                </button>
              </div>
            </form>
          )}

          {/* Footer note */}
          <div className="pt-4 border-t border-slate-100 text-center text-[10px] text-slate-400">
            Maa Sharda Go Delivery Network • Protected & Encrypted
          </div>
        </div>
      </main>
    </div>
  );
};
