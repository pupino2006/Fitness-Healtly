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
    backgroundColor: '#000000',
  },
  plugins: {
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#000000',
    },
  },
};

export default config;
