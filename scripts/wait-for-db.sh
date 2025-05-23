#!/bin/bash

# Wait for SQL Server to be ready
echo "Waiting for SQL Server to be ready..."
for i in {1..50}; do
    /opt/mssql-tools/bin/sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASSWORD -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready!"
        break
    fi
    echo "SQL Server is not ready yet, retrying... ($i/50)"
    sleep 2
done

if [ $i -eq 50 ]; then
    echo "Could not connect to SQL Server after multiple attempts. Exiting."
    exit 1
fi

# Check if database exists and create if it doesn't
echo "Checking if database exists..."
DB_EXISTS=$(/opt/mssql-tools/bin/sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASSWORD -Q "SELECT COUNT(*) FROM sys.databases WHERE name = '$DB_NAME'" -h -1)

if [ "$DB_EXISTS" -eq "0" ]; then
    echo "Database $DB_NAME does not exist. Creating..."
    /opt/mssql-tools/bin/sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASSWORD -Q "CREATE DATABASE $DB_NAME"
    echo "Database $DB_NAME created."
else
    echo "Database $DB_NAME already exists."
fi

echo "Database connection established successfully."