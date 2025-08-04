import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

class PaymentFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController sellingPriceController;
  final TextEditingController downPaymentController;
  final TextEditingController notesController;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime transactionDate;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String> onPaymentStatusChanged;
  final ValueChanged<DateTime> onTransactionDateChanged;

  const PaymentFormWidget({
    super.key,
    required this.formKey,
    required this.sellingPriceController,
    required this.downPaymentController,
    required this.notesController,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionDate,
    required this.onPaymentMethodChanged,
    required this.onPaymentStatusChanged,
    required this.onTransactionDateChanged,
  });

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';

    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return '';

    return NumberFormat('#,###').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Selling Price
          TextFormField(
            controller: sellingPriceController,
            decoration: InputDecoration(
              labelText: 'Harga Jual *',
              hintText: '125000000',
              prefixText: 'Rp ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final formatted = _formatCurrency(newValue.text);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Harga jual harus diisi';
              }
              final number =
                  double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
              if (number == null || number <= 0) {
                return 'Harga jual tidak valid';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Payment Method
          DropdownButtonFormField<String>(
            value: paymentMethod,
            decoration: InputDecoration(
              labelText: 'Metode Pembayaran *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'cash',
                child: Row(
                  children: [
                    Icon(Icons.money, size: 20),
                    SizedBox(width: 8),
                    Text('Tunai'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'transfer',
                child: Row(
                  children: [
                    Icon(Icons.account_balance, size: 20),
                    SizedBox(width: 8),
                    Text('Transfer Bank'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'credit',
                child: Row(
                  children: [
                    Icon(Icons.credit_card, size: 20),
                    SizedBox(width: 8),
                    Text('Kredit/Cicilan'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'debit',
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 20),
                    SizedBox(width: 8),
                    Text('Kartu Debit'),
                  ],
                ),
              ),
            ],
            onChanged: (value) => onPaymentMethodChanged(value!),
          ),

          const SizedBox(height: 16),

          // Payment Status
          DropdownButtonFormField<String>(
            value: paymentStatus,
            decoration: InputDecoration(
              labelText: 'Status Pembayaran *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'paid',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Lunas'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'partial',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('DP/Sebagian'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('Pending'),
                  ],
                ),
              ),
            ],
            onChanged: (value) => onPaymentStatusChanged(value!),
          ),

          const SizedBox(height: 16),

          // Down Payment (only show if partial payment)
          if (paymentStatus == 'partial') ...[
            TextFormField(
              controller: downPaymentController,
              decoration: InputDecoration(
                labelText: 'Uang Muka/DP *',
                hintText: '50000000',
                prefixText: 'Rp ',
                helperText: 'Jumlah yang sudah dibayar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  final formatted = _formatCurrency(newValue.text);
                  return TextEditingValue(
                    text: formatted,
                    selection:
                        TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              validator: (value) {
                if (paymentStatus == 'partial') {
                  if (value == null || value.isEmpty) {
                    return 'Uang muka harus diisi untuk pembayaran sebagian';
                  }
                  final downPayment =
                      double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                  final sellingPrice = double.tryParse(sellingPriceController
                      .text
                      .replaceAll(RegExp(r'[^0-9]'), ''));

                  if (downPayment == null || downPayment <= 0) {
                    return 'Uang muka tidak valid';
                  }

                  if (sellingPrice != null && downPayment >= sellingPrice) {
                    return 'Uang muka tidak boleh lebih dari harga jual';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Transaction Date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: transactionDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                onTransactionDateChanged(date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tanggal Transaksi *',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                DateFormat('dd MMMM yyyy').format(transactionDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Catatan',
              hintText: 'Catatan tambahan untuk transaksi ini...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: 16),

          // Payment Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Pembayaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Harga Jual',
                  sellingPriceController.text.isNotEmpty
                      ? 'Rp ${sellingPriceController.text}'
                      : 'Rp 0',
                ),
                if (paymentStatus == 'partial' &&
                    downPaymentController.text.isNotEmpty) ...[
                  _buildSummaryRow(
                    'Uang Muka',
                    'Rp ${downPaymentController.text}',
                  ),
                  _buildSummaryRow(
                    'Sisa Pembayaran',
                    _calculateRemaining(),
                    isHighlight: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isHighlight ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateRemaining() {
    final sellingPrice = double.tryParse(
            sellingPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    final downPayment = double.tryParse(
            downPaymentController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    final remaining = sellingPrice - downPayment;
    return 'Rp ${NumberFormat('#,###').format(remaining)}';
  }
}
