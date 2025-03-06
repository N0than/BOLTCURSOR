import { createClient } from '@supabase/supabase-js';
import type { Show, User, Prediction } from '../types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY environment variables are required');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Fonction pour se connecter
export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  if (error) throw error;
  return data;
}

// Fonction pour s'inscrire
export async function signUp(email: string, password: string) {
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        username: email.split('@')[0]
      }
    }
  });
  if (authError) throw authError;

  // Create user profile after successful signup
  if (authData.user) {
    const username = email.split('@')[0];
    const { data: profileData, error: profileError } = await supabase
      .from('users')
      .insert([{
        id: authData.user.id,
        username,
        email,
        avatar: `https://api.dicebear.com/7.x/initials/svg?seed=${username}`,
        score: 0,
        accuracy: 0,
        predictions_count: 0,
        is_online: true
      }])
      .select()
      .single();

    if (profileError && profileError.code !== '23505') { // Ignore unique constraint violations
      throw profileError;
    }
  }

  return authData;
}

// Fonction pour se déconnecter
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

// Fonction pour récupérer l'utilisateur courant
export async function getCurrentUser(): Promise<User | null> {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session?.user) {
    return null;
  }

  try {
    // Try to get existing profile
    const { data: existingProfile, error: fetchError } = await supabase
      .from('users')
      .select('*')
      .eq('id', session.user.id)
      .single();

    if (fetchError) {
      if (fetchError.code === 'PGRST116') {
        // Profile doesn't exist, create it
        const username = session.user.user_metadata.username || session.user.email?.split('@')[0] || 'user';
        const { data: newProfile, error: createError } = await supabase
          .from('users')
          .insert([{
            id: session.user.id,
            username,
            email: session.user.email,
            avatar: `https://api.dicebear.com/7.x/initials/svg?seed=${username}`,
            score: 0,
            accuracy: 0,
            predictions_count: 0,
            is_online: true
          }])
          .select()
          .single();

        if (createError) {
          if (createError.code === '23505') {
            // If there's a duplicate key error, try to fetch the profile again
            const { data: retryProfile } = await supabase
              .from('users')
              .select('*')
              .eq('id', session.user.id)
              .single();
              
            if (retryProfile) {
              return {
                ...retryProfile,
                email: session.user.email
              };
            }
          }
          throw createError;
        }
        return {
          ...newProfile,
          email: session.user.email
        };
      } else {
        throw fetchError;
      }
    }

    // Ensure email is available from session if not in profile
    return {
      ...existingProfile,
      email: existingProfile.email || session.user.email
    };
  } catch (error) {
    console.error("Error in getCurrentUser:", error);
    
    // Fallback to basic user info from session
    return {
      id: session.user.id,
      username: session.user.user_metadata.username || session.user.email?.split('@')[0] || 'user',
      email: session.user.email || '',
      avatar: `https://api.dicebear.com/7.x/initials/svg?seed=${session.user.email?.split('@')[0] || 'user'}`,
      score: 0,
      accuracy: 0,
      predictions: 0,
      isOnline: true
    };
  }
}

// Fonction pour récupérer tous les utilisateurs
export async function getUsers(): Promise<User[]> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .order('score', { ascending: false });

  if (error) throw error;
  return data;
}

// Fonction pour mettre à jour le profil utilisateur
export async function updateUserProfile(userId: string, updates: Partial<User>) {
  // Filter out properties that might not exist in the database schema
  const { email: newEmail, ...dbUpdates } = updates;
  
  const { data, error } = await supabase
    .from('users')
    .update(dbUpdates)
    .eq('id', userId)
    .select()
    .single();

  if (error) throw error;
  
  // If email is being updated, update it in auth
  if (newEmail) {
    await updateUserEmail(newEmail);
  }
  
  return data;
}

