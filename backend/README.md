# Hero Budget Backend API Documentation

This document provides detailed information about the Hero Budget backend microservices and their REST API endpoints.

## Table of Contents

1. [Dashboard Data Service](#dashboard-data-service)
2. [Budget Management Service](#budget-management-service)
3. [Savings Management Service](#savings-management-service)
4. [Cash Bank Management Service](#cash-bank-management-service)
5. [Bills Management Service](#bills-management-service)

## Service Architecture

The backend consists of several independent microservices written in Go, each managing its own specific domain. All services connect to a shared SQLite database for data storage.

## Dashboard Data Service

**Port:** 8087

### Endpoints

#### `GET /dashboard/data`

Retrieves comprehensive dashboard data for a user.

**Query Parameters:**
- `user_id` (required): The ID of the user
- `period` (optional): The time period (daily, weekly, monthly, quarterly, semiannual, annual). Default: monthly

**Response:**
```json
{
  "period": "monthly",
  "date": "2023-07-01",
  "budget_overview": {
    "money_flow": {
      "percent": 10.0,
      "from_previous": 500.0
    },
    "remaining_amount": 750.0,
    "total_amount": 1000.0,
    "spent_amount": 150.0,
    "upcoming_amount": 100.0,
    "combined_expense": 250.0,
    "expense_percent": 25.0,
    "daily_rate": 8.33,
    "high_spending": false
  },
  "savings_overview": {
    "percent": 80.0,
    "available": 800.0,
    "goal": 1000.0,
    "need_to_save": 200.0,
    "daily_target": 6.67
  },
  "cash_distribution": {
    "month": "July 2023",
    "cash_amount": 300.0,
    "cash_percent": 30.0,
    "bank_amount": 700.0,
    "bank_percent": 70.0,
    "monthly_total": 1000.0
  },
  "finance_metrics": {
    "income": 2000.0,
    "expenses": 800.0,
    "bills": 400.0
  },
  "upcoming_bills": [
    {
      "id": 1,
      "name": "Rent",
      "amount": 800.0,
      "due_date": "2023-07-05",
      "paid": false,
      "overdue": false,
      "overdue_days": 0,
      "recurring": true,
      "category": "Housing",
      "icon": "🏠"
    }
  ]
}
```

## Budget Management Service

**Port:** 8088

### Endpoints

#### `GET /budget/fetch`

Retrieves budget information for a user.

**Query Parameters:**
- `user_id` (required): The ID of the user
- `period` (optional): The time period (daily, weekly, monthly, quarterly, semiannual, annual). Default: monthly

**Response:**
```json
{
  "success": true,
  "message": "Budget data fetched successfully",
  "data": {
    "user_id": "1",
    "period": "monthly",
    "date": "2023-07-01",
    "total_amount": 1000.0,
    "remaining_amount": 750.0,
    "spent_amount": 150.0,
    "upcoming_amount": 100.0,
    "from_previous": 500.0,
    "percent": 10.0
  }
}
```

#### `POST /budget/update`

Updates budget information for a user.

**Request Body:**
```json
{
  "user_id": "1",
  "period": "monthly",
  "total_amount": 1200.0,
  "spent_amount": 300.0,
  "upcoming_amount": 150.0,
  "from_previous": 600.0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Budget updated successfully",
  "data": {
    "user_id": "1",
    "period": "monthly",
    "date": "2023-07-01",
    "total_amount": 1200.0,
    "remaining_amount": 750.0,
    "spent_amount": 300.0,
    "upcoming_amount": 150.0,
    "from_previous": 600.0,
    "percent": 37.5
  }
}
```

## Savings Management Service

**Port:** 8089

### Endpoints

#### `GET /savings/fetch`

Retrieves savings information for a user.

**Query Parameters:**
- `user_id` (required): The ID of the user

**Response:**
```json
{
  "success": true,
  "message": "Savings data fetched successfully",
  "data": {
    "user_id": "1",
    "available": 800.0,
    "goal": 1000.0,
    "percent": 80.0,
    "need_to_save": 200.0,
    "daily_target": 6.67
  }
}
```

#### `POST /savings/update`

Updates savings information for a user.

**Request Body:**
```json
{
  "user_id": "1",
  "available": 850.0,
  "goal": 1000.0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Savings updated successfully",
  "data": {
    "user_id": "1",
    "available": 850.0,
    "goal": 1000.0,
    "percent": 85.0,
    "need_to_save": 150.0,
    "daily_target": 5.0
  }
}
```

## Cash Bank Management Service

**Port:** 8090

### Endpoints

#### `GET /cash-bank/distribution`

Retrieves cash and bank distribution for a user.

**Query Parameters:**
- `user_id` (required): The ID of the user

**Response:**
```json
{
  "success": true,
  "message": "Cash bank distribution fetched successfully",
  "data": {
    "user_id": "1",
    "month": "July 2023",
    "cash_amount": 300.0,
    "cash_percent": 30.0,
    "bank_amount": 700.0,
    "bank_percent": 70.0,
    "monthly_total": 1000.0
  }
}
```

#### `POST /cash/update`

Updates the cash amount for a user.

**Request Body:**
```json
{
  "user_id": "1",
  "amount": 350.0,
  "date": "2023-07-01T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Cash amount updated successfully",
  "data": {
    "user_id": "1",
    "month": "July 2023",
    "cash_amount": 350.0,
    "cash_percent": 33.3,
    "bank_amount": 700.0,
    "bank_percent": 66.7,
    "monthly_total": 1050.0
  }
}
```

#### `POST /bank/update`

Updates the bank amount for a user.

**Request Body:**
```json
{
  "user_id": "1",
  "amount": 750.0,
  "date": "2023-07-01T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bank amount updated successfully",
  "data": {
    "user_id": "1",
    "month": "July 2023",
    "cash_amount": 300.0,
    "cash_percent": 28.6,
    "bank_amount": 750.0,
    "bank_percent": 71.4,
    "monthly_total": 1050.0
  }
}
```

#### `POST /transfer/cash-to-bank`

Transfers money from cash to bank.

**Request Body:**
```json
{
  "user_id": "1",
  "amount": 100.0,
  "date": "2023-07-01T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Cash to bank transfer successful",
  "data": {
    "user_id": "1",
    "month": "July 2023",
    "cash_amount": 200.0,
    "cash_percent": 20.0,
    "bank_amount": 800.0,
    "bank_percent": 80.0,
    "monthly_total": 1000.0
  }
}
```

#### `POST /transfer/bank-to-cash`

Transfers money from bank to cash.

**Request Body:**
```json
{
  "user_id": "1",
  "amount": 100.0,
  "date": "2023-07-01T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bank to cash transfer successful",
  "data": {
    "user_id": "1",
    "month": "July 2023",
    "cash_amount": 400.0,
    "cash_percent": 40.0,
    "bank_amount": 600.0,
    "bank_percent": 60.0,
    "monthly_total": 1000.0
  }
}
```

## Bills Management Service

**Port:** 8091

### Endpoints

#### `GET /bills`

Retrieves unpaid bills for a user.

**Query Parameters:**
- `user_id` (required): The ID of the user

**Response:**
```json
{
  "success": true,
  "message": "Bills fetched successfully",
  "data": [
    {
      "id": 1,
      "user_id": "1",
      "name": "Rent",
      "amount": 800.0,
      "due_date": "2023-07-05",
      "paid": false,
      "overdue": false,
      "overdue_days": 0,
      "recurring": true,
      "category": "Housing",
      "icon": "🏠"
    },
    {
      "id": 2,
      "user_id": "1",
      "name": "Electricity",
      "amount": 100.0,
      "due_date": "2023-07-10",
      "paid": false,
      "overdue": false,
      "overdue_days": 0,
      "recurring": true,
      "category": "Utilities",
      "icon": "⚡"
    }
  ]
}
```

#### `POST /bills/add`

Adds a new bill for a user.

**Request Body:**
```json
{
  "user_id": "1",
  "name": "Internet",
  "amount": 50.0,
  "due_date": "2023-07-15",
  "paid": false,
  "overdue": false,
  "recurring": true,
  "category": "Utilities",
  "icon": "📱"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bill added successfully",
  "data": {
    "id": 3,
    "user_id": "1",
    "name": "Internet",
    "amount": 50.0,
    "due_date": "2023-07-15",
    "paid": false,
    "overdue": false,
    "overdue_days": 0,
    "recurring": true,
    "category": "Utilities",
    "icon": "📱"
  }
}
```

#### `POST /bills/pay`

Marks a bill as paid.

**Request Body:**
```json
{
  "user_id": "1",
  "bill_id": 2
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bill paid successfully"
}
```

#### `POST /bills/update`

Updates a bill's details.

**Request Body:**
```json
{
  "user_id": "1",
  "bill_id": 3,
  "name": "Internet & TV",
  "amount": 75.0,
  "due_date": "2023-07-15",
  "recurring": true,
  "category": "Utilities",
  "icon": "📡"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bill updated successfully",
  "data": {
    "id": 3,
    "user_id": "1",
    "name": "Internet & TV",
    "amount": 75.0,
    "due_date": "2023-07-15",
    "paid": false,
    "overdue": false,
    "overdue_days": 0,
    "recurring": true,
    "category": "Utilities",
    "icon": "📡"
  }
}
```

#### `POST /bills/delete`

Deletes a bill.

**Request Body:**
```json
{
  "user_id": "1",
  "bill_id": 3
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bill deleted successfully"
}
```

## Error Responses

All endpoints can return the following error responses:

**401 Unauthorized:**
```json
{
  "success": false,
  "message": "User not authenticated"
}
```

**400 Bad Request:**
```json
{
  "success": false,
  "message": "User ID is required"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "Error fetching data"
}
```

## Running the Services

All services can be started using the scripts in the root directory:

```bash
# Start all services
./start_services.sh

# Restart all services
./restart_services.sh

# Stop all services
./stop_services.sh
``` 