// API client for Maa Sharda Go Delivery Partner backend
const BASE_URL =
  ((import.meta as any).env?.VITE_API_BASE_URL as string) ||
  'https://maa-sharda-backend-rylo.onrender.com';

export interface ApiResponse<T = any> {
  ok: boolean;
  status: number;
  data?: T;
  error?: string;
}

export class ApiClient {
  private static instance: ApiClient;
  private token: string | null = null;
  private riderId: string | null = null;

  private constructor() {
    this.token = localStorage.getItem('rider_token');
    this.riderId = localStorage.getItem('rider_id');
  }

  public static getInstance(): ApiClient {
    if (!ApiClient.instance) {
      ApiClient.instance = new ApiClient();
    }
    return ApiClient.instance;
  }

  public get baseUrl(): string {
    return BASE_URL;
  }

  public setAuthSession(token: string, riderId: string): void {
    this.token = token;
    this.riderId = riderId;
    localStorage.setItem('rider_token', token);
    localStorage.setItem('rider_id', riderId);
  }

  public clearSession(): void {
    this.token = null;
    this.riderId = null;
    localStorage.removeItem('rider_token');
    localStorage.removeItem('rider_id');
    localStorage.removeItem('rider_phone');
    localStorage.removeItem('rider_username');
    localStorage.removeItem('rider_profile');
    localStorage.removeItem('rider_verification');
    localStorage.removeItem('rider_trips');
    localStorage.removeItem('rider_history');
    localStorage.removeItem('rider_metrics');
    localStorage.removeItem('rider_online');
    localStorage.removeItem('rider_attendance');
  }

  public getRiderId(): string | null {
    return this.riderId;
  }

  public getToken(): string | null {
    return this.token;
  }

  private getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };
    if (this.riderId) {
      headers['x-rider-id'] = this.riderId;
    }
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  private async requestWithTimeout(url: string, options: RequestInit, timeoutMs = 12000): Promise<Response> {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(url, { ...options, signal: controller.signal });
      clearTimeout(id);
      return res;
    } catch (err) {
      clearTimeout(id);
      throw err;
    }
  }

  public async get<T = any>(endpoint: string): Promise<ApiResponse<T>> {
    try {
      const res = await this.requestWithTimeout(`${this.baseUrl}${endpoint}`, {
        method: 'GET',
        headers: this.getHeaders(),
      });
      const data = await res.json().catch(() => null);
      return { ok: res.ok, status: res.status, data, error: data?.message || data?.error };
    } catch (err: any) {
      const isTimeout = err?.name === 'AbortError';
      return {
        ok: false,
        status: 0,
        error: isTimeout ? 'Server timeout - server may be waking up' : err?.message || 'Network request failed',
      };
    }
  }

  public async post<T = any>(endpoint: string, body?: any): Promise<ApiResponse<T>> {
    try {
      const res = await this.requestWithTimeout(`${this.baseUrl}${endpoint}`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: body ? JSON.stringify(body) : undefined,
      });
      const data = await res.json().catch(() => null);
      return { ok: res.ok, status: res.status, data, error: data?.message || data?.error };
    } catch (err: any) {
      const isTimeout = err?.name === 'AbortError';
      return {
        ok: false,
        status: 0,
        error: isTimeout ? 'Server timeout - server may be waking up' : err?.message || 'Network request failed',
      };
    }
  }

  public async put<T = any>(endpoint: string, body?: any): Promise<ApiResponse<T>> {
    try {
      const res = await this.requestWithTimeout(`${this.baseUrl}${endpoint}`, {
        method: 'PUT',
        headers: this.getHeaders(),
        body: body ? JSON.stringify(body) : undefined,
      });
      const data = await res.json().catch(() => null);
      return { ok: res.ok, status: res.status, data, error: data?.message || data?.error };
    } catch (err: any) {
      const isTimeout = err?.name === 'AbortError';
      return {
        ok: false,
        status: 0,
        error: isTimeout ? 'Server timeout - server may be waking up' : err?.message || 'Network request failed',
      };
    }
  }
}

export const api = ApiClient.getInstance();
