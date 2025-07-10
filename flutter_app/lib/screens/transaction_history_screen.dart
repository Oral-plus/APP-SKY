import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';
import '../utils/theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndTransactions();
  }

  Future<void> _loadUserAndTransactions() async {
    try {
      final user = await ApiService.getUserProfile();
      _currentUserId = user.id;
      await _loadTransactions();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final transactions = await ApiService.getTransactionHistory(
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _transactions = transactions;
          } else {
            _transactions.addAll(transactions);
          }
          _hasMoreData = transactions.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando transacciones: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (!_hasMoreData || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Transacciones'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadTransactions(refresh: true),
              child: _transactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppTheme.textSecondaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tienes transacciones aún',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _transactions.length) {
                          // Botón de cargar más
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _loadMoreTransactions,
                                child: const Text('Cargar más'),
                              ),
                            ),
                          );
                        }

                        final transaction = _transactions[index];
                        return _TransactionCard(
                          transaction: transaction,
                          currentUserId: _currentUserId ?? 0,
                        );
                      },
                    ),
            ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final int currentUserId;

  const _TransactionCard({
    required this.transaction,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isOutgoing = transaction.isOutgoing(currentUserId);
    final statusColor = AppTheme.getStatusColor(transaction.estado);
    final typeIcon = _getTypeIcon(transaction.tipoTransaccionId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.nombreParaMostrar,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.fechaFormateada,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      transaction.getMontoConSigno(currentUserId),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTransactionColor(isOutgoing),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.estadoFormateado,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.descripcion != null && transaction.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                transaction.descripcion!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Código: ${transaction.codigoTransaccion}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                    fontFamily: 'monospace',
                  ),
                ),
                if (transaction.comision > 0)
                  Text(
                    'Comisión: ${transaction.comisionFormateada}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(int tipoId) {
    switch (tipoId) {
      case 1: // Envío de dinero
        return Icons.send;
      case 2: // Recarga de saldo
        return Icons.add_circle;
      case 3: // Pago de servicios
        return Icons.receipt_long;
      case 4: // Retiro de efectivo
        return Icons.money;
      case 5: // Recarga celular
        return Icons.phone_android;
      default:
        return Icons.swap_horiz;
    }
  }
}
