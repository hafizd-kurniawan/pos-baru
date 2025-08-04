import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/sale_transaction.dart';
import '../../../../core/theme/app_theme.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final SaleTransaction sale;
  final VoidCallback onPrint;
  final VoidCallback onGeneratePDF;

  const InvoicePreviewDialog({
    super.key,
    required this.sale,
    required this.onPrint,
    required this.onGeneratePDF,
  });

  String _formatCurrency(double? amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm').format(date);
  }

  String _translatePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer Bank';
      case 'credit':
        return 'Kredit/Cicilan';
      case 'debit':
        return 'Kartu Debit';
      default:
        return method;
    }
  }

  String _translatePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'DP/Sebagian';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Invoice Penjualan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Invoice Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Header
                    _buildCompanyHeader(),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Transaction Info
                    _buildTransactionInfo(),

                    const SizedBox(height: 24),

                    // Customer Info
                    _buildCustomerInfo(),

                    const SizedBox(height: 24),

                    // Vehicle Info
                    _buildVehicleInfo(),

                    const SizedBox(height: 24),

                    // Payment Details
                    _buildPaymentDetails(),

                    const SizedBox(height: 24),

                    // Notes
                    if (sale.notes?.isNotEmpty == true) ...[
                      _buildNotes(),
                      const SizedBox(height: 24),
                    ],

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGeneratePDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPrint,
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BENGKEL MOTOR SEJAHTERA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jl. Raya Contoh No. 123, Jakarta Selatan\n'
          'Telp: (021) 1234-5678 | Email: info@bengkelmotor.com',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INVOICE PENJUALAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('No. Invoice', sale.transactionCode),
              _buildInfoRow('Tanggal', _formatDate(sale.transactionDate)),
              _buildInfoRow('Sales', sale.salesperson?.fullName ?? 'Admin'),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getPaymentStatusColor(sale.paymentStatus).withOpacity(0.1),
            border: Border.all(
              color: _getPaymentStatusColor(sale.paymentStatus),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getPaymentStatusColor(sale.paymentStatus),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _translatePaymentStatus(sale.paymentStatus),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getPaymentStatusColor(sale.paymentStatus),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFORMASI CUSTOMER',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Nama', sale.customer?.name ?? 'Tidak diketahui'),
              _buildInfoRow(
                  'Telepon', sale.customer?.phone ?? 'Tidak diketahui'),
              if (sale.customer?.email?.isNotEmpty == true)
                _buildInfoRow('Email', sale.customer!.email!),
              if (sale.customer?.address?.isNotEmpty == true)
                _buildInfoRow('Alamat', sale.customer!.address!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    final vehicle = sale.vehicle;
    if (vehicle == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETAIL KENDARAAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Kode Kendaraan', vehicle.code),
              _buildInfoRow('Brand & Model',
                  '${vehicle.brand?.name ?? 'Unknown'} ${vehicle.model}'),
              _buildInfoRow('Tahun', vehicle.year.toString()),
              _buildInfoRow('Warna', vehicle.color ?? 'Tidak diatur'),
              _buildInfoRow(
                  'Nomor Polisi', vehicle.licensePlate ?? 'Tidak diatur'),
              _buildInfoRow('Odometer',
                  '${NumberFormat('#,###').format(vehicle.odometer)} km'),
              if (vehicle.fuelType != null)
                _buildInfoRow('Bahan Bakar', vehicle.fuelType!),
              if (vehicle.transmissionType != null)
                _buildInfoRow('Transmisi', vehicle.transmissionType!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETAIL PEMBAYARAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              _buildPaymentRow(
                  'Harga Jual', _formatCurrency(sale.sellingPrice)),
              if (sale.downPayment != null) ...[
                _buildPaymentRow(
                    'Uang Muka', _formatCurrency(sale.downPayment)),
                _buildPaymentRow(
                  'Sisa Pembayaran',
                  _formatCurrency(sale.sellingPrice - sale.downPayment!),
                ),
              ],
              const Divider(),
              _buildPaymentRow(
                'TOTAL YANG DIBAYAR',
                _formatCurrency(sale.downPayment ?? sale.sellingPrice),
                isTotal: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Metode Pembayaran:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _translatePaymentMethod(sale.paymentMethod),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATATAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow.shade200),
          ),
          child: Text(
            sale.notes!,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Terima kasih atas kepercayaan Anda!\n'
          'Semoga kendaraan ini memberikan pelayanan terbaik.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Invoice ini digenerate pada ${_formatDate(DateTime.now())}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
