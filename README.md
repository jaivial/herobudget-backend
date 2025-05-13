# Hero Budget

Hero Budget is a comprehensive personal finance management application built with Flutter for the frontend and Go microservices for the backend.

## Dashboard Features

The application includes a powerful dashboard with the following features:

### Budget Overview
- View your current budget status including remaining amount, spent amount, and upcoming expenses
- Track your expense percentage and daily spending rate
- Get alerts for high spending periods

### Savings Management
- Monitor your savings progress with visual goal tracking
- Set and update savings goals
- View daily savings targets needed to reach your goal

### Cash & Bank Distribution
- See how your money is distributed between cash and bank accounts
- Transfer money between cash and bank accounts
- Track changes in your distribution over time

### Financial Metrics
- View key financial metrics including income, expenses, and bills
- Track changes in your financial status

### Bill Management
- View upcoming bills with due dates
- Mark bills as paid
- Add new bills with customizable categories and icons
- Set up recurring bills

### Period Selection
- Switch between different time periods (daily, weekly, monthly, quarterly, etc.)
- View customized data for each period

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Go 1.18 or higher
- SQLite

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/hero_budget.git
cd hero_budget
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Start the backend microservices:
```bash
./start_services.sh
```

4. Run the Flutter application:
```bash
flutter run
```

## Backend Microservices

The application is powered by several Go microservices:

1. **Dashboard Data Service** - Provides general dashboard data
2. **Budget Management Service** - Handles budget-related operations
3. **Savings Management Service** - Manages savings goals and tracking
4. **Cash-Bank Management Service** - Handles cash and bank account distribution
5. **Bills Management Service** - Manages bills, recurring payments, and due dates

## Using the Dashboard

### Viewing Your Financial Overview
The dashboard provides a quick overview of your current financial status. You can see your budget, savings progress, and upcoming bills all in one place.

### Changing Time Periods
Use the period selector at the top of the dashboard to switch between different time periods:
- Daily: View today's finances
- Weekly: View this week's financial status
- Monthly: View your monthly budget and expenses
- Custom: Select a custom date range

### Managing Savings
1. View your current savings progress in the Savings card
2. Click the edit button to update your savings goal
3. Enter your new goal amount and save

### Managing Bills
1. View your upcoming bills in the Bills section
2. Click "Pay Bill" to mark a bill as paid
3. Click "Add Bill" to add a new bill
   - Enter bill details including name, amount, due date
   - Select a category and icon
   - Toggle recurring if it's a recurring bill

### Transferring Between Cash and Bank
1. In the Cash & Bank Distribution card, click "Transfer"
2. Select whether to transfer from Cash to Bank or Bank to Cash
3. Enter the amount to transfer
4. Click "Transfer" to complete the transaction

## Development

### Running Tests
```bash
flutter test
```

### Restarting Services
If you need to restart the backend services:
```bash
./restart_services.sh
```

### Stopping Services
To stop all running services:
```bash
./stop_services.sh
```

## License
This project is licensed under the MIT License - see the LICENSE file for details.
