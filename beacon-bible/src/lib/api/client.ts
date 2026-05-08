import axios from 'axios';

// API.Bible client
export const apiBibleClient = axios.create({
  baseURL: 'https://api.scripture.api.bible/v1',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

apiBibleClient.interceptors.request.use((config) => {
  const apiKey = process.env.EXPO_PUBLIC_API_BIBLE_KEY ?? '';
  config.headers['api-key'] = apiKey;
  return config;
});

apiBibleClient.interceptors.response.use(
  (res) => res,
  (err) => {
    if (__DEV__) {
      console.error('[API.Bible]', err.response?.status, err.config?.url);
    }
    return Promise.reject(err);
  }
);

// Bible Brain (FCBH) client
export const bibleBrainClient = axios.create({
  baseURL: 'https://4.dbt.io/api',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

bibleBrainClient.interceptors.request.use((config) => {
  const apiKey = process.env.EXPO_PUBLIC_BIBLE_BRAIN_KEY ?? '';
  config.params = { ...config.params, key: apiKey, v: 4 };
  return config;
});

bibleBrainClient.interceptors.response.use(
  (res) => res,
  (err) => {
    if (__DEV__) {
      console.error('[BibleBrain]', err.response?.status, err.config?.url);
    }
    return Promise.reject(err);
  }
);
