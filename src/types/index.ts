export interface Show {
  id: string;
  title: string;
  channel: string;
  datetime: string;
  description: string;
  isNew: boolean;
  genre: string;
  imageUrl: string;
  actual_audience?: number;
  expectedAudience?: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface User {
  id: string;
  username: string;
  email?: string;
  avatar: string;
  score: number;
  predictions_count: number;
  accuracy: number;
  is_online: boolean;
  // Backward compatibility fields
  predictions?: number;
  isOnline?: boolean;
  currentPrediction?: {
    showId: string;
    prediction: number;
  };
  role?: 'user' | 'admin';
}

export interface Prediction {
  id: string;
  userId: string;
  showId: string;
  prediction: number;
  actual_audience?: number;
  accuracy?: number;
  timestamp: string;
  // Database field names
  user_id?: string;
  show_id?: string;
  created_at?: string;
}

export interface AdminStats {
  totalUsers: number;
  totalPredictions: number;
  averageAccuracy: number;
  activePredictions: number;
}
