package services

import (
	"fmt"
	"log"
	"time"

	"money_flow_calculation/models"
	"money_flow_calculation/repositories"
)

// CalculationServiceInterface defines the interface for the calculation service
type CalculationServiceInterface interface {
	CalculateBudgetOverview(req models.PeriodRequest) (models.BudgetOverview, error)
}

// CalculationService handles budget calculation business logic
type CalculationService struct {
	repo repositories.DBRepositoryInterface
}

// NewCalculationService creates a new calculation service
func NewCalculationService(repo repositories.DBRepositoryInterface) *CalculationService {
	return &CalculationService{repo: repo}
}

// CalculateBudgetOverview calculates the budget overview for a specific period
func (s *CalculationService) CalculateBudgetOverview(req models.PeriodRequest) (models.BudgetOverview, error) {
	var overview models.BudgetOverview

	// Calculate date range for the period
	start, end := s.getDateRange(req.Period, req.Date, req.Direction)
	log.Printf("Calculating budget for period %s from %s to %s", req.Period, start.Format("2006-01-02"), end.Format("2006-01-02"))

	// Set period and date range in response
	overview.Period = req.Period
	overview.StartDate = start
	overview.EndDate = end
	overview.UserID = req.UserID

	// Get inherited money from previous period
	inheritedMoney, err := s.getInheritedMoney(req.UserID, start)
	if err != nil {
		log.Printf("Error getting inherited money: %v", err)
		inheritedMoney = 0
	}
	overview.MoneyFlow.FromPrevious = inheritedMoney

	// Get total income
	totalIncome, err := s.repo.GetTotalIncome(req.UserID, start, end)
	if err != nil {
		log.Printf("Error getting total income: %v", err)
		totalIncome = 0
	}
	overview.TotalIncome = totalIncome

	// Get total expenses
	totalExpenses, err := s.repo.GetTotalExpenses(req.UserID, start, end)
	if err != nil {
		log.Printf("Error getting total expenses: %v", err)
		totalExpenses = 0
	}
	overview.SpentAmount = totalExpenses

	// Get future bills
	futureBills, err := s.repo.GetFutureBills(req.UserID, start, end)
	if err != nil {
		log.Printf("Error getting future bills: %v", err)
		futureBills = 0
	}
	overview.UpcomingBills = futureBills

	// Calculate combined expenses
	overview.CombinedExpense = overview.SpentAmount + overview.UpcomingBills

	// Calculate total amount (budget)
	overview.TotalAmount = overview.MoneyFlow.FromPrevious + overview.TotalIncome

	// Calculate daily rate
	daysInPeriod := end.Sub(start).Hours()/24 + 1
	if daysInPeriod > 0 {
		overview.DailyRate = overview.CombinedExpense / daysInPeriod
	}

	// Calculate remaining money
	overview.RemainingAmount = overview.TotalAmount - overview.CombinedExpense

	// Calculate expense percentage
	if overview.TotalAmount > 0 {
		overview.ExpensePercent = (overview.CombinedExpense / overview.TotalAmount) * 100
	}

	// Store the calculation in the database
	err = s.repo.StoreBudgetData(
		req.UserID,
		req.Period,
		req.Date,
		overview.TotalAmount,            // total budget
		overview.RemainingAmount,        // remaining amount
		overview.SpentAmount,            // spent amount
		overview.UpcomingBills,          // upcoming amount
		overview.MoneyFlow.FromPrevious, // from previous
		overview.ExpensePercent,         // expense percent
		overview.TotalIncome,            // total income
		overview.DailyRate,              // daily rate
	)

	if err != nil {
		log.Printf("Error storing budget data: %v", err)
		// Continue anyway, we can still return the calculated data
	}

	return overview, nil
}

// getInheritedMoney calculates the amount of money inherited from previous periods
func (s *CalculationService) getInheritedMoney(userID string, start time.Time) (float64, error) {
	// First check if there's a record in the budget table
	balance, err := s.repo.GetPreviousRemainingMoney(userID, "monthly")
	if err == nil && balance > 0 {
		log.Printf("Found existing budget entry with from_previous=%f", balance)
		return balance, nil
	}

	// If no budget record found, calculate from transactions
	prevIncome, err := s.repo.GetPreviousIncome(userID, start)
	if err != nil {
		return 0, fmt.Errorf("error getting previous income: %w", err)
	}

	prevExpenses, err := s.repo.GetPreviousExpenses(userID, start)
	if err != nil {
		return 0, fmt.Errorf("error getting previous expenses: %w", err)
	}

	prevPaidBills, err := s.repo.GetPreviousPaidBills(userID, start)
	if err != nil {
		return 0, fmt.Errorf("error getting previous paid bills: %w", err)
	}

	// Calculate inherited balance
	balance = prevIncome - (prevExpenses + prevPaidBills)

	// Don't inherit negative balance
	if balance < 0 {
		balance = 0
	}

	log.Printf("Calculated inherited money: %f (income=%f, expenses=%f, paid bills=%f)",
		balance, prevIncome, prevExpenses, prevPaidBills)

	return balance, nil
}

