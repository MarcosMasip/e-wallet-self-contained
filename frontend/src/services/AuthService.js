import axios from './axios';

// Key used in localStorage
const STORAGE_KEY = 'user';

const login = (body) => {
  const url = '/auth/login';
  return axios.post(url, body).then((response) => {
    // Backend returns JwtResponse directly (no nested data wrapper)
    const payload = response.data;
    if (!payload || !payload.token) {
      throw new Error('Malformed login response');
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    return payload;
  });
};

const signup = (body) => {
  const url = '/auth/signup';
  return axios.post(url, body).then((response) => response.data);
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

const AuthService = { login, signup, logout, getCurrentUser };

export default AuthService;
