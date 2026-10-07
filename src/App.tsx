import React, { useState } from 'react';
import { useApp } from './context/AppContext';
import { AuthScreen } from './screens/AuthScreen';
import { OnboardingScreen } from './screens/OnboardingScreen';
import { ApplicationReviewScreen } from './screens/ApplicationReviewScreen';
import { HomeTab } from './screens/HomeTab';
import { OrdersTab } from './screens/OrdersTab';
import { EarningsTab } from './screens/EarningsTab';
import { ProfileTab } from './screens/ProfileTab';
import { BottomNav } from './components/BottomNav';
import { DeliveryFlowModal } from './screens/DeliveryFlowModal';

export const App: React.FC = () => {
  const {
    isLoggedIn,
    isOnboardingComplete,
    verification,
    activeOrders,
  } = useApp();

  const [activeTab, setActiveTab] = useState<number>(0);

  // 1. Not logged in -> Auth flow
  if (!isLoggedIn) {
    return <AuthScreen />;
  }

  // 2. Onboarding not complete -> Onboarding wizard
  if (!isOnboardingComplete) {
    return <OnboardingScreen />;
  }

  // 3. Application under review (pending or inReview or rejected)
  if (verification !== 'verified') {
    return <ApplicationReviewScreen />;
  }

  // 4. Verified rider -> Main App Shell
  return (
    <div className="min-h-screen bg-slate-100 flex justify-center text-slate-900">
      <main className="w-full max-w-md bg-white min-h-screen relative shadow-2xl flex flex-col">
        {activeTab === 0 && <HomeTab />}
        {activeTab === 1 && <OrdersTab />}
        {activeTab === 2 && <EarningsTab />}
        {activeTab === 3 && <ProfileTab onNavigateToTab={setActiveTab} />}

        {/* Global Bottom Navigation */}
        <BottomNav
          currentIndex={activeTab}
          onSelect={setActiveTab}
          activeOrdersCount={activeOrders.length}
        />

        {/* Live Delivery Flow Modal / Full Screen Runner */}
        <DeliveryFlowModal />
      </main>
    </div>
  );
};