// getDateRange calculates the start and end dates for a specific period
func (s *CalculationService) getDateRange(period string, date time.Time, direction string) (time.Time, time.Time) {
	var start, end time.Time

	switch period {
	case "daily":
		if direction == "next" {
			start = date.AddDate(0, 0, 1)
		} else {
			start = date.AddDate(0, 0, -1)
		}
		end = start
	case "weekly":
		// Find the Monday of the week
		daysToMonday := int(date.Weekday())
		if daysToMonday == 0 {
			daysToMonday = 7 // Sunday is 0, so 7 days to the previous Monday
		} else {
			daysToMonday = daysToMonday - 1 // Monday is 1, so 0 days
		}
		monday := date.AddDate(0, 0, -daysToMonday)

		if direction == "next" {
			start = monday.AddDate(0, 0, 7)
		} else {
			start = monday.AddDate(0, 0, -7)
		}

		end = start.AddDate(0, 0, 6)
	case "monthly":
		if direction == "next" {
			start = time.Date(date.Year(), date.Month()+1, 1, 0, 0, 0, 0, date.Location())
		} else {
			start = time.Date(date.Year(), date.Month()-1, 1, 0, 0, 0, 0, date.Location())
		}
		end = time.Date(start.Year(), start.Month()+1, 0, 0, 0, 0, 0, start.Location())
	case "quarterly":
		currentQuarter := ((int(date.Month()) - 1) / 3) + 1

		var targetQuarter int
		if direction == "next" {
			targetQuarter = currentQuarter + 1
			if targetQuarter > 4 {
				targetQuarter = 1
				start = time.Date(date.Year()+1, time.Month((targetQuarter-1)*3+1), 1, 0, 0, 0, 0, date.Location())
			} else {
				start = time.Date(date.Year(), time.Month((targetQuarter-1)*3+1), 1, 0, 0, 0, 0, date.Location())
			}
		} else {
			targetQuarter = currentQuarter - 1
			if targetQuarter < 1 {
				targetQuarter = 4
				start = time.Date(date.Year()-1, time.Month((targetQuarter-1)*3+1), 1, 0, 0, 0, 0, date.Location())
			} else {
				start = time.Date(date.Year(), time.Month((targetQuarter-1)*3+1), 1, 0, 0, 0, 0, date.Location())
			}
		}
		end = time.Date(start.Year(), start.Month()+3, 0, 0, 0, 0, 0, start.Location())
	case "semiannual":
		// First or second half of the year
		firstHalf := date.Month() <= 6

		if direction == "next" {
			if firstHalf {
				// From first half to second half
				start = time.Date(date.Year(), 7, 1, 0, 0, 0, 0, date.Location())
				end = time.Date(date.Year(), 12, 31, 0, 0, 0, 0, date.Location())
			} else {
				// From second half to first half of next year
				start = time.Date(date.Year()+1, 1, 1, 0, 0, 0, 0, date.Location())
				end = time.Date(date.Year()+1, 6, 30, 0, 0, 0, 0, date.Location())
			}
		} else {
			if firstHalf {
				// From first half to second half of previous year
				start = time.Date(date.Year()-1, 7, 1, 0, 0, 0, 0, date.Location())
				end = time.Date(date.Year()-1, 12, 31, 0, 0, 0, 0, date.Location())
			} else {
				// From second half to first half of same year
				start = time.Date(date.Year(), 1, 1, 0, 0, 0, 0, date.Location())
				end = time.Date(date.Year(), 6, 30, 0, 0, 0, 0, date.Location())
			}
		}
	case "annual":
		if direction == "next" {
			start = time.Date(date.Year()+1, 1, 1, 0, 0, 0, 0, date.Location())
		} else {
			start = time.Date(date.Year()-1, 1, 1, 0, 0, 0, 0, date.Location())
		}
		end = time.Date(start.Year(), 12, 31, 0, 0, 0, 0, start.Location())
	default:
		// Default to monthly
		if direction == "next" {
			start = time.Date(date.Year(), date.Month()+1, 1, 0, 0, 0, 0, date.Location())
		} else {
			start = time.Date(date.Year(), date.Month()-1, 1, 0, 0, 0, 0, date.Location())
		}
		end = time.Date(start.Year(), start.Month()+1, 0, 0, 0, 0, 0, start.Location())
	}

	return start, end
}
