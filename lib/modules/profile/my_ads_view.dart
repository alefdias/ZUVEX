import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/ad_model.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/payment_service.dart';
import '../../widgets/ad_image_view.dart';

class MyAdsView extends StatefulWidget {
  const MyAdsView({super.key});

  @override
  State<MyAdsView> createState() => _MyAdsViewState();
}

class _MyAdsViewState extends State<MyAdsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUid ?? 'user_guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Meus Anúncios'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Ativos'),
            Tab(text: 'Rascunhos / A Pagar'),
            Tab(text: 'Vendidos'),
            Tab(text: 'Expirados'),
          ],
        ),
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: AdService.streamUserAds(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          // Apenas anúncios reais do usuário logado (sem anúncios fictícios)
          final ads = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAdsList(ads, 'Você ainda não possui anúncios cadastrados.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.active).toList(), 'Nenhum anúncio ativo no momento.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.draft || a.status == AdStatus.pendingPayment).toList(), 'Nenhum rascunho pendente.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.sold).toList(), 'Nenhum anúncio marcado como vendido.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.expired).toList(), 'Nenhum anúncio expirado.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdsList(List<AdModel> list, String emptyMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.box, size: 52, color: isDark ? AppColors.textSecondaryDark : AppColors.textLight),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final ad = list[index];
        return _MyAdItemCard(ad: ad);
      },
    );
  }
}

class _MyAdItemCard extends StatelessWidget {
  final AdModel ad;
  const _MyAdItemCard({required this.ad});

  void _showAdActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ad.status == AdStatus.draft || ad.status == AdStatus.pendingPayment)
                ListTile(
                  leading: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981)),
                  title: const Text('Pagar Pix e Ativar Anúncio', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  onTap: () {
                    Navigator.pop(ctx);
                    _payAndActivateDraft(context, ad);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                title: const Text('Marcar como Vendido'),
                onTap: () async {
                  await AdService.updateAdStatus(ad.id, AdStatus.sold);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Get.snackbar('Sucesso', 'Anúncio marcado como vendido!', backgroundColor: AppColors.success, colorText: Colors.white);
                },
              ),
              if (ad.status == AdStatus.expired)
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded, color: AppColors.primary),
                  title: const Text('Renovar Anúncio (30 dias)'),
                  onTap: () async {
                    await AdService.renewAd(ad.id, 30);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Get.snackbar('Sucesso', 'Anúncio renovado!', backgroundColor: AppColors.primary, colorText: Colors.white);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Excluir Anúncio', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  await AdService.deleteAd(ad.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Get.snackbar('Excluído', 'O anúncio foi removido permanentemente.');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _payAndActivateDraft(BuildContext context, AdModel ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PixActivationSheet(ad: ad),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDraftOrPending = ad.status == AdStatus.draft || ad.status == AdStatus.pendingPayment;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDraftOrPending
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          width: isDraftOrPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: AdImageView(
                    imageSource: ad.primaryImage,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ad.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ad.status == AdStatus.draft ? 'RASCUNHO (NÃO PUBLICADO)' : ad.status.label,
                        style: TextStyle(
                          color: _getStatusColor(ad.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ad.formattedPrice,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showAdActions(context),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),

          // Botão Direto de Pagar Pix e Ativar para Rascunhos
          if (isDraftOrPending) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Pagar Pix e Ativar Anúncio Agora',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () => _payAndActivateDraft(context, ad),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return AppColors.success;
      case AdStatus.pendingPayment:
      case AdStatus.inReview:
        return AppColors.warning;
      case AdStatus.sold:
        return AppColors.sold;
      case AdStatus.expired:
      case AdStatus.rejected:
      case AdStatus.removed:
        return AppColors.error;
      case AdStatus.draft:
        return const Color(0xFF6366F1);
    }
  }
}

/// Modal Interativo de Pagamento Pix para Ativação de Rascunhos
class _PixActivationSheet extends StatefulWidget {
  final AdModel ad;
  const _PixActivationSheet({required this.ad});

  @override
  State<_PixActivationSheet> createState() => _PixActivationSheetState();
}

class _PixActivationSheetState extends State<_PixActivationSheet> {
  PaymentTransactionModel? _transaction;
  bool _isLoading = true;
  bool _isChecking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generatePixCharge();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generatePixCharge() async {
    final plan = PlanModel.defaultPlans.firstWhere(
      (p) => p.id == widget.ad.planId,
      orElse: () => PlanModel.basic,
    );

    try {
      final tx = await PaymentService.instance.createPixCharge(
        ad: widget.ad,
        plan: plan,
        userEmail: widget.ad.userEmail,
      );

      if (mounted) {
        setState(() {
          _transaction = tx;
          _isLoading = false;
        });

        _startPolling(tx.botaPixChargeId ?? tx.id, plan.durationDays);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar('Erro', 'Não foi possível gerar a cobrança Pix. Tente novamente.');
      }
    }
  }

  void _startPolling(String chargeId, int durationDays) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      final status = await PaymentService.instance.checkPaymentStatus(chargeId);
      if (status == PaymentStatus.confirmed) {
        timer.cancel();
        await _onPaymentSuccess(durationDays);
      }
    });
  }

  Future<void> _manualCheck() async {
    final tx = _transaction;
    if (tx == null) return;
    setState(() => _isChecking = true);
    try {
      final status = await PaymentService.instance.checkPaymentStatus(tx.botaPixChargeId ?? tx.id);
      if (status == PaymentStatus.confirmed) {
        _timer?.cancel();
        final plan = PlanModel.defaultPlans.firstWhere((p) => p.id == widget.ad.planId, orElse: () => PlanModel.basic);
        await _onPaymentSuccess(plan.durationDays);
      } else {
        Get.snackbar(
          'Aguardando Pagamento',
          'O BotaPix ainda não detectou o pagamento. Assim que concluir no seu banco, a liberação é imediata!',
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _onPaymentSuccess(int durationDays) async {
    if (_transaction != null) {
      await PaymentService.instance.confirmPaymentAndActivate(
        transactionId: _transaction!.id,
        adId: widget.ad.id,
        durationDays: durationDays,
      );
      await HiveService.setPixVerified(true);
    }

    if (mounted) {
      Navigator.pop(context); // fecha sheet
      Get.defaultDialog(
        title: '🎉 Anúncio Ativado!',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
        middleText: 'Pagamento Pix aprovado com sucesso!\nSeu anúncio já está no ar com o selo 🛡️ Vendedor Verificado via Pix!',
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
          onPressed: () => Get.back(),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = _transaction;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              : tx == null
                  ? const Center(child: Text('Falha ao carregar cobrança Pix.'))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 18),
                              SizedBox(width: 6),
                              Text('Ativação Automática via Pix', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(tx.formattedAmount, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        const SizedBox(height: 14),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
                            ],
                          ),
                          child: Image.network(
                            tx.pixQrCode,
                            width: 180,
                            height: 180,
                            errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, size: 170, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Copia e Cola
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                            label: const Text('Copiar Código Pix (Copia e Cola)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: tx.pixCopiaECola));
                              Get.snackbar('Copiado!', 'Código Pix copiado com sucesso. Cole no app do seu banco para pagar.', backgroundColor: AppColors.success, colorText: Colors.white);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Botão Verificar
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: _isChecking
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh_rounded),
                            label: const Text('Já paguei, verificar agora'),
                            onPressed: _isChecking ? null : _manualCheck,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
