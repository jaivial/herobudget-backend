Mejoras_de_app.md
✅ 1) Asegurarse que todos los idiomas tienen todas las traducciones en /assets/l10n
2) Cuando cantidad restante es negativa el gráfico de budget overview se tiene que mostrar al 100% rojo, lo mismo que cuando los gastos comibnados hacen que el dinero restante sea 0 o menos.
3) Por defecto quiero que se muestre el modo oscuro de la APP.
4) Quiero que se incluya el boton de cmabio de modo claro/oscuro en las primeras paginas de onboarding/inicio sesión/registro
5) En la ventana de añadir categoría mejorar el tipo de categoría 'Income' 'Expense': mejorar el icono, mejorar la ui de las cards, añadir la traducción para todos los idiomas en /assets/l10n.
6) El periodo de tiempo weekly no carga los datos correctamente, los datos salen todos a 0: 
flutter: 📋 Request body: {"user_id":"19","period":"weekly","date":"2025-W22"}
flutter: 📡 Response status: 200
flutter: 📦 Response body: {"success":true,"message":"Budget overview fetched successfully","data":{"remaining_amount":0,"expense_percent":0,"spent_amount":0,"upcoming_amount":0,"total_amount":0,"total_balance":0,"combined_expense":0,"total_income":0,"daily_rate":0,"high_spending":false,"money_flow":{"from_previous":0},"cash_bank_distribution":{"cash_amount":0,"cash_percent":0,"bank_amount":0,"bank_percent":0,"total_amount":0},"savings_data":{"available":0,"goal":0,"period":"weekly","percent":0,"need_to_save":0,"daily_target":0}}}
flutter: ✅ Budget data received successfully

7) En el modal de Transferir dinero mejorar la legibilidad del icono y el texto del botón 'Transferir'. También el título del modal se corta viéndose así 'Transferir Din...'
8) El endpoint de transferir dinero no funciona bien con la configuración de microservicios en el servidor: flutter: 🔄 Transferring $200.00 from bank to cash for user: 19
flutter: 📡 Transfer response status: 404
flutter: 📦 Transfer response body: 404 page not found
flutter: ❌ Transfer failed: Error transferring bank to cash: 404
flutter: ❌ Error in transferBankToCash: Exception: Error transferring bank to cash: 404
9) El endpoint para fetch facturar cuando se hace click en pagar factura al abrir la pantalla 'Pagar Factura' no funciona correctamente con los endpoints en los microservicios en el VPS: flutter: Error in fetchInvoices: Exception: Error fetching invoices: 404

10) Mejora la disposición de la ui de las cards para proximas facturas y overdue bills.
11) En la pantalla pay_bill_screen mejora la ui de 'Detalles de la Factura', mejora la ui de Resumen del Pago, añade más margen entre el bottom de la pantalla y el botón de 'Confirmar Pago'.