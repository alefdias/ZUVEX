import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../data/models/ad_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/report_model.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/firebase_service.dart';
import '../favorites/favorites_controller.dart';

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late final AdModel ad;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    ad = Get.arguments as AdModel;
    AdService.incrementViews(ad.id);
  }

  Future<void> _openWhatsApp() async {
    final cleanPhone = ad.contactPhone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.startsWith('55') ? cleanPhone : '55$cleanPhone';

    final text = 'Olá! Vi seu anúncio "${ad.title}" na ZUVEX e gostaria de saber se ainda está disponível.';
    final whatsappUrl = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'WhatsApp não disponível',
          'Não foi possível abrir o WhatsApp no seu dispositivo.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Erro ao abrir',
        'Verifique se o aplicativo do WhatsApp está instalado.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _shareAd() {
    Share.share(
      'Confira este anúncio na ZUVEX: ${ad.title} por ${ad.formattedPrice} em ${ad.cityName}!\n'
      'https://zuvex.com.br/anuncio/${ad.id}',
    );
  }

  void _showReportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedReason = 'Golpe ou Fraude';
    final detailsCtrl = TextEditingController();

    final reasons = [
      'Golpe ou Fraude',
      'Produto Proibido',
      'Informações Falsas ou Enganosas',
      'Preço Irreal ou Abusivo',
      'Spam ou Anúncio Duplicado',
      'Conteúdo Ofensivo',
      'Outro',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Denunciar Anúncio', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecione o motivo da denúncia:', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Detalhes adicionais (opcional):', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: detailsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Descreva brevemente o problema...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () async {
                    final report = ReportModel(
                      id: '',
                      adId: ad.id,
                      adTitle: ad.title,
                      reportedUserId: ad.userId,
                      reporterUserId: FirebaseService.currentUid ?? 'anonimo',
                      reporterEmail: FirebaseService.currentEmail ?? 'anonimo',
                      reason: selectedReason,
                      details: detailsCtrl.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await AdService.createReport(report);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Get.snackbar(
                      'Denúncia Enviada',
                      'Obrigado. Nossa equipe de moderação irá analisar o anúncio.',
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text('Enviar Denúncia'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = ad.images.isNotEmpty ? ad.images : [ad.primaryImage];
    final category = CategoryModel.findById(ad.categoryId);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // AppBar com Galeria de Imagens
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    onPressed: _shareAd,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Obx(() {
                  bool isFav = false;
                  try {
                    isFav = FavoritesController.to.isAdFavorite(ad.id);
                  } catch (_) {}

                  return CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Iconsax.heart5 : Iconsax.heart,
                        color: isFav ? AppColors.error : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        try {
                          FavoritesController.to.toggleAdFavorite(ad);
                        } catch (_) {}
                      },
                    ),
                  );
                }),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? const Color(0xFF2D2F3E) : const Color(0xFFE5E7EB),
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? const Color(0xFF2D2F3E) : const Color(0xFFE5E7EB),
                          child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                  ),

                  // Indicador de fotos (ex: 1/4)
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Selo de Destaque
                  if (ad.isFeatured)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ANÚNCIO DESTAQUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Conteúdo do Anúncio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preço
                  Text(
                    ad.formattedPrice,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.white : AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Título
                  Text(
                    ad.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Data e visualizações
                  Row(
                    children: [
                      Icon(Iconsax.clock, size: 14, color: isDark ? AppColors.textLight : AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        'Publicado em ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(ad.createdAt)}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLight : AppColors.textSecondaryLight),
                      ),
                      const Spacer(),
                      Icon(Iconsax.eye, size: 14, color: isDark ? AppColors.textLight : AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        '${ad.viewsCount} visualizações',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLight : AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Localização
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.location5, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ad.district}, ${ad.cityName}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Promissão – SP e Região',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ficha Técnica / Campos Específicos da Categoria
                  if (ad.specificFields.isNotEmpty) ...[
                    Text(
                      'Detalhes do Item (${category.title})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                      ),
                      child: Column(
                        children: ad.specificFields.entries.map((entry) {
                          final label = entry.key[0].toUpperCase() + entry.key.substring(1).replaceAll('_', ' ');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(label, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13)),
                                Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Descrição
                  const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    child: Text(
                      ad.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Perfil do Anunciante
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight,
                              child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          ad.userName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (ad.isPixVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Anunciante na ZUVEX',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (ad.isPixVerified) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Vendedor Verificado via Pix (Conta bancária autenticada)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aviso de Segurança Contra Golpes
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.security_rounded, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dicas de Segurança ZUVEX',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Nunca faça pagamentos antecipados antes de ver o item pessoalmente.\n'
                                '• Prefira locais públicos e movimentados para encontrar o vendedor.\n'
                                '• A ZUVEX não intermedeia pagamentos entre usuários.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.amber.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão de Denunciar Anúncio
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showReportDialog(context),
                      icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
                      label: const Text(
                        'Denunciar este anúncio',
                        style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 90), // Espaço para a barra inferior
                ],
              ),
            ),
          ),
        ],
      ),

      // Barra Inferior com Botão WhatsApp
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsapp,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: ad.allowWhatsApp ? _openWhatsApp : null,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                  label: Text(
                    ad.allowWhatsApp ? 'Conversar com vendedor' : 'Contato não disponível',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
