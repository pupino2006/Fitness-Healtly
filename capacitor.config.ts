import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.lucaripa.fitnesshealtly',
  appName: 'LR Training Pro',
  webDir: 'www',
  server: {
    androidScheme: 'https',
  },
  ios: {
    contentInset: 'automatic',
    preferredContentMode: 'mobile',
    backgroundColor: '#111827',
  },
  plugins: {
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#111827',
    },
  },
};

export default config;