// Fonction pour mettre à jour l'email
export async function updateUserEmail(newEmail: string) {
  // Check if email is actually different
  const { data: { session } } = await supabase.auth.getSession();
  if (session?.user?.email === newEmail) {
    return { user: session.user };
  }

  // Check rate limit first
  try {
    const { data: isAllowed, error: rateLimitError } = await supabase
      .rpc('check_email_update_rate_limit', { p_user_id: session.user.id });
    
    if (rateLimitError || !isAllowed) {
      throw new Error('Veuillez patienter 60 secondes entre chaque tentative de modification d\'email');
    }
  } catch (error) {
    if (error.message.includes('patienter')) {
      throw error;
    }
    console.error('Rate limit check error:', error);
  }

  const { data, error } = await supabase.auth.updateUser({
    email: newEmail
  });

  if (error) {
    if (error.status === 429) {
      throw new Error('Veuillez patienter 60 secondes entre chaque tentative de modification d\'email');
    }
    throw error;
  }
  return data;
}

// Fonction pour mettre à jour le mot de passe
export async function updateUserPassword(newPassword: string) {
  const { data, error } = await supabase.auth.updateUser({
    password: newPassword
  });

  if (error) throw error;
  return data;
}

// Fonction pour récupérer les shows
export async function getShows() {
  const { data, error } = await supabase
    .from('shows')
    .select('*')
    .order('datetime', { ascending: true });

  if (error) {
    console.error("Error fetching shows:", error);
    throw error;
  }
  return data as Show[];
}

// Fonction pour créer un show
export async function createShow(show: Omit<Show, 'id' | 'createdAt' | 'updatedAt'>) {
  // Ensure actual_audience is properly typed as number or null
  if (!show.title || !show.channel || !show.datetime || !show.description || !show.genre || !show.imageUrl) {
    throw new Error('Tous les champs sont requis');
  }

  const showData = {
    ...show,
    actual_audience: show.actual_audience ? Number(show.actual_audience) : null
  };

  const { data, error } = await supabase
    .from('shows')
    .insert([showData])
    .select()
    .single();

  if (error) {
    if (error.code === '42501') {
      throw new Error('Vous devez être administrateur pour effectuer cette action');
    }
    console.error("Error creating show:", error);
    throw error;
  }
  return data as Show;
}

// Fonction pour mettre à jour un show
export async function updateShow(id: string, show: Partial<Show>) {
  // Ensure actual_audience is properly typed as number or null
  if (!show.title || !show.channel || !show.datetime || !show.description || !show.genre || !show.imageUrl) {
    throw new Error('Tous les champs sont requis');
  }

  const showData = {
    ...show,
    actual_audience: show.actual_audience ? Number(show.actual_audience) : null
  };

  const { data, error } = await supabase
    .from('shows')
    .update(showData)
    .eq('id', id)
    .select();

  if (error) {
    if (error.code === '42501') {
      throw new Error('Vous devez être administrateur pour effectuer cette action');
    }
    console.error("Error updating show:", error);
    throw error;
  }
  return data[0] as Show;
}

// Fonction pour supprimer un show
export async function deleteShow(id: string) {
  const { error } = await supabase
    .from('shows')
    .delete()
    .eq('id', id);

  if (error) {
    if (error.code === '42501') {
      throw new Error('Vous devez être administrateur pour effectuer cette action');
    }
    console.error("Error deleting show:", error);
    throw error;
  }
}

// Fonction pour mettre à jour l'audience réelle
export async function updateActualAudience(showId: string, actualAudience: number): Promise<Show> {
  try {
    // Première étape : mettre à jour l'audience réelle dans la table shows
    const { data, error } = await supabase
      .from('shows')
      .update({ actual_audience: actualAudience })
      .eq('id', showId)
      .select();

    if (error) {
      console.error("Error updating actual audience:", error);
      console.error("Supabase error details:", error);
      throw error;
    }

    if (!data || data.length === 0) {
      console.warn("No show found with id:", showId);
      return null;
    }

    // Deuxième étape : mettre à jour les prédictions existantes avec la nouvelle audience réelle
    // et calculer la précision pour chaque prédiction
    const { error: predictionError } = await supabase.rpc(
      'update_predictions_with_actual_audience',
      {
        p_show_id: showId,
        p_actual_audience: actualAudience
      }
    );

    if (predictionError) {
      console.error("Error updating predictions with actual audience:", predictionError);
      // On continue même s'il y a une erreur pour au moins retourner le show mis à jour
    }

    return data[0] as Show;
  } catch (error) {
    console.error("Error updating actual audience:", error);
    throw error;
  }
}

