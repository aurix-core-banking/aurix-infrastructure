-- AUREUS Core Banking - Script de Inicialização do Banco de Dados
-- This script creates databases and users only.
-- Table creation is handled by JPA/Hibernate ddl-auto=update per service.

-- Create database for Keycloak
CREATE DATABASE keycloak;

-- Create user for Keycloak
CREATE USER keycloak WITH PASSWORD 'keycloak123';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;

-- Connect to keycloak database
\c keycloak;

-- Configure encoding and collation for Keycloak
SET client_encoding = 'UTF8';
SET default_tablespace = '';

-- Grant privileges on public schema
GRANT ALL ON SCHEMA public TO keycloak;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO keycloak;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO keycloak;

-- Connect back to main database
\c aurix_db;

-- Create main schema (JPA entities use this schema)
CREATE SCHEMA IF NOT EXISTS aurix;
