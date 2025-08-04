import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/transaction.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../blocs/transaction_bloc.dart';
import '../services/transaction_service.dart';

class TransactionDetailPage extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    // Load fresh data from server
    context.read<TransactionBloc>().add(
          LoadTransactionDetail(
            transactionId: widget.transaction.id,
            type: widget.transaction.type,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Detail Transaksi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () => _showPrintDialog(),
            tooltip: 'Print Invoice',
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePDF(),
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => TransactionBloc(apiClient: ApiClient())
          ..add(LoadTransactionDetail(
            transactionId: widget.transaction.id,
            type: widget.transaction.type,
          )),
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            }

            if (state is TransactionError) {
              // If detail loading fails, use the transaction from widget props
              print(
                  '⚠️ Detail loading failed, using widget transaction data: ${state.message}');
              return _buildTransactionDetail(widget.transaction);
            }

            // Use the transaction from widget if detail loading fails
            final transaction = state is TransactionDetailLoaded
                ? state.transaction
                : widget.transaction;

            return _buildTransactionDetail(transaction);
          },
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(Transaction transaction) {
    // Debug print to see what data we have
    print('🔍 Transaction Detail Data:');
    print('  - ID: ${transaction.id}');
    print('  - Invoice: ${transaction.invoiceNumber}');
    print('  - Type: ${transaction.type}');
    print('  - Customer: ${transaction.customer?.name ?? 'NULL'}');
    print('  - Vehicle: ${transaction.vehicle?.model ?? 'NULL'}');
    print('  - Amount: ${transaction.amount}');

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Header
          _buildInvoiceHeader(transaction),
          SizedBox(height: 24),

          // Customer/Supplier Info
          _buildPartyInfo(transaction),
          SizedBox(height: 24),

          // Vehicle Info
          _buildVehicleInfo(transaction),
          SizedBox(height: 24),

          // Transaction Details
          _buildTransactionInfo(transaction),
          SizedBox(height: 24),

          // Payment Info
          _buildPaymentInfo(transaction),
          SizedBox(height: 24),

          // Notes
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildNotes(transaction),

          SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(transaction),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(Transaction transaction) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    transaction.invoiceNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: transaction.type == 'sales'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: transaction.type == 'sales'
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
                child: Text(
                  transaction.type.toUpperCase(),
                  style: TextStyle(
                    color: transaction.type == 'sales'
                        ? Colors.green
                        : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(transaction.transactionDate)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyInfo(Transaction transaction) {
    final isSales = transaction.type == 'sales';
    final title = isSales ? 'Informasi Customer' : 'Informasi Supplier';
    final name =
        isSales ? transaction.customer?.name : transaction.supplierName;
    final phone = isSales ? transaction.customer?.phone : 'N/A';
    final address = isSales ? transaction.customer?.address : 'N/A';

    return _buildInfoCard(
      title: title,
      icon: isSales ? Icons.person : Icons.business,
      children: [
        _buildInfoRow('Nama', name ?? 'N/A'),
        if (isSales) _buildInfoRow('Telepon', phone ?? 'N/A'),
        if (isSales) _buildInfoRow('Alamat', address ?? 'N/A'),
      ],
    );
  }

  Widget _buildVehicleInfo(Transaction transaction) {
    final vehicle = transaction.vehicle;
    return _buildInfoCard(
      title: 'Informasi Kendaraan',
      icon: Icons.directions_car,
      children: [
        _buildInfoRow('Brand', vehicle?.brand?.name ?? 'N/A'),
        _buildInfoRow('Model', vehicle?.model ?? 'N/A'),
        _buildInfoRow('Tahun', vehicle?.year.toString() ?? 'N/A'),
        _buildInfoRow('Warna', vehicle?.color ?? 'N/A'),
        _buildInfoRow('Plat Nomor', vehicle?.licensePlate ?? 'N/A'),
        _buildInfoRow('Nomor Rangka', vehicle?.chassisNumber ?? 'N/A'),
        _buildInfoRow('Nomor Mesin', vehicle?.engineNumber ?? 'N/A'),
        _buildInfoRow(
            'Kilometer',
            vehicle?.odometer != null
                ? '${NumberFormat('#,##0').format(vehicle!.odometer)} km'
                : 'N/A'),
      ],
    );
  }

  Widget _buildTransactionInfo(Transaction transaction) {
    return _buildInfoCard(
      title: 'Detail Transaksi',
      icon: Icons.receipt,
      children: [
        _buildInfoRow('Total', _formatCurrency(transaction.amount)),
        _buildInfoRow('Dibayar', _formatCurrency(transaction.paidAmount)),
        _buildInfoRow('Sisa', _formatCurrency(transaction.remainingAmount)),
        if (transaction.type == 'sales' &&
            transaction.vehicle?.purchasePrice != null)
          _buildInfoRow(
              'HPP', _formatCurrency(transaction.vehicle!.purchasePrice)),
        if (transaction.type == 'sales')
          _buildInfoRow(
              'Profit',
              _formatCurrency(transaction.amount -
                  (transaction.vehicle?.purchasePrice ?? 0))),
      ],
    );
  }

  Widget _buildPaymentInfo(Transaction transaction) {
    return _buildInfoCard(
      title: 'Informasi Pembayaran',
      icon: Icons.payment,
      children: [
        _buildInfoRow('Metode', transaction.paymentMethod),
        _buildInfoRow(
            'Status', _getPaymentStatusText(transaction.paymentStatus)),
        if (transaction.type == 'sales')
          _buildInfoRow(
              'Down Payment', _formatCurrency(transaction.paidAmount)),
      ],
    );
  }

  Widget _buildNotes(Transaction transaction) {
    return _buildInfoCard(
      title: 'Catatan',
      icon: Icons.note,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            transaction.notes!,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Transaction transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showPrintDialog(),
          icon: Icon(Icons.print),
          label: Text('Print Invoice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _generatePDF(),
          icon: Icon(Icons.picture_as_pdf),
          label: Text('Generate PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (transaction.paymentStatus != 'paid') ...[
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _updatePaymentStatus(transaction),
            icon: Icon(Icons.payment),
            label: Text('Update Pembayaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Print Invoice'),
          ],
        ),
        content: Text('Pilih opsi print untuk invoice ini:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _printInvoice();
            },
            icon: Icon(Icons.print),
            label: Text('Print Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _printInvoice() async {
    try {
      await _transactionService.printInvoice(
          widget.transaction.id, widget.transaction.type);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Invoice berhasil "dicetak" (Mock Print)'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal print invoice: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generatePDF() async {
    try {
      final pdfUrl = await _transactionService.generatePDF(
          widget.transaction.id, widget.transaction.type);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                  child: Text('PDF berhasil "dibuat": $pdfUrl (Mock PDF)')),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Gagal generate PDF: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updatePaymentStatus(Transaction transaction) {
    // TODO: Implement payment status update dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update pembayaran coming soon')),
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat('#,##0').format(amount)}';
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'Sebagian';
      case 'pending':
        return 'Belum Bayar';
      default:
        return status;
    }
  }
}
