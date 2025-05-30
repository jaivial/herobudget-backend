Mejoras_de_app.md
✅ 1) Asegurarse que todos los idiomas tienen todas las traducciones en /assets/l10n

**TRABAJO COMPLETADO:**

✅ **TRADUCCIONES AGREGADAS A TODOS LOS IDIOMAS:**
- Agregadas 33 claves faltantes a 14 archivos de idioma
- Claves agregadas: personal_information, tell_us_about_yourself, enter_first_name, please_enter_first_name, enter_last_name, please_enter_last_name, privacy_information, privacy_info_text, add_photo_to_personalize, tap_to_add_photo, tap_to_change_photo, update_profile_picture_anytime, your_selected_language, error_picking_image, please_enter_password, password_min_6_chars, password_strength, please_confirm_password, passwords_do_not_match, verify_email_agreement, password_guidelines, at_least_6_chars, passwords_match, contains_letters_numbers, contains_special_chars, password_weak, password_fair, password_good, password_strong, please_enter_email, please_enter_valid_email, please_enter_valid_email_address, please_enter_your_password, an_error_occurred_try_again

✅ **ARCHIVOS DART ACTUALIZADOS:**
- lib/screens/onboarding/steps/personal_info_step.dart: Reemplazados textos hardcodeados con context.tr.translate()
- lib/screens/onboarding/steps/profile_image_step.dart: Reemplazados textos hardcodeados con context.tr.translate()
- lib/screens/onboarding/steps/email_step.dart: Reemplazados textos hardcodeados con context.tr.translate()

✅ **ARCHIVOS DE IDIOMA ACTUALIZADOS:**
- assets/l10n/en.json (inglés - completo)
- assets/l10n/es.json (español - completo)
- assets/l10n/fr.json (francés - completo)
- assets/l10n/de.json (alemán - completo)
- assets/l10n/it.json (italiano - completo)
- assets/l10n/pt.json (portugués - completo)
- assets/l10n/ru.json (ruso - placeholders)
- assets/l10n/zh.json (chino - placeholders)
- assets/l10n/ja.json (japonés - placeholders)
- assets/l10n/da.json (danés - placeholders)
- assets/l10n/nl.json (holandés - placeholders)
- assets/l10n/el.json (griego - placeholders)
- assets/l10n/gsw.json (alemán suizo - placeholders)
- assets/l10n/hi.json (hindi - placeholders)

**NOTA:** Los idiomas con placeholders están listos para que un traductor nativo complete las traducciones reales.

ANÁLISIS DETALLADO - TRADUCCIONES FALTANTES EN ONBOARDING/SIGNIN/SIGNUP:

CLAVES FALTANTES QUE NECESITAN SER AGREGADAS A TODOS LOS IDIOMAS:

📧 PERSONAL INFO STEP:
- "personal_information": "Personal Information"
- "tell_us_about_yourself": "Tell us more about yourself"
- "enter_first_name": "Enter your first name"
- "please_enter_first_name": "Please enter your first name"
- "enter_last_name": "Enter your last name"
- "please_enter_last_name": "Please enter your last name"
- "privacy_information": "Privacy Information"
- "privacy_info_text": "We use your name to personalize your experience in the app. This information is never shared with third parties without your consent."

📸 PROFILE IMAGE STEP:
- "add_photo_to_personalize": "Add a photo to personalize your account"
- "tap_to_add_photo": "Tap to add a photo"
- "tap_to_change_photo": "Tap to change photo"
- "update_profile_picture_anytime": "You can update your profile picture anytime."
- "your_selected_language": "Your Selected Language"
- "error_picking_image": "Error picking image"

🔒 PASSWORD STEP:
- "please_enter_password": "Please enter a password"
- "password_min_6_chars": "Password must be at least 6 characters"
- "password_strength": "Password Strength:"
- "please_confirm_password": "Please confirm your password"
- "passwords_do_not_match": "Passwords do not match"
- "verify_email_agreement": "I agree to verify my email after registration"
- "password_guidelines": "Password Guidelines"
- "at_least_6_chars": "At least 6 characters long"
- "passwords_match": "Passwords match"
- "contains_letters_numbers": "Contains letters and numbers (recommended)"
- "contains_special_chars": "Contains special characters (recommended)"
- "password_weak": "Weak"
- "password_fair": "Fair"
- "password_good": "Good"
- "password_strong": "Strong"

📧 EMAIL STEP:
- "please_enter_email": "Please enter your email"
- "please_enter_valid_email": "Please enter a valid email"

📱 GENERAL ONBOARDING:
- "please_enter_valid_email_address": "Please enter a valid email address"
- "please_enter_your_password": "Please enter your password"
- "an_error_occurred_try_again": "An error occurred. Please try again."

ARCHIVOS A ACTUALIZAR:
- assets/l10n/es.json
- assets/l10n/en.json
- assets/l10n/fr.json
- assets/l10n/de.json
- assets/l10n/it.json
- assets/l10n/pt.json
- assets/l10n/ru.json
- assets/l10n/zh.json
- assets/l10n/ja.json
- assets/l10n/da.json
- assets/l10n/nl.json
- assets/l10n/el.json
- assets/l10n/gsw.json
- assets/l10n/hi.json

ARCHIVOS DART A ACTUALIZAR (reemplazar textos hardcodeados):
- lib/screens/onboarding/steps/personal_info_step.dart
- lib/screens/onboarding/steps/profile_image_step.dart
- lib/screens/onboarding/steps/password_step.dart
- lib/screens/onboarding/steps/email_step.dart
- lib/screens/onboarding/onboarding_screen.dart

✅ 2) Cuando cantidad restante es negativa el gráfico de budget overview se tiene que mostrar al 100% rojo, lo mismo que cuando los gastos comibnados hacen que el dinero restante sea 0 o menos.
✅ 3) Por defecto quiero que se muestre el modo oscuro de la APP.
✅ 4) Quiero que se incluya el boton de cmabio de modo claro/oscuro en las primeras paginas de onboarding/inicio sesión/registro
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