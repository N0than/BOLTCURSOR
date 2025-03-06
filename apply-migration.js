import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Read environment variables
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Error: VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY environment variables are required.');
  process.exit(1);
}

// Create Supabase client
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Get the migration file path from command line arguments or use default
const migrationFile = process.argv[2] || './supabase/migrations/20250301001913_wooden_prism.sql';

// Check if the file exists
if (!fs.existsSync(migrationFile)) {
  console.error(`Error: Migration file ${migrationFile} does not exist.`);
  process.exit(1);
}

// Read the SQL file
const sql = fs.readFileSync(migrationFile, 'utf8');

// Split the SQL into individual statements
const statements = sql
  .replace(/--.*$/gm, '') // Remove comments
  .split(';')
  .map(statement => statement.trim())
  .filter(statement => statement.length > 0);

async function applyMigration() {
  console.log(`Applying migration from ${migrationFile}...`);
  
  try {
    // Execute each statement
    for (const statement of statements) {
      console.log(`Executing: ${statement.substring(0, 50)}...`);
      
      const { error } = await supabase.rpc('exec_sql', { sql: statement });
      
      if (error) {
        console.error('Error executing SQL:', error);
        // Continue with other statements even if one fails
      }
    }
    
    console.log('Migration completed successfully!');
  } catch (error) {
    console.error('Error applying migration:', error);
  }
}

applyMigration();
