-- Create databases
CREATE DATABASE arborist_db;
CREATE DATABASE fence_db;
CREATE DATABASE keycloak_db;

-- Enable ltree extension for Arborist
\connect arborist_db;
CREATE EXTENSION IF NOT EXISTS ltree;
