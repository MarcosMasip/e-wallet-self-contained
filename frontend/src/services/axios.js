import axios from "axios";

// Determine API base URL priority: build-time env -> runtime injected global -> fallback default
const baseURL = process.env.REACT_APP_API_BASE_URL || (typeof window !== 'undefined' && window._API_BASE_URL) || "http://localhost:8080/api/v1";

const instance = axios.create({ baseURL });
instance.defaults.headers.common["Content-Type"] = "application/json";

// LocalStorage key (duplicated to avoid circular dependency with AuthService)
const STORAGE_KEY = 'user';

// Request interceptor: attach Authorization header if token present
instance.interceptors.request.use(
	(config) => {
		try {
			const raw = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null;
			if (raw) {
				const parsed = JSON.parse(raw);
				if (parsed && parsed.token) {
					// Only set header if not already explicitly provided
					if (!config.headers.Authorization) {
						config.headers.Authorization = `Bearer ${parsed.token}`;
					}
				}
			}
		} catch (e) {
			// Swallow JSON errors silently
		}
		return config;
	},
	(error) => Promise.reject(error)
);

// Response interceptor: on 401/403 clear auth and redirect to login
instance.interceptors.response.use(
	(response) => response,
	(error) => {
		if (error?.response && [401, 403].includes(error.response.status)) {
			try {
				const currentPath = window.location.pathname;
				// Avoid infinite redirect loop if already on login or signup
				if (typeof window !== 'undefined' && !['/login', '/signup'].includes(currentPath)) {
					localStorage.removeItem(STORAGE_KEY);
					window.location.replace('/login');
				} else {
					localStorage.removeItem(STORAGE_KEY);
				}
			} catch (e) {
				// ignore
			}
		}
		return Promise.reject(error);
	}
);

export default instance;
