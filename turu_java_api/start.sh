#!/bin/bash

# This script helps start the Turu Java API with Aiven database connection

# Check if .env file exists
if [ -f .env ]; then
  echo "Loading environment variables from .env file"
  export $(grep -v '^#' .env | xargs)
else
  echo "No .env file found. Using default values or system environment variables."
fi

# Print connection info (without password)
echo "Starting Turu API with the following database connection:"
echo "Host: ${DB_HOST:-turumysql-turuproject.e.aivencloud.com}"
echo "Port: ${DB_PORT:-23729}"
echo "Database: ${DB_NAME:-dbturu}"
echo "Username: ${DB_USER:-avnadmin}"

# Check if mvnw exists
if [ -f "./mvnw" ]; then
  echo "Running with Maven wrapper..."
  chmod +x ./mvnw
  ./mvnw spring-boot:run
# Check if mvn command exists
elif command -v mvn &> /dev/null; then
  echo "Running with system Maven..."
  mvn spring-boot:run
else
  echo "Maven not found. Please install Maven or use the Maven wrapper."
  echo "To install Maven wrapper, run the following commands:"
  echo "mvn -N io.takari:maven:wrapper"
  echo ""
  echo "Or compile and run the application with Java directly:"
  echo "mkdir -p target/classes"
  echo "javac -d target/classes -cp \"lib/*\" src/main/java/com/turu/**/*.java"
  echo "java -cp \"target/classes:lib/*\" com.turu.TuruApiApplication"
fi 