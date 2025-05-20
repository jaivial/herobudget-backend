# Money Flow Calculation Microservice

A microservice for calculating budget metrics based on periods.

## Overview

This microservice calculates budget metrics such as:
- Remaining money
- Total income
- Total expenses
- Future bills
- Combined expenses
- Daily rate
- Inherited money (from previous periods)

## API Endpoints

### Calculate Budget Overview

```
GET /calculate?period={period}&date={date}&direction={direction}&user_id={user_id}
```

**Parameters**:

- `period`: The period type (daily, weekly, monthly, quarterly, semiannual, annual)
- `date`: Reference date in YYYY-MM-DD format
- `direction`: Direction of navigation (prev, next)
- `user_id`: User ID (optional for backwards compatibility)

**Example Request**:

```
GET /calculate?period=monthly&date=2025-05-20&direction=next&user_id=123
```

**Example Response**:

```json
{
  "success": true,
  "message": "Budget overview calculated successfully",
  "data": {
    "remaining_money": 1500.50,
    "total_income": 3000.00,
    "total_expenses": 1200.75,
    "future_bills": 300.25,
    "combined_expenses": 1501.00,
    "daily_rate": 50.03,
    "inherited_money": 200.00,
    "period": "monthly",
    "start_date": "2025-06-01T00:00:00Z",
    "end_date": "2025-06-30T00:00:00Z"
  }
}
```

## Running the Service

### Using Go directly

```bash
go run main.go
```

### Building and running the binary

```bash
go build -o money_flow_calculation
./money_flow_calculation
```

### Using Docker

Build the Docker image:

```bash
docker build -t money-flow-calculation .
```

Run the container:

```bash
docker run -p 8083:8083 money-flow-calculation
```

## Testing

Test with curl:

```bash
curl "http://localhost:8083/calculate?period=monthly&date=2023-09-15&direction=next"
```

## Integration with the Main System

Add the service to the restart_services script:

```bash
# money_flow_calculation
cd /backend/money_flow_calculation && go run main.go &
``` 