import axios from './axios';

// Key used in localStorage
const STORAGE_KEY = 'user';

const login = (body) => {
  const url = '/auth/login';
  return axios.post(url, body)
    .then((response) => {
      const payload = response.data;
      if (!payload || !payload.token) {
        throw new Error('Malformed login response');
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
      return payload;
    })
    .catch((e) => {
      if (!e.response) {
        // Network layer issue
        throw new Error('Network Error: Backend unreachable. Verify backend container is healthy at /api/v1/health.');
      }
      throw e;
    });
};

const signup = (body) => {
  const url = '/auth/signup';
  return axios.post(url, body)
    .then((response) => response.data)
    .catch((e) => {
      if (!e.response) {
        throw new Error('Network Error: Backend unreachable. Check backend health /api/v1/health.');
      }
      throw e;
    });
};

const logout = () => {
  localStorage.removeItem(STORAGE_KEY);
};

const getCurrentUser = () => {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (e) {
    // Corrupted storage entry; remove it to prevent render crashes
    localStorage.removeItem(STORAGE_KEY);
    return null;
  }
};

// Merge existing stored user with fresh me() response (keep token)
const mergeUser = (stored, fresh) => {
  if (!stored) return fresh;
  return { ...stored, ...fresh, token: stored.token };
};

// Fetch current authenticated user profile
const me = () => {
  return axios.get('/auth/me').then((response) => {
    const fresh = response.data;
    if (!fresh) return null;
    const existing = getCurrentUser();
    const merged = mergeUser(existing, fresh);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
    return merged;
  });
};

const AuthService = { login, signup, logout, getCurrentUser, me };

export default AuthService;
