import axios from "axios";

// Determine API base URL priority: build-time env -> runtime injected global -> fallback default
const baseURL = process.env.REACT_APP_API_BASE_URL || (typeof window !== 'undefined' && window._API_BASE_URL) || "http://localhost:8080/api/v1";

const instance = axios.create({ baseURL });
instance.defaults.headers.common["Content-Type"] = "application/json";

export default instance;
