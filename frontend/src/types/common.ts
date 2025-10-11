export interface Message {
  message: string;
}

export interface PaginatedResponse<T> {
  total: number;
  page: number;
  size: number;
  items: T[];
}

export interface ApiResponse<T = any> {
  data: T;
  message?: string;
  success: boolean;
}

export interface ErrorResponse {
  detail: string;
  error_code?: string;
}

export interface PaginationParams {
  page?: number;
  size?: number;
  skip?: number;
  limit?: number;
}

export interface SortParams {
  sort_by?: string;
  sort_order?: 'asc' | 'desc';
}

export interface FilterParams {
  search?: string;
  filters?: Record<string, any>;
}
