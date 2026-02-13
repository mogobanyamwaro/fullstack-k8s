-- Create the todo_user and todo_db if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'todo_user') THEN
        CREATE USER todo_user WITH PASSWORD 'todo_password';
    END IF;
END
$$;

-- Create database (this will be run by postgres user)
SELECT 'CREATE DATABASE todo_db OWNER todo_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'todo_db')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE todo_db TO todo_user;

-- Connect to todo_db and grant schema privileges
\c todo_db
GRANT ALL ON SCHEMA public TO todo_user;
