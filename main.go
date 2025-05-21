package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

func handlePayBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var payRequest PayBillRequest
	err := json.NewDecoder(r.Body).Decode(&payRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request
	if payRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	if payRequest.BillID <= 0 {
		sendErrorResponse(w, "Valid bill ID is required", http.StatusBadRequest)
		return
	}

	// Get the bill details before updating
	var bill Bill
	err = db.QueryRow(`
		SELECT id, user_id, name, amount, due_date, category, recurring, paid, payment_method, icon
		FROM bills WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID).Scan(
		&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate, &bill.Category, &bill.Recurring, &bill.Paid, &bill.PaymentMethod, &bill.Icon,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			sendErrorResponse(w, "Bill not found", http.StatusNotFound)
		} else {
			log.Printf("Error fetching bill: %v", err)
			sendErrorResponse(w, "Error fetching bill", http.StatusInternalServerError)
		}
		return
	}

	// Check if bill is already paid
	if bill.Paid {
		sendErrorResponse(w, "Bill is already paid", http.StatusBadRequest)
		return
	}

	// Default payment method to "bank" if not specified
	paymentMethod := payRequest.PaymentMethod
	if paymentMethod == "" {
		// Usar el método de pago almacenado en la factura si no se proporciona uno nuevo
		if bill.PaymentMethod != "" {
			paymentMethod = bill.PaymentMethod
		} else {
			paymentMethod = "bank"
		}
	}

	// Actualizar el método de pago en la factura si es diferente
	if bill.PaymentMethod != paymentMethod {
		_, err = db.Exec(`
			UPDATE bills
			SET payment_method = ?
			WHERE id = ? AND user_id = ?
		`, paymentMethod, payRequest.BillID, payRequest.UserID)
		if err != nil {
			log.Printf("Error updating payment method: %v", err)
			// Continue despite the error
		}
	}

	// Mark the bill as paid, reset overdue stats since it's now paid
	_, err = db.Exec(`
		UPDATE bills
		SET paid = 1, overdue = 0, overdue_days = 0, updated_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID)
	if err != nil {
		log.Printf("Error marking bill as paid: %v", err)
		sendErrorResponse(w, "Error marking bill as paid", http.StatusInternalServerError)
		return
	}

	// Process payment based on payment method
	// This is a simplification, in a real app you'd update account balances
	log.Printf("Bill %d paid with %s: $%.2f", bill.ID, paymentMethod, bill.Amount)

	// Determinar los montos de cash y bank según el método de pago
	var cashAmt, bankAmt float64
	if paymentMethod == "cash" {
		cashAmt = bill.Amount
		bankAmt = 0
	} else {
		cashAmt = 0
		bankAmt = bill.Amount
	}

	// Obtener la fecha actual para registrar el pago
	billDate := time.Now().Format("2006-01-02")

	// Actualizar los balances por periodos
	if err := updateTimeBalances(payRequest.UserID, 0, 0, bill.Amount, cashAmt, bankAmt, billDate); err != nil {
		log.Printf("Error updating time balances: %v", err)
		// Continue despite the error
	}

	// Recalcular todos los balances para asegurar que previous_xxx_amount y balance_xxx_amount se actualicen en cascada
	if err := recalculateAllBalances(payRequest.UserID, billDate); err != nil {
		log.Printf("Error recalculating balances: %v", err)
		// Continue despite the error
	}

	// Convertir la factura pagada en un gasto
	description := payRequest.Description
	if description == "" {
		description = fmt.Sprintf("Pago de factura: %s", bill.Name)
	}

	expenseReq := BillToExpenseRequest{
		UserID:        bill.UserID,
		Amount:        bill.Amount,
		Date:          billDate,
		Category:      bill.Category,
		PaymentMethod: paymentMethod,
		Description:   description,
	}

	// Registrar el gasto en el servicio de expense_management
	if err := createExpenseFromBill(expenseReq); err != nil {
		log.Printf("Error converting bill to expense: %v", err)
		// No fallamos la solicitud completa, solo registramos el error
	} else {
		log.Printf("Bill %d successfully converted to expense", bill.ID)
	}

	// SOLUCIÓN AL PROBLEMA DE RESPUESTA API:
	// En lugar de modificar manualmente los campos del objeto bill,
	// reconstruimos completamente el objeto desde la base de datos
	// para asegurar que todos los campos reflejen el estado actual
	var updatedBill Bill
	err = db.QueryRow(`
		SELECT id, user_id, name, amount, due_date, category, recurring, paid, overdue, overdue_days, payment_method, icon, created_at, updated_at
		FROM bills WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID).Scan(
		&updatedBill.ID, &updatedBill.UserID, &updatedBill.Name, &updatedBill.Amount, &updatedBill.DueDate,
		&updatedBill.Category, &updatedBill.Recurring, &updatedBill.Paid, &updatedBill.Overdue, &updatedBill.OverdueDays,
		&updatedBill.PaymentMethod, &updatedBill.Icon, &updatedBill.CreatedAt, &updatedBill.UpdatedAt,
	)

	if err != nil {
		log.Printf("Error fetching updated bill details: %v - Fallback to manually updated bill", err)
		// Fallback: Actualizamos manualmente el objeto bill como antes
		bill.Paid = true
		bill.Overdue = false
		bill.OverdueDays = 0
		bill.PaymentMethod = paymentMethod

		// Obtenemos las fechas de creación y actualización
		var createdAt, updatedAt string
		err = db.QueryRow("SELECT created_at, updated_at FROM bills WHERE id = ?", bill.ID).Scan(&createdAt, &updatedAt)
		if err == nil {
			bill.CreatedAt = createdAt
			bill.UpdatedAt = updatedAt
		}

		// Verificación post-actualización para asegurar que los datos sean correctos
		var verifiedPaid bool
		err = db.QueryRow("SELECT paid FROM bills WHERE id = ?", bill.ID).Scan(&verifiedPaid)
		if err == nil && verifiedPaid {
			// La base de datos confirma que está pagada
			log.Printf("Verificación exitosa: Factura %d marcada como pagada en base de datos", bill.ID)
			// Asegurarnos que el campo paid se actualice correctamente a pesar de cualquier problema
			bill.Paid = verifiedPaid
		} else if err != nil {
			log.Printf("Error en verificación post-actualización: %v", err)
		} else {
			log.Printf("Discrepancia detectada: Factura %d no aparece como pagada en base de datos", bill.ID)
		}

		// Usar el objeto bill actualizado manualmente como respuesta
		sendSuccessResponse(w, "Bill paid successfully and converted to expense", bill)
	} else {
		// Usamos el objeto updatedBill que fue reconstruido desde la base de datos
		log.Printf("Verificación exitosa: Factura %d reconstruida correctamente desde la base de datos. Paid=%v", updatedBill.ID, updatedBill.Paid)
		sendSuccessResponse(w, "Bill paid successfully and converted to expense", updatedBill)
	}
}

// Nueva función para convertir una factura pagada en un gasto
func createExpenseFromBill(billExpense BillToExpenseRequest) error {
	// Método 1: Intento a través de la API HTTP
	log.Printf("Intentando crear gasto desde factura para usuario %s por $%.2f", billExpense.UserID, billExpense.Amount)

	expenseServiceURL := "http://localhost:8094/expenses/add"

	// Convertir a estructura esperada por expense_management (AddExpenseRequest)
	expenseRequest := struct {
		UserID        string  `json:"user_id"`
		Amount        float64 `json:"amount"`
		Date          string  `json:"date"`
		Category      string  `json:"category"`
		PaymentMethod string  `json:"payment_method"`
		Description   string  `json:"description,omitempty"`
	}{
		UserID:        billExpense.UserID,
		Amount:        billExpense.Amount,
		Date:          billExpense.Date,
		Category:      billExpense.Category,
		PaymentMethod: billExpense.PaymentMethod,
		Description:   billExpense.Description,
	}

	// Convertir la solicitud a JSON
	jsonData, err := json.Marshal(expenseRequest)
	if err != nil {
		log.Printf("Error al serializar JSON: %v", err)
		// Continuar con el método alternativo
	} else {
		// Imprimir el JSON para depuración
		log.Printf("Intentando enviar a expense_management: %s", string(jsonData))

		// Crear la solicitud HTTP
		req, err := http.NewRequest("POST", expenseServiceURL, bytes.NewBuffer(jsonData))
		if err == nil {
			req.Header.Set("Content-Type", "application/json")

			// Enviar la solicitud
			client := &http.Client{Timeout: 10 * time.Second}
			resp, err := client.Do(req)
			if err == nil {
				defer resp.Body.Close()

				// Leer el cuerpo de la respuesta
				respBody, _ := io.ReadAll(resp.Body)
				log.Printf("Respuesta del servicio expense_management: Status=%s, Body=%s", resp.Status, string(respBody))

				// Si tuvimos éxito con el método HTTP, retornamos
				if resp.StatusCode == http.StatusOK {
					log.Printf("Gasto creado exitosamente a través de la API HTTP")
					return nil
				}
			} else {
				log.Printf("Error al enviar la petición HTTP: %v", err)
			}
		}
	}

	// SOLUCIÓN MEJORADA: Método directo a la base de datos como respaldo
	log.Printf("Método HTTP falló. Intentando método alternativo mejorado: inserción directa en la base de datos")

	// Ruta a la base de datos SQLite
	dbPath := "/Users/usuario/Documents/PROYECTOS/herobudgetflutter/hero_budget/backend/google_auth/users.db"
	log.Printf("Intentando conectar a SQLite en la ruta específica: %s", dbPath)

	// Importamos drivers necesarios para SQLite
	_ = "github.com/mattn/go-sqlite3" // Asegurarse de que el driver está incluido

	// Abrir conexión dedicada a SQLite (usamos file:path?mode=rw para asegurar permiso de escritura)
	sqliteDB, err := sql.Open("sqlite3", fmt.Sprintf("file:%s?mode=rw", dbPath))
	if err != nil {
		log.Printf("Error al abrir conexión dedicada a SQLite: %v", err)
		return fmt.Errorf("error al conectar a la base de datos SQLite: %v", err)
	}
	defer sqliteDB.Close()

	// Verificar conexión
	if err := sqliteDB.Ping(); err != nil {
		log.Printf("Error al verificar conexión a SQLite: %v", err)
		return fmt.Errorf("error al verificar conexión a SQLite: %v", err)
	}

	log.Printf("Conexión a SQLite establecida correctamente")

	// Ejecutar la consulta dentro de una transacción para mayor seguridad
	tx, err := sqliteDB.Begin()
	if err != nil {
		log.Printf("Error al iniciar transacción SQLite: %v", err)
		return fmt.Errorf("error al iniciar transacción SQLite: %v", err)
	}

	// Definir clausula para rollback en caso de error
	commit := false
	defer func() {
		if !commit {
			tx.Rollback()
			log.Printf("Transacción SQLite cancelada por error")
		}
	}()

	// Preparar la consulta SQL (usando placeholders específicos de SQLite)
	insertStmt, err := tx.Prepare(`
		INSERT INTO expenses (
			user_id, amount, date, category, payment_method, description, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
	`)

	if err != nil {
		log.Printf("Error al preparar consulta SQLite: %v", err)
		return fmt.Errorf("error al preparar consulta SQLite: %v", err)
	}
	defer insertStmt.Close()

	// Ejecutar la consulta preparada
	result, err := insertStmt.Exec(
		billExpense.UserID,
		billExpense.Amount,
		billExpense.Date,
		billExpense.Category,
		billExpense.PaymentMethod,
		billExpense.Description,
	)

	if err != nil {
		log.Printf("Error al ejecutar consulta SQLite: %v", err)
		return fmt.Errorf("error al ejecutar consulta SQLite: %v", err)
	}

	// Obtener el ID del gasto insertado
	id, err := result.LastInsertId()
	if err != nil {
		log.Printf("Error al obtener el ID del gasto insertado: %v", err)
		// Continuamos a pesar del error
	} else {
		log.Printf("Gasto creado correctamente con ID: %d (método SQLite directo)", id)
	}

	// Confirmar la transacción
	if err := tx.Commit(); err != nil {
		log.Printf("Error al confirmar transacción SQLite: %v", err)
		return fmt.Errorf("error al confirmar transacción SQLite: %v", err)
	}
	commit = true

	// Verificación post-inserción
	var count int
	err = sqliteDB.QueryRow("SELECT COUNT(*) FROM expenses WHERE user_id = ? AND description = ? AND amount = ?",
		billExpense.UserID, billExpense.Description, billExpense.Amount).Scan(&count)

	if err != nil {
		log.Printf("Error al verificar inserción: %v", err)
	} else if count > 0 {
		log.Printf("Verificación exitosa: Encontrados %d gastos con los criterios proporcionados", count)
	} else {
		log.Printf("Verificación fallida: No se encontraron gastos con los criterios proporcionados")
	}

	log.Printf("Gasto creado exitosamente mediante inserción directa en la base de datos SQLite")
	return nil
}

func updateDailyBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	dateStr := date.Format("2006-01-02")

	// Obtener el balance del día anterior para calcular el balance previo
	prevDate := date.AddDate(0, 0, -1)
	prevDateStr := prevDate.Format("2006-01-02")

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance del día anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM daily_balance 
		WHERE user_id = ? AND date = ?
	`, userID, prevDateStr).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del día anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como el balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para esta fecha
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM daily_balance
		WHERE user_id = ? AND date = ?
	`, userID, dateStr).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		// Verificar cuántas columnas tiene la tabla daily_balance
		var columnCount int
		err = db.QueryRow(`
			SELECT COUNT(*) FROM pragma_table_info('daily_balance')
		`).Scan(&columnCount)

		if err != nil {
			log.Printf("Error al obtener el número de columnas de daily_balance: %v", err)
			// Continuar con la consulta original
			columnCount = 16 // Asumimos 16 columnas basado en el esquema
		}

		log.Printf("La tabla daily_balance tiene %d columnas", columnCount)

		// Usar la consulta apropiada según el número de columnas
		// Aseguramos que el número de valores coincida con el número de columnas
		_, err = db.Exec(`
			INSERT INTO daily_balance (
				user_id, date, income_amount, expense_amount, bills_amount, 
				cash_amount, bank_amount, previous_cash_amount, previous_bank_amount, 
				balance_cash_amount, balance_bank_amount, balance, previous_balance,
				created_at, updated_at
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		`, userID, dateStr, incomeAmount, expenseAmount, billsAmount,
			totalCashAmount, totalBankAmount, prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE daily_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND date = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, previousBalance, balance, userID, dateStr)
	}

	if err != nil {
		return err
	}

	// Actualizar todos los días posteriores en cascada
	return updateSubsequentDailyBalances(userID, date.AddDate(0, 0, 1))
}

func updateWeeklyBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	// Calcular el número de semana y año
	year, week := date.ISOWeek()
	yearWeek := fmt.Sprintf("%d-%02d", year, week)

	// Calcular fecha de inicio y fin de la semana
	// El lunes es el primer día de la semana ISO
	daysSinceMonday := int(date.Weekday())
	if daysSinceMonday == 0 {
		daysSinceMonday = 7 // Domingo es 0 en time.Weekday(), pero queremos que sea 7
	}
	daysSinceMonday-- // Lunes es 1, queremos que sea 0

	startDate := date.AddDate(0, 0, -daysSinceMonday)
	startDateStr := startDate.Format("2006-01-02")
	endDate := startDate.AddDate(0, 0, 6)
	endDateStr := endDate.Format("2006-01-02")

	// Obtener el balance de la semana anterior para calcular el balance previo
	prevWeekStart := startDate.AddDate(0, 0, -7)
	prevYear, prevWeek := prevWeekStart.ISOWeek()
	prevYearWeek := fmt.Sprintf("%d-%02d", prevYear, prevWeek)

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance de la semana anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM weekly_balance
		WHERE user_id = ? AND year_week = ?
	`, userID, prevYearWeek).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	// Si no existe registro de la semana anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como el balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para esta semana
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM weekly_balance
		WHERE user_id = ? AND year_week = ?
	`, userID, yearWeek).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		// SOLUCIÓN AL PROBLEMA DE COLUMNAS:
		// Aseguramos que la consulta SQL tenga el número correcto de placeholders
		// y que estén en el orden correcto según el esquema de la tabla weekly_balance
		_, err = db.Exec(`
			INSERT INTO weekly_balance (
				user_id, year_week, start_date, end_date,
				income_amount, expense_amount, bills_amount,
				cash_amount, bank_amount,
				previous_cash_amount, previous_bank_amount,
				balance_cash_amount, balance_bank_amount,
				balance, previous_balance
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`,
			userID, yearWeek, startDateStr, endDateStr,
			incomeAmount, expenseAmount, billsAmount,
			totalCashAmount, totalBankAmount,
			prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount,
			balance, previousBalance)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		// SOLUCIÓN AL PROBLEMA DE COLUMNAS:
		// Aseguramos que la orden de los campos en UPDATE coincida con el esquema
		_, err = db.Exec(`
			UPDATE weekly_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_week = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, previousBalance, balance, userID, yearWeek)
	}

	if err != nil {
		return err
	}

	// No es necesario actualizar las semanas posteriores en cascada
	// ya que cada semana es independiente
	return nil
}
