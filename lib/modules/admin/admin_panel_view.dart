import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/hive_service.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock de usuários para controle master
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'u_01',
      'name': 'Alef Dias (Master)',
      'email': 'devalefdias44@gmail.com',
      'role': 'Super Admin Master',
      'isBlocked': false,
      'adsCount': 8,
      'totalSpent': 'R\$ 320,00',
    },
    {
      'id': 'u_02',
      'name': 'Carlos Vendedor',
      'email': 'carlos.promissao@gmail.com',
      'role': 'Usuário / Anunciante',
      'isBlocked': false,
      'adsCount': 4,
      'totalSpent': 'R\$ 69,80',
    },
    {
      'id': 'u_03',
      'name': 'Mariana Souza',
      'email': 'mari.souza@outlook.com',
      'role': 'Usuário / Anunciante',
      'isBlocked': false,
      'adsCount': 2,
      'totalSpent': 'R\$ 19,90',
    },
    {
      'id': 'u_04',
      'name': 'Anunciante Suspeito',
      'email': 'ofertas.rapidas@gmail.com',
      'role': 'Usuário / Suspeito',
      'isBlocked': true,
      'adsCount': 1,
      'totalSpent': 'R\$ 0,00',
    },
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isAuthorized {
    final email = AuthService.currentEmail ?? HiveService.email;
    return AuthService.isMasterAdmin(email) || AuthService.isCurrentMasterAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Se NÃO for o administrador master devalefdias44@gmail.com, bloqueia totalmente
    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Acesso Negado'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.g_mobiledata, size: 64, color: AppColors.error),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Acesso Restrito ao Administrador Geral',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apenas a conta devalefdias44@gmail.com possui permissão de controle total sobre usuários, pagamentos e anúncios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar ao App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Painel Geral Master ZUVEX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('devalefdias44@gmail.com • Controle Total', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Métricas'),
            Tab(text: '👥 Usuários'),
            Tab(text: '💰 Pagamentos Pix'),
            Tab(text: 'Moderação'),
            Tab(text: 'Denúncias'),
            Tab(text: 'Planos & Preços'),
            Tab(text: 'Cidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMetricsTab(isDark),
          _buildUsersTab(isDark),
          _buildPaymentsTab(isDark),
          _buildModerationTab(isDark),
          _buildReportsTab(isDark),
          _buildPlansTab(isDark),
          _buildCitiesTab(isDark),
        ],
      ),
    );
  }

  // 1. Métricas Gerais
  Widget _buildMetricsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Master
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Conta Master Autenticada',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'devalefdias44@gmail.com controla 100% dos usuários, recebimento Pix e moderação.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Resumo Financeiro & Operacional', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Faturamento Pix',
                  value: 'R\$ 2.450,00',
                  icon: Icons.pix_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Usuários Cadastrados',
                  value: '${_users.length} ativos',
                  icon: Iconsax.profile_2user,
                  color: AppColors.info,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Anúncios no Ar',
                  value: '148 anúncios',
                  icon: Iconsax.box,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Chave Pix Master',
                  value: 'devalefdias44...',
                  icon: Icons.key_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Gestão Completa de Usuários
  Widget _buildUsersTab(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final u = _users[index];
        final isBlocked = u['isBlocked'] as bool;
        final isMaster = (u['email'] as String) == 'devalefdias44@gmail.com';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMaster
                  ? AppColors.primary
                  : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              width: isMaster ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isMaster ? AppColors.primary : Colors.grey.shade400,
                    child: Icon(
                      isMaster ? Icons.star_rounded : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (isMaster) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MASTER',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(u['email'], style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBlocked ? AppColors.error.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBlocked ? 'Bloqueado' : 'Ativo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isBlocked ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Anúncios: ${u['adsCount']} • Total Gasto: ${u['totalSpent']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (!isMaster)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isBlocked ? AppColors.success : AppColors.error,
                      ),
                      onPressed: () {
                        setState(() {
                          u['isBlocked'] = !isBlocked;
                        });
                        Get.snackbar(
                          isBlocked ? 'Desbloqueado' : 'Usuário Bloqueado',
                          '${u['email']} foi ${isBlocked ? "reativado" : "bloqueado pelo Master"}.',
                          backgroundColor: isBlocked ? AppColors.success : AppColors.error,
                          colorText: Colors.white,
                        );
                      },
                      icon: Icon(isBlocked ? Icons.lock_open : Icons.block, size: 16),
                      label: Text(isBlocked ? 'Desbloquear' : 'Bloquear Acesso'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. Gestão Financeira & Pagamentos Pix (100% Tempo Real no Firestore)
  Widget _buildPaymentsTab(bool isDark) {
    return StreamBuilder<List<PaymentTransactionModel>>(
      stream: AdService.streamTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        // Métricas financeiras calculadas a partir dos dados reais
        double totalConfirmedAmount = 0.0;
        int confirmedCount = 0;
        int pendingCount = 0;

        for (final tx in transactions) {
          if (tx.isConfirmed) {
            totalConfirmedAmount += tx.amount;
            confirmedCount++;
          } else if (tx.isPending) {
            pendingCount++;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chave Pix Master Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Conta de Recebimento Pix ZUVEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Todos os pagamentos de planos de anúncios são destinados diretamente para a chave do Administrador Master:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.email, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'devalefdias44@gmail.com',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Resumo de Faturamento Real
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Recebido', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${totalConfirmedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                        Text('$confirmedCount pagamentos', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aguardando Pix', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '$pendingCount pendentes',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.warning),
                        ),
                        const Text('Reconhecimento auto', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transações Reais (Firestore)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${transactions.length} registros', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma transação Pix gerada ainda.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quando usuários ativarem anúncios, as cobranças aparecerão aqui em tempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...transactions.map((tx) {
                final isPending = tx.isPending;
                final isConfirmed = tx.isConfirmed;
                final dateFormatted =
                    '${tx.createdAt.day.toString().padLeft(2, '0')}/${tx.createdAt.month.toString().padLeft(2, '0')}/${tx.createdAt.year} às ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tx.planName.isNotEmpty ? tx.planName : 'Ativação de Anúncio',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'R\$ ${tx.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (tx.adTitle.isNotEmpty) ...[
                        Text(
                          'Anúncio: ${tx.adTitle}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        'Comprador: ${tx.userEmail != null && tx.userEmail!.isNotEmpty ? tx.userEmail! : 'Usuário ZUVEX'} • $dateFormatted',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : isPending
                                      ? AppColors.warning.withValues(alpha: 0.15)
                                      : AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isConfirmed
                                  ? 'Aprovado'
                                  : isPending
                                      ? 'Aguardando Pagamento'
                                      : 'Expirado',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isConfirmed
                                    ? AppColors.success
                                    : isPending
                                        ? AppColors.warning
                                        : AppColors.error,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isPending)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                await AdService.confirmPaymentAndActivateAd(
                                  transactionId: tx.id,
                                  adId: tx.adId,
                                  durationDays: 30,
                                );
                                Get.snackbar(
                                  'Pix Aprovado no Firebase!',
                                  'Pagamento de R\$ ${tx.amount.toStringAsFixed(2)} confirmado pelo Master. Anúncio ativado!',
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                );
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Aprovar Manualmente', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // 4. Moderação de Anúncios
  Widget _buildModerationTab(bool isDark) {
    final mockPending = AdService.getInitialMockAds().take(3).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockPending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ad = mockPending[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ad.cityName, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  Text(ad.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 4),
              Text(ad.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text('Anunciante: ${ad.userName} (${ad.contactPhone})', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () {
                        Get.snackbar('Rejeitado', 'Anúncio rejeitado pelo Administrador Master.');
                      },
                      child: const Text('Rejeitar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () {
                        Get.snackbar('Aprovado', 'Anúncio aprovado e publicado na ZUVEX!', backgroundColor: AppColors.success, colorText: Colors.white);
                      },
                      child: const Text('Aprovar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 5. Denúncias
  Widget _buildReportsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('GOLPE / FRAUDE', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  const Text('Hoje, 11:20', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Anúncio: "iPhone 14 Pro Max por R\$ 800"', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              const Text(
                'Detalhe: "Vendedor está pedindo adiantamento via Pix antes de entregar o aparelho em Promissão."',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.snackbar('Descartada', 'Denúncia descartada pelo Master.'),
                      child: const Text('Descartar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Get.snackbar('Removido', 'Anúncio removido e usuário banido pelo Master.', backgroundColor: AppColors.error, colorText: Colors.white),
                      child: const Text('Remover Anúncio'),
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

  // 6. Planos & Preços
  Widget _buildPlansTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: PlanModel.defaultPlans.map((plan) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${plan.durationDays} dias de duração • ${plan.isFeatured ? "Destaque" : "Normal"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Text(plan.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.primary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 7. Cidades
  Widget _buildCitiesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          tileColor: isDark ? AppColors.surfaceDark : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: const Icon(Iconsax.location5, color: AppColors.primary),
          title: const Text('Promissão – SP (Padrão)', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Status: Ativa • 124 anúncios'),
          trailing: const Icon(Icons.check_circle, color: AppColors.success),
        ),
        const SizedBox(height: 8),
        ListTile(
          tileColor: isDark ? AppColors.surfaceDark : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: const Icon(Iconsax.location, color: AppColors.textLight),
          title: const Text('Lins – SP', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Status: Ativa • Expansão'),
          trailing: const Icon(Icons.check_circle, color: AppColors.success),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}
