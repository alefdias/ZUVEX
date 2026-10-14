import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../data/models/category_model.dart';
import '../../data/models/city_model.dart';
import '../../widgets/ad_card.dart';
import 'create_ad_controller.dart';

class CreateAdView extends StatelessWidget {
  const CreateAdView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CreateAdController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Publicar Anúncio'),
        actions: [
          TextButton(
            onPressed: () => ctrl.resetForm(),
            child: const Text('Limpar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: Obx(() {
        final step = ctrl.currentStep.value;

        return Column(
          children: [
            // Indicador de Progresso
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              child: Row(
                children: [
                  _StepIndicator(index: 1, label: 'Dados', active: step == 0, completed: step > 0),
                  _StepDivider(completed: step > 0),
                  _StepIndicator(index: 2, label: 'Prévia', active: step == 1, completed: step > 1),
                  _StepDivider(completed: step > 1),
                  _StepIndicator(index: 3, label: 'Plano', active: step == 2, completed: step > 2),
                  _StepDivider(completed: step > 2),
                  _StepIndicator(index: 4, label: 'Pix', active: step == 3, completed: false),
                ],
              ),
            ),

            // Conteúdo da Etapa
            Expanded(
              child: IndexedStack(
                index: step,
                children: [
                  _Step0Form(ctrl: ctrl),
                  _Step1Preview(ctrl: ctrl),
                  _Step2Plans(ctrl: ctrl),
                  _Step3Payment(ctrl: ctrl),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Step0Form extends StatelessWidget {
  final CreateAdController ctrl;
  const _Step0Form({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Categoria
          const Text('1. Categoria *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Obx(() {
            return DropdownButtonFormField<CategoryModel>(
              value: ctrl.selectedCategory.value,
              hint: const Text('Escolha a categoria do anúncio'),
              items: CategoryModel.allCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(cat.title),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat != null) ctrl.setCategory(cat);
              },
            );
          }),
          const SizedBox(height: 18),

          // Campos Específicos da Categoria
          Obx(() {
            final cat = ctrl.selectedCategory.value;
            if (cat == null || cat.specificFields.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Detalhes Específicos: ${cat.title}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cat.specificFields.map((field) {
                    if (field.options != null && field.options!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: '${field.label}${field.required ? ' *' : ''}'),
                          items: field.options!.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                          onChanged: (val) => ctrl.setDynamicField(field.id, val),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        keyboardType: field.keyboardType,
                        decoration: InputDecoration(labelText: '${field.label}${field.required ? ' *' : ''}'),
                        onChanged: (val) => ctrl.setDynamicField(field.id, val),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          // 2. Título
          const Text('2. Título do Anúncio *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.titleController,
            decoration: const InputDecoration(
              hintText: 'Ex: Gol 1.6 Flex Completo ou iPhone 14 Pro',
            ),
          ),
          const SizedBox(height: 18),

          // 3. Descrição
          const Text('3. Descrição Completa *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Descreva os detalhes, estado de conservação, acessórios e formas de negociação.',
            ),
          ),
          const SizedBox(height: 18),

          // 4. Preço
          const Text('4. Preço (R\$) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Ex: 1500 (ou deixe 0 para "A combinar")',
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: 18),

          // 5. Fotos (Até 10)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('5. Fotos (Até 10) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Obx(() => Text('${ctrl.selectedImages.length}/10 adicionadas', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...ctrl.selectedImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Icon(Icons.image_rounded, color: AppColors.primary),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => ctrl.removeImage(entry.key),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.error,
                            child: Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (ctrl.selectedImages.length < 10)
                  GestureDetector(
                    onTap: () => ctrl.pickImages(),
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
                          SizedBox(height: 3),
                          Text('Foto', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 18),

          // 6. Cidade e Bairro
          const Text('6. Localização *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Obx(() {
            return DropdownButtonFormField<CityModel>(
              value: ctrl.selectedCity.value,
              decoration: const InputDecoration(labelText: 'Cidade'),
              items: ctrl.availableCities.map((c) {
                return DropdownMenuItem(value: c, child: Text(c.displayName));
              }).toList(),
              onChanged: (c) {
                if (c != null) ctrl.selectedCity.value = c;
              },
            );
          }),
          const SizedBox(height: 10),
          TextFormField(
            controller: ctrl.districtController,
            decoration: const InputDecoration(
              labelText: 'Bairro',
              hintText: 'Ex: Centro, Jardim das Flores, etc.',
            ),
          ),
          const SizedBox(height: 18),

          // 7. Telefone de Contato e WhatsApp
          const Text('7. Contato para Venda *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl.phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone / WhatsApp com DDD',
              hintText: 'Ex: 14998765432',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Permitir contato direto via WhatsApp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Compradores verão o botão "Conversar com vendedor"', style: TextStyle(fontSize: 12)),
              value: ctrl.allowWhatsApp.value,
              activeColor: AppColors.whatsapp,
              onChanged: (val) => ctrl.allowWhatsApp.value = val,
            );
          }),
          const SizedBox(height: 24),

          // Botão Continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ctrl.proceedToPreview(),
              child: const Text('Ver Prévia do Anúncio'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Step1Preview extends StatelessWidget {
  final CreateAdController ctrl;
  const _Step1Preview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como seu anúncio aparecerá na ZUVEX:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final ad = ctrl.createdAd.value;
            if (ad == null) return const SizedBox.shrink();

            return Center(
              child: SizedBox(
                width: 260,
                child: AdCard(ad: ad),
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ctrl.currentStep.value = 0,
                  child: const Text('Editar Dados'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ctrl.proceedToPlanSelection(),
                  child: const Text('Escolher Plano'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step2Plans extends StatelessWidget {
  final CreateAdController ctrl;
  const _Step2Plans({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha o plano de publicação',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'A validade do anúncio começa após a confirmação do pagamento.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 18),

          // Cards dos Planos (Básico, Estendido, Destaque)
          Obx(() {
            return Column(
              children: ctrl.availablePlans.map((plan) {
                final isSelected = ctrl.selectedPlan.value.id == plan.id;

                return GestureDetector(
                  onTap: () => ctrl.selectedPlan.value = plan,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? (plan.isFeatured ? AppColors.featured : AppColors.primary)
                            : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: (plan.isFeatured ? AppColors.featured : AppColors.primary).withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (plan.isFeatured) ...[
                                  const Icon(Icons.star_rounded, color: AppColors.featured, size: 20),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  plan.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: plan.isFeatured ? AppColors.featured : null,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              plan.formattedPrice,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const Divider(height: 20),
                        ...plan.benefits.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Expanded(child: Text(b, style: const TextStyle(fontSize: 12.5))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ctrl.currentStep.value = 1,
                  child: const Text('Voltar à Prévia'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  return ElevatedButton(
                    onPressed: ctrl.isSubmitting.value ? null : () => ctrl.proceedToPayment(),
                    child: ctrl.isSubmitting.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Pagar com Pix'),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Step3Payment extends StatelessWidget {
  final CreateAdController ctrl;
  const _Step3Payment({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Obx(() {
        final tx = ctrl.currentTransaction.value;
        if (tx == null) return const Center(child: CircularProgressIndicator());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Badge BotaPix & Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Pagamento Automático via BotaPix',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              tx.formattedAmount,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Plano: ${tx.planName}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 18),

            // QR Code Pix do BotaPix
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Image.network(
                tx.pixQrCode,
                width: 200,
                height: 200,
                errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, size: 190, color: AppColors.graphite),
              ),
            ),
            const SizedBox(height: 16),

            // Status ao vivo de escuta do Pix
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Aguardando Pix... Liberação automática ativa!',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Botão Copiar Pix
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: tx.pixCopiaECola));
                Get.snackbar(
                  'Copiado!',
                  'Código Pix copiado! Cole no aplicativo do seu banco.',
                  backgroundColor: AppColors.primary,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copiar Código Pix (Copia e Cola)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            // Botão para abrir o link de pagamento BotaPix se disponível
            if (tx.paymentUrl != null && tx.paymentUrl!.startsWith('http')) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(tx.paymentUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Abrir Página do BotaPix no Navegador'),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              'Assim que você pagar no app do seu banco, o BotaPix identifica o valor e seu anúncio é ATIVADO NA HORA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const Divider(height: 28),

            // Botão Verificar Agora
            Obx(() {
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
                onPressed: ctrl.isCheckingPix.value
                    ? null
                    : () => ctrl.checkPaymentStatusNow(),
                icon: ctrl.isCheckingPix.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Já Paguei — Verificar Agora', style: TextStyle(fontWeight: FontWeight.bold)),
              );
            }),

            const SizedBox(height: 12),
            // Opção de simulação para desenvolvimento/testes
            TextButton(
              onPressed: ctrl.isSubmitting.value ? null : () => ctrl.confirmPaymentSimulation(),
              child: Text(
                'Simular Pagamento Aprovado (Modo Teste)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      }),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final bool completed;

  const _StepIndicator({
    required this.index,
    required this.label,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.dividerLight;
    Color fg = AppColors.textLight;

    if (active) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (completed) {
      bg = AppColors.success;
      fg = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: bg,
          child: completed
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$index', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  final bool completed;
  const _StepDivider({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: completed ? AppColors.success : AppColors.dividerLight,
      ),
    );
  }
}
