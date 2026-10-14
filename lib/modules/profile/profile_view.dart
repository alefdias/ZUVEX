import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/hive_service.dart';
import '../../modules/auth/auth_controller.dart';
import '../../modules/auth/setup_profile_view.dart';
import '../admin/admin_panel_view.dart';
import 'my_ads_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late String _name;
  late String _email;
  late String _avatarPath;

  bool get _isMasterAdmin =>
      AuthService.isMasterAdmin(_email) || AuthService.isCurrentMasterAdmin;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _name = HiveService.name.isNotEmpty ? HiveService.name : 'Usuário ZUVEX';
      _email = AuthService.currentEmail ??
          (HiveService.email.isNotEmpty ? HiveService.email : 'usuario@zuvex.com');
      _avatarPath = HiveService.avatarPath;
    });
  }

  void _showTermsDialog(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        title: const Text('Excluir Conta (LGPD)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
        content: const Text(
          'Esta ação é irreversível. Todos os seus dados pessoais, histórico e anúncios cadastrados na ZUVEX serão permanentemente excluídos conforme a Lei Geral de Proteção de Dados (LGPD).',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveService.clearProfile();
              try {
                await AuthController.to.signOut();
              } catch (_) {}
              Get.offAllNamed(AppRoutes.home);
              Get.snackbar(
                'Conta Excluída',
                'Seus dados e anúncios foram removidos conforme solicitado.',
                backgroundColor: AppColors.error,
                colorText: Colors.white,
              );
            },
            child: const Text('Excluir Definitivamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Meu Perfil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Perfil
            Container(
              width: double.infinity,
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.primaryLight,
                    child: _avatarPath.isNotEmpty
                        ? ClipOval(
                            child: Image.asset(
                              _avatarPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppColors.primary),
                            ),
                          )
                        : const Icon(Icons.person, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Promissão – SP',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                            if (_isMasterAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 11, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Seção: Meus Classificados
            _sectionLabel('Classificados'),
            _menuCard(
              isDark: isDark,
              items: [
                _MenuEntry(
                  icon: Iconsax.box,
                  label: 'Meus Anúncios',
                  onTap: () => Get.to(() => const MyAdsView()),
                ),
                _MenuEntry(
                  icon: Iconsax.heart,
                  label: 'Favoritos Salvos',
                  onTap: () => Get.toNamed(AppRoutes.favorites),
                ),
                _MenuEntry(
                  icon: Iconsax.card,
                  label: 'Histórico de Planos e Pix',
                  onTap: () => Get.to(() => const MyAdsView()),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Seção: Administração ZUVEX - EXCLUSIVA PARA devalefdias44@gmail.com
            // Outros usuários NÃO verão esta seção ou botão.
            if (_isMasterAdmin) ...[
              _sectionLabel('Administração Master'),
              _menuCard(
                isDark: isDark,
                items: [
                  _MenuEntry(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Painel Master (Usuários, Pagamentos & Controle)',
                    iconColor: AppColors.primary,
                    onTap: () => Get.to(() => const AdminPanelView()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Seção: Conta e Privacidade (LGPD)
            _sectionLabel('Conta e Privacidade'),
            _menuCard(
              isDark: isDark,
              items: [
                _MenuEntry(
                  icon: Iconsax.edit,
                  label: 'Editar Perfil',
                  onTap: () async {
                    await Get.to(() => const SetupProfileView(isEdit: true));
                    _loadProfile();
                  },
                ),
                _MenuEntry(
                  icon: Icons.policy_rounded,
                  label: 'Política de Privacidade (LGPD)',
                  onTap: () {
                    _showTermsDialog(
                      context,
                      'Política de Privacidade (LGPD)',
                      'A ZUVEX valoriza a sua privacidade. Seus dados são coletados exclusivamente para a publicação de anúncios de classificados locais e intermediação de contato via WhatsApp. Em nenhuma hipótese comercializamos seus dados com terceiros. Você tem o direito de solicitar a alteração ou exclusão definitiva de seus dados a qualquer momento.',
                    );
                  },
                ),
                _MenuEntry(
                  icon: Icons.description_rounded,
                  label: 'Termos de Uso',
                  onTap: () {
                    _showTermsDialog(
                      context,
                      'Termos de Uso ZUVEX',
                      '1. A ZUVEX é uma plataforma de classificados para conectar compradores e vendedores em Promissão e região.\n\n'
                      '2. É expressamente proibido anunciar produtos ilícitos, armas, medicamentos controlados ou aplicar golpes.\n\n'
                      '3. A ZUVEX cobra apenas pela veiculação de anúncios (Planos Básico, Estendido e Destaque). As transações de compra e venda são realizadas diretamente entre as partes.\n\n'
                      '4. Anúncios fraudulentos serão removidos imediatamente e os responsáveis bloqueados.',
                    );
                  },
                ),
                _MenuEntry(
                  icon: Icons.delete_forever_rounded,
                  label: 'Excluir Minha Conta e Dados',
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  onTap: () => _confirmDeleteAccount(context),
                ),
                _MenuEntry(
                  icon: Iconsax.logout,
                  label: 'Sair da Conta',
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  onTap: () => _confirmSignOut(context),
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Versão do App
            Center(
              child: Column(
                children: [
                  const Text(
                    'ZUVEX — Compre e venda perto de você.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Versão 1.0.0 • Promissão - SP',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _menuCard({required List<_MenuEntry> items, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _menuItemWidget(items[i], isLast: i == items.length - 1, isDark: isDark),
        ],
      ),
    );
  }

  Widget _menuItemWidget(_MenuEntry entry, {required bool isLast, required bool isDark}) {
    return Column(
      children: [
        GestureDetector(
          onTap: entry.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 20,
                  color: entry.iconColor ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: entry.labelColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
                if (entry.showChevron)
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 15,
                    color: isDark ? AppColors.textLight.withValues(alpha: 0.5) : AppColors.textLight,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 52,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Deseja sair da sua conta?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Você precisará fazer login novamente para gerenciar ou publicar novos anúncios.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () {
                      Get.back();
                      AuthController.to.signOut();
                    },
                    child: const Text('Sair'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showChevron;

  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.showChevron = true,
  });
}