// Fonction pour créer une prédiction
export async function createPrediction(showId: string, prediction: number): Promise<Prediction> {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    throw new Error('Vous devez être connecté pour faire une prédiction');
  }

  try {
    // Use the RPC function to create or update prediction
    const { data, error } = await supabase.rpc(
      'create_or_update_prediction',
      {
        p_show_id: showId,
        p_prediction: prediction
      }
    );
    
    if (error) {
      console.error("Error using RPC function:", error);
      throw error;
    }
    
    return data as Prediction;
  } catch (error) {
    console.error("Error creating prediction:", error);
    throw error;
  }
}

// Fonction pour récupérer une prédiction spécifique
export async function getUserPredictionForShow(showId: string): Promise<Prediction | null> {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    throw new Error('Vous devez être connecté pour voir vos pronostics');
  }

  try {
    // Use the RPC function to get the prediction
    const { data, error } = await supabase.rpc(
      'get_user_prediction_for_show',
      {
        p_show_id: showId
      }
    );

    if (error) {
      console.error("Error fetching prediction:", error);
      throw error;
    }
    
    if (!data || data.length === 0) {
      return null;
    }

    return data[0];
  } catch (error) {
    console.error("Error in getUserPredictionForShow:", error);
    throw error;
  }
}

// Fonction pour récupérer toutes les prédictions d'un utilisateur
export async function getUserPredictions(): Promise<(Prediction & { show: Show })[]> {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    console.warn('User not authenticated');
    return [];
  }

  try {
    // Use the RPC function to get all predictions
    const { data, error } = await supabase.rpc('get_user_predictions');

    if (error) {
      console.error("Error fetching predictions:", error);
      if (error.code === 'PGRST116') {
        // No data found, return empty array instead of throwing
        return [];
      }
      return [];
    }

    if (!data) {
      console.warn('No predictions found');
      return [];
    }

    // Filter out any invalid data
    const validData = data.filter(p => 
      p && 
      p.show_id && 
      p.show_title && 
      p.show_channel && 
      p.show_datetime
    );

    if (validData.length === 0) {
      console.warn('No valid predictions found after filtering');
      return [];
    }

    // Transform the data to match the expected format
    return validData.map(p => ({
      id: p.id,
      userId: p.user_id,
      showId: p.show_id,
      prediction: p.prediction,
      actual_audience: p.actual_audience,
      accuracy: p.accuracy,
      timestamp: p.created_at,
      show: {
        id: p.show_id,
        title: p.show_title,
        channel: p.show_channel,
        datetime: p.show_datetime,
        description: p.show_description,
        genre: p.show_genre,
        imageUrl: p.show_image_url,
        isNew: true // Default value since it's not in the function result
      }
    }));
  } catch (error) {
    console.error("Error in getUserPredictions:", error);
    return [];
  }
}

// Fonction pour s'abonner aux changements des prédictions
export function subscribeToPredictions(callback: (predictions: (Prediction & { show: Show })[]) => void) {
  const subscription = supabase
    .channel('predictions_channel')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'predictions'
      },
      async () => {
        try {
          const predictions = await getUserPredictions();
          if (!predictions || predictions.length === 0) {
            console.warn('No predictions received from subscription');
          }
          callback(predictions);
        } catch (error) {
          console.error("Error in prediction subscription:", error);
          console.warn('Returning empty array due to subscription error');
          callback([]);
        }
      }
    )
    .subscribe();

  return () => {
    subscription.unsubscribe();
  };
}

// Fonction pour s'abonner aux changements de la table shows
export function subscribeToShows(callback: (shows: Show[]) => void) {
  const subscription = supabase
    .channel('shows_channel')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'shows'
      },
      async () => {
        const shows = await getShows();
        callback(shows);
      }
    )
    .subscribe();

  return () => {
    subscription.unsubscribe();
  };
}

// Fonction pour s'abonner aux changements de la table users
export function subscribeToUsers(callback: (users: User[]) => void) {
  const subscription = supabase
    .channel('users_channel')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'users'
      },
      async () => {
        try {
          const users = await getUsers();
          callback(users);
        } catch (error) {
          console.error("Error in users subscription:", error);
          // Return empty array to avoid breaking the UI
          callback([]);
        }
      }
    )
    .subscribe();

  return () => {
    subscription.unsubscribe();
  };
}
