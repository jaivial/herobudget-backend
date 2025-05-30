import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../utils/extensions.dart';
import '../theme/app_theme.dart';
import '../services/cash_bank_service.dart';
import '../models/dashboard_model.dart';

class TransferModal extends StatefulWidget {
  final CashBankDistribution distribution;
  final VoidCallback onTransferComplete;

  const TransferModal({
    super.key,
    required this.distribution,
    required this.onTransferComplete,
  });

  @override
  State<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends State<TransferModal>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final CashBankService _cashBankService = CashBankService();
  bool _isLoading = false;
  bool _isCashToBank = true; // true = cash to bank, false = bank to cash
  String? _errorMessage;

  late AnimationController _animationController;
  late AnimationController _switchAnimationController;
  late AnimationController _cardSwapAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _switchAnimation;
  late Animation<double> _cardSwapAnimation;
  late Animation<Offset> _leftCardAnimation;
  late Animation<Offset> _rightCardAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _cardSwapAnimationController = AnimationController(
      duration: const Duration(
        milliseconds: 1000,
      ), // Duración más larga para suavidad
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _switchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _switchAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Animación para el intercambio de tarjetas
    _cardSwapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardSwapAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Animaciones de posición para las tarjetas con movimiento circular y aterrizaje suave
    _leftCardAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _cardSwapAnimationController,
        curve: Curves.easeOutBack, // Aterrizaje suave con rebote
      ),
    );

    _rightCardAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _cardSwapAnimationController,
        curve: Curves.easeOutBack, // Aterrizaje suave con rebote
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    _switchAnimationController.dispose();
    _cardSwapAnimationController.dispose();
    super.dispose();
  }

  double get _maxTransferAmount {
    return _isCashToBank
        ? widget.distribution.cashAmount
        : widget.distribution.bankAmount;
  }

  String get _fromAccount {
    return _isCashToBank
        ? context.tr.translate('cash')
        : context.tr.translate('bank');
  }

  String get _toAccount {
    return _isCashToBank
        ? context.tr.translate('bank')
        : context.tr.translate('cash');
  }

  void _switchTransferDirection() {
    // Iniciar animación del botón de intercambio
    _switchAnimationController.forward().then((_) {
      _switchAnimationController.reverse();
    });

    // Iniciar animación de intercambio de tarjetas (solo forward)
    _cardSwapAnimationController.forward().then((_) {
      // Cambiar el estado al final de la animación
      setState(() {
        _isCashToBank = !_isCashToBank;
        _amountController.clear();
        _errorMessage = null;
      });

      // Resetear la animación suavemente para la próxima vez
      _cardSwapAnimationController.reset();
    });
  }

  void _validateAmount(String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.isEmpty) return;

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = context.tr.translate('invalid_amount');
      });
      return;
    }

    if (amount > _maxTransferAmount) {
      setState(() {
        _errorMessage = context.tr.translate('insufficient_funds');
      });
      return;
    }
  }

  Future<void> _performTransfer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = context.tr.translate('invalid_amount');
      });
      return;
    }

    if (amount > _maxTransferAmount) {
      setState(() {
        _errorMessage = context.tr.translate('insufficient_funds');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success;
      if (_isCashToBank) {
        success = await _cashBankService.transferCashToBank(amount);
      } else {
        success = await _cashBankService.transferBankToCash(amount);
      }

      if (success) {
        widget.onTransferComplete();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(context.tr.translate('transfer_successful')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = context.tr.translate('transfer_failed');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.tr.translate('transfer_error');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Improved color scheme
    final Color surfaceColor =
        isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final Color cardColor =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA);
    final Color primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final Color secondaryTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF666666);

    // Enhanced gradient colors
    final LinearGradient cashGradient = LinearGradient(
      colors:
          isDarkMode
              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
              : [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final LinearGradient bankGradient = LinearGradient(
      colors:
          isDarkMode
              ? [const Color(0xFF2196F3), const Color(0xFF42A5F5)]
              : [const Color(0xFF1565C0), const Color(0xFF2196F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final Color accentColor =
        isDarkMode ? const Color(0xFF6C63FF) : const Color(0xFF5A52FF);
    final Color borderColor =
        isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.2),
                                accentColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr.translate('transfer_money'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: secondaryTextColor,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Enhanced Transfer Direction Selector with Animation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDarkMode ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _cardSwapAnimation,
                        builder: (context, child) {
                          return Row(
                            children: [
                              // Enhanced From Account with Animation
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(
                                    _leftCardAnimation.value.dx * 120,
                                    math.sin(
                                          _cardSwapAnimation.value * math.pi,
                                        ) *
                                        30,
                                  ),
                                  child: Transform.scale(
                                    scale:
                                        1.0 + (_cardSwapAnimation.value * 0.1),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient:
                                            _isCashToBank
                                                ? cashGradient
                                                : bankGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isCashToBank
                                                    ? Colors.green
                                                    : Colors.blue)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _isCashToBank
                                                  ? Icons.payments_rounded
                                                  : Icons
                                                      .account_balance_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _fromAccount,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              context.tr.formatCurrency(
                                                _maxTransferAmount,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Enhanced Switch Button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: AnimatedBuilder(
                                  animation: _switchAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _switchAnimation.value * 3.14159,
                                      child: GestureDetector(
                                        onTap: _switchTransferDirection,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                accentColor,
                                                accentColor.withOpacity(0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: accentColor.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.swap_horiz_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Enhanced To Account with Animation
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(
                                    _rightCardAnimation.value.dx * 120,
                                    math.sin(
                                          _cardSwapAnimation.value * math.pi,
                                        ) *
                                        30,
                                  ),
                                  child: Transform.scale(
                                    scale:
                                        1.0 + (_cardSwapAnimation.value * 0.1),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient:
                                            _isCashToBank
                                                ? bankGradient
                                                : cashGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isCashToBank
                                                    ? Colors.blue
                                                    : Colors.green)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _isCashToBank
                                                  ? Icons
                                                      .account_balance_rounded
                                                  : Icons.payments_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _toAccount,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              context.tr.formatCurrency(
                                                _isCashToBank
                                                    ? widget
                                                        .distribution
                                                        .bankAmount
                                                    : widget
                                                        .distribution
                                                        .cashAmount,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Enhanced Amount Input Section
                    Text(
                      context.tr.translate('amount'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDarkMode ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: _validateAmount,
                        decoration: InputDecoration(
                          hintText: '0,00',
                          hintStyle: TextStyle(
                            color: secondaryTextColor.withOpacity(0.6),
                            fontSize: 18,
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.euro_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: borderColor.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${context.tr.translate('available')}: ${context.tr.formatCurrency(_maxTransferAmount)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Enhanced Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDarkMode ? 0.1 : 0.05,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                backgroundColor: cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: borderColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              child: Text(
                                context.tr.translate('cancel'),
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  accentColor,
                                  accentColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ||
                                          _errorMessage != null ||
                                          _amountController.text.isEmpty
                                      ? null
                                      : _performTransfer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.send_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            context.tr.translate('transfer'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
