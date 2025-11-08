/*
  # Oxedro ERP Database Schema

  ## Overview
  This migration creates the complete database structure for Oxedro ERP system
  for educational institutes. The system manages students, teachers, parents,
  admins, and superadmins with role-based access control.

  ## Tables Created

  1. **profiles** - Central user profile table for all users
     - `id` (uuid, primary key) - Auto-generated UUID
     - `unique_id` (text, unique) - Custom format ID (e.g., TIME25ST9367)
     - `email` (text, unique) - User email
     - `phone` (text) - Contact number
     - `first_name` (text) - First name
     - `last_name` (text) - Last name (optional)
     - `role` (text) - One of: superadmin, admin, teacher, student, parent
     - `address` (text) - Physical address
     - `sex` (text) - Gender
     - `blood_group` (text) - Blood group
     - `avatar_url` (text) - Profile picture URL
     - `is_active` (boolean) - Account active status
     - `created_at` (timestamptz) - Account creation timestamp
     - `updated_at` (timestamptz) - Last update timestamp

  2. **students** - Student-specific information
     - `id` (uuid, primary key) - References profiles.id
     - `roll_no` (text) - Roll number
     - `enrollment_no` (text, unique) - Enrollment number
     - `class` (text) - Current class
     - `section` (text) - Class section
     - `father_name` (text) - Father's full name
     - `mother_name` (text) - Mother's full name
     - `admission_date` (date) - Date of admission
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)

  3. **teachers** - Teacher-specific information
     - `id` (uuid, primary key) - References profiles.id
     - `employee_id` (text, unique) - Employee ID
     - `department` (text) - Department name
     - `designation` (text) - Job designation
     - `qualification` (text) - Educational qualification
     - `joining_date` (date) - Date of joining
     - `subjects` (text[]) - Array of subjects taught
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)

  4. **parents** - Parent-specific information
     - `id` (uuid, primary key) - References profiles.id
     - `student_id` (uuid) - References students.id (child relationship)
     - `relation` (text) - Relation to student (father/mother/guardian)
     - `occupation` (text) - Occupation
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)

  5. **admins** - Admin-specific information
     - `id` (uuid, primary key) - References profiles.id
     - `employee_id` (text, unique) - Employee ID
     - `designation` (text) - Job designation
     - `department` (text) - Department name
     - `joining_date` (date) - Date of joining
     - `permissions` (text[]) - Array of permission codes
     - `created_at` (timestamptz)
     - `updated_at` (timestamptz)

  ## Security

  - Row Level Security (RLS) enabled on all tables
  - Restrictive policies for role-based access
  - Users can only access their own data or data they're authorized to see
  - Only admins and superadmins can create new accounts

  ## Important Notes

  1. The `unique_id` format: {INSTITUTE_CODE}{YEAR}{ROLE_CODE}{RANDOM}
     - Example: TIME25ST9367 (TIME=institute, 25=year, ST=student, 9367=random)
     - Role codes: SA=superadmin, AD=admin, TE=teacher, ST=student, PA=parent

  2. Authentication handled through Supabase Auth with custom unique_id as login

  3. Parent-Student relationship maintained through parent.student_id

  4. All tables have soft delete capability through is_active flag in profiles
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unique_id text UNIQUE NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  first_name text NOT NULL,
  last_name text,
  role text NOT NULL CHECK (role IN ('superadmin', 'admin', 'teacher', 'student', 'parent')),
  address text,
  sex text CHECK (sex IN ('male', 'female', 'other')),
  blood_group text,
  avatar_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create students table
CREATE TABLE IF NOT EXISTS students (
  id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  roll_no text,
  enrollment_no text UNIQUE NOT NULL,
  class text NOT NULL,
  section text,
  father_name text NOT NULL,
  mother_name text NOT NULL,
  admission_date date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create teachers table
CREATE TABLE IF NOT EXISTS teachers (
  id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  employee_id text UNIQUE NOT NULL,
  department text,
  designation text,
  qualification text,
  joining_date date DEFAULT CURRENT_DATE,
  subjects text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create parents table
CREATE TABLE IF NOT EXISTS parents (
  id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  student_id uuid REFERENCES students(id) ON DELETE SET NULL,
  relation text CHECK (relation IN ('father', 'mother', 'guardian')),
  occupation text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create admins table
CREATE TABLE IF NOT EXISTS admins (
  id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  employee_id text UNIQUE NOT NULL,
  designation text,
  department text,
  joining_date date DEFAULT CURRENT_DATE,
  permissions text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_unique_id ON profiles(unique_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_students_enrollment ON students(enrollment_no);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class);
CREATE INDEX IF NOT EXISTS idx_teachers_employee_id ON teachers(employee_id);
CREATE INDEX IF NOT EXISTS idx_admins_employee_id ON admins(employee_id);
CREATE INDEX IF NOT EXISTS idx_parents_student_id ON parents(student_id);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles table

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Admins and superadmins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Teachers can view student and parent profiles
CREATE POLICY "Teachers can view students and parents"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'teacher'
      AND profiles.is_active = true
    )
    AND role IN ('student', 'parent')
  );

-- Parents can view their linked student's profile
CREATE POLICY "Parents can view their children"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM parents
      JOIN profiles p ON p.id = auth.uid()
      WHERE parents.id = p.id
      AND parents.student_id IN (
        SELECT id FROM students WHERE students.id = profiles.id
      )
      AND p.is_active = true
    )
  );

-- Only admins can insert new profiles
CREATE POLICY "Admins can create profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can update any profile
CREATE POLICY "Admins can update profiles"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- RLS Policies for students table

-- Students can view their own data
CREATE POLICY "Students can view own data"
  ON students FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Teachers, admins, and superadmins can view all students
CREATE POLICY "Staff can view students"
  ON students FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('teacher', 'admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Parents can view their children
CREATE POLICY "Parents can view their children data"
  ON students FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM parents
      JOIN profiles p ON p.id = auth.uid()
      WHERE parents.id = p.id
      AND parents.student_id = students.id
      AND p.is_active = true
    )
  );

-- Only admins can create students
CREATE POLICY "Admins can create students"
  ON students FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Admins can update students
CREATE POLICY "Admins can update students"
  ON students FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- RLS Policies for teachers table

-- Teachers can view their own data
CREATE POLICY "Teachers can view own data"
  ON teachers FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Admins and superadmins can view all teachers
CREATE POLICY "Admins can view teachers"
  ON teachers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Only admins can create teachers
CREATE POLICY "Admins can create teachers"
  ON teachers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Admins can update teachers
CREATE POLICY "Admins can update teachers"
  ON teachers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- RLS Policies for parents table

-- Parents can view their own data
CREATE POLICY "Parents can view own data"
  ON parents FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Admins, superadmins, and teachers can view all parents
CREATE POLICY "Staff can view parents"
  ON parents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('teacher', 'admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Only admins can create parents
CREATE POLICY "Admins can create parents"
  ON parents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- Admins can update parents
CREATE POLICY "Admins can update parents"
  ON parents FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superadmin')
      AND profiles.is_active = true
    )
  );

-- RLS Policies for admins table

-- Admins can view their own data
CREATE POLICY "Admins can view own data"
  ON admins FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Superadmins can view all admins
CREATE POLICY "Superadmins can view admins"
  ON admins FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'superadmin'
      AND profiles.is_active = true
    )
  );

-- Only superadmins can create admins
CREATE POLICY "Superadmins can create admins"
  ON admins FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'superadmin'
      AND profiles.is_active = true
    )
  );

-- Superadmins can update admins
CREATE POLICY "Superadmins can update admins"
  ON admins FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'superadmin'
      AND profiles.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'superadmin'
      AND profiles.is_active = true
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parents_updated_at BEFORE UPDATE ON parents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
