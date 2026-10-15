import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/models/ad_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/city_model.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/payment_service.dart';

class CreateAdController extends GetxController {
  static CreateAdController get to => Get.find();

  // Etapa atual do assistente (0 a 3)
  // 0: Dados do Anúncio
  // 1: Pré-visualização
  // 2: Escolha do Plano
  // 3: Pagamento Pix BotaPix (com liberação automática)
  final currentStep = 0.obs;

  // Campos do Formulário
  final selectedCategory = Rxn<CategoryModel>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final districtController = TextEditingController();
  final phoneController = TextEditingController();
  final allowWhatsApp = true.obs;

  final selectedCity = CityModel.promissao.obs;
  final availableCities = CityModel.defaultCities.obs;

  final dynamicFieldValues = <String, dynamic>{}.obs;

  // Imagens (até 10)
  final selectedImages = <XFile>[].obs;
  final picker = ImagePicker();

  // Monetização
  final availablePlans = PlanModel.defaultPlans.obs;
  final selectedPlan = PlanModel.basic.obs;
  final currentTransaction = Rxn<PaymentTransactionModel>();
  final createdAd = Rxn<AdModel>();

  final isSubmitting = false.obs;
  final isCheckingPix = false.obs;

  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    phoneController.text = '';
    districtController.text = '';
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Tirar foto agora usando a Câmera
  Future<void> pickImageFromCamera() async {
    if (selectedImages.length >= 10) {
      Get.snackbar('Limite atingido', 'Você já selecionou o limite máximo de 10 fotografias.');
      return;
    }

    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (photo != null) {
        selectedImages.add(photo);
      }
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível acessar a câmera do dispositivo.');
    }
  }

  /// Escolher fotos da Galeria (Uploads)
  Future<void> pickImagesFromGallery() async {
    if (selectedImages.length >= 10) {
      Get.snackbar('Limite atingido', 'Você já selecionou o limite máximo de 10 fotografias.');
      return;
    }

    try {
      final list = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      final remaining = 10 - selectedImages.length;
      if (list.length > remaining) {
        selectedImages.addAll(list.take(remaining));
        Get.snackbar('Aviso', 'Adicionadas apenas as primeiras $remaining fotos para não ultrapassar 10.');
      } else {
        selectedImages.addAll(list);
      }
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível selecionar fotos da galeria.');
    }
  }

  /// Atalho compatível com chamadas legadas
  Future<void> pickImages() async => pickImagesFromGallery();

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  void setCategory(CategoryModel cat) {
    selectedCategory.value = cat;
    dynamicFieldValues.clear();
  }

  void setDynamicField(String fieldId, dynamic value) {
    if (value != null) {
      dynamicFieldValues[fieldId] = value;
    } else {
      dynamicFieldValues.remove(fieldId);
    }
  }

  void proceedToPreview() {
    if (selectedCategory.value == null) {
      Get.snackbar('Campo obrigatório', 'Por favor, selecione uma categoria.');
      return;
    }

    if (titleController.text.trim().length < 5) {
      Get.snackbar('Título muito curto', 'Digite um título com ao menos 5 caracteres.');
      return;
    }

    final price = double.tryParse(priceController.text.replaceAll('.', '').replaceAll(',', '.'));
    if (price == null || price < 0) {
      Get.snackbar('Preço inválido', 'Informe um valor numérico válido.');
      return;
    }

    if (districtController.text.trim().isEmpty) {
      Get.snackbar('Bairro obrigatório', 'Informe o bairro onde o item está localizado.');
      return;
    }

    // Validação estrita de WhatsApp obrigatório
    final rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.length < 10) {
      Get.snackbar(
        'WhatsApp Obrigatório',
        'Informe o seu número de WhatsApp com DDD (mínimo 10 dígitos) para contato.',
        backgroundColor: const Color(0xFFE11D48),
        colorText: Colors.white,
      );
      return;
    }

    final user = FirebaseService.currentUid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userName = HiveService.name.isNotEmpty ? HiveService.name : 'Anunciante ZUVEX';
    final userEmail = FirebaseService.currentEmail ?? HiveService.email;

    final ad = AdModel(
      id: '',
      userId: user,
      userName: userName,
      userEmail: userEmail.isNotEmpty ? userEmail : 'devalefdias44@gmail.com',
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      price: price,
      categoryId: selectedCategory.value!.id,
      images: selectedImages.map((e) => e.path).toList(),
      cityId: selectedCity.value.id,
      cityName: selectedCity.value.displayName,
      district: districtController.text.trim(),
      contactPhone: rawPhone,
      allowWhatsApp: true,
      planId: selectedPlan.value.id,
      isFeatured: selectedPlan.value.isFeatured,
      status: AdStatus.draft,
      specificFields: Map<String, dynamic>.from(dynamicFieldValues),
      createdAt: DateTime.now(),
    );

    createdAd.value = ad;
    currentStep.value = 1; // Passo 1: Pré-visualização
  }

  void proceedToPlanSelection() {
    currentStep.value = 2; // Passo 2: Escolha de Plano
  }

  /// Salvar Anúncio como Rascunho para pagar e ativar depois
  Future<void> saveDraftPayLater() async {
    isSubmitting.value = true;
    try {
      final ad = createdAd.value;
      if (ad == null) return;
      final plan = selectedPlan.value;

      final draftAd = ad.copyWith(
        planId: plan.id,
        isFeatured: plan.isFeatured,
        status: AdStatus.draft,
      );

      final adId = await AdService.createAd(draftAd);
      createdAd.value = draftAd.copyWith(id: adId);

      Get.defaultDialog(
        title: '📝 Rascunho Salvo!',
        titleStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        middleText:
            'Seu anúncio foi salvo como rascunho com sucesso!\nVocê pode visualizá-lo e pagar o Pix para ativá-lo a qualquer momento em "Meus Anúncios".',
        middleTextStyle: const TextStyle(fontSize: 14, height: 1.4),
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            Get.back(); // fecha diálogo
            resetForm();
            Get.offAllNamed(AppRoutes.home);
          },
          child: const Text('OK, Entendido', style: TextStyle(color: Colors.white)),
        ),
        barrierDismissible: false,
      );
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível salvar o rascunho.');
    } finally {
      isSubmitting.value = false;
    }
  }

  // Gera a cobrança Pix via BotaPix e inicia verificação automática
  Future<void> proceedToPayment() async {
    isSubmitting.value = true;
    try {
      final ad = createdAd.value!;
      final plan = selectedPlan.value;

      final savedAd = ad.copyWith(
        planId: plan.id,
        isFeatured: plan.isFeatured,
        status: AdStatus.pendingPayment,
      );

      final adId = await AdService.createAd(savedAd);
      createdAd.value = savedAd.copyWith(id: adId);

      // Cria a cobrança real na API BotaPix
      final tx = await PaymentService.instance.createPixCharge(
        ad: createdAd.value!,
        plan: plan,
        userEmail: savedAd.userEmail,
      );

      currentTransaction.value = tx;
      currentStep.value = 3; // Passo 3: Pagamento Pix

      // Inicia verificação automática periódica com o BotaPix
      startBotaPixPolling(tx.botaPixChargeId ?? tx.id);
    } catch (_) {
      Get.snackbar('Erro', 'Não foi possível gerar a cobrança Pix. Tente novamente.');
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Polling automático: verifica se o Pix foi pago no BotaPix a cada 4 segundos
  void startBotaPixPolling(String chargeId) {
    stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      await _checkStatusInternal(chargeId, isSilent: true);
    });
  }

  /// Verificação manual disparada pelo botão "Verificar Pagamento Agora"
  Future<void> checkPaymentStatusNow() async {
    final tx = currentTransaction.value;
    if (tx == null) return;
    isCheckingPix.value = true;
    try {
      await _checkStatusInternal(tx.botaPixChargeId ?? tx.id, isSilent: false);
    } finally {
      isCheckingPix.value = false;
    }
  }

  Future<void> _checkStatusInternal(String chargeId, {required bool isSilent}) async {
    final status = await PaymentService.instance.checkPaymentStatus(chargeId);
    if (status == PaymentStatus.confirmed) {
      stopPolling();
      await _activateAdSuccess();
    } else if (!isSilent) {
      Get.snackbar(
        'Aguardando Pagamento',
        'O BotaPix ainda não detectou o pagamento. Assim que concluir no seu banco, a liberação é automática!',
        backgroundColor: Colors.amber.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Ativação do anúncio quando o pagamento BotaPix é confirmado
  Future<void> _activateAdSuccess() async {
    final tx = currentTransaction.value;
    final ad = createdAd.value;

    if (tx != null && ad != null) {
      await PaymentService.instance.confirmPaymentAndActivate(
        transactionId: tx.id,
        adId: ad.id,
        durationDays: selectedPlan.value.durationDays,
      );

      // Ativa o selo de Vendedor Verificado via Pix no perfil
      await HiveService.setPixVerified(true);

      Get.defaultDialog(
        title: '🎉 Pagamento Aprovado!',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
        middleText:
            'O BotaPix confirmou o pagamento com sucesso!\nSeu anúncio já está no ar com o selo 🛡️ Vendedor Verificado via Pix!',
        middleTextStyle: const TextStyle(fontSize: 14, height: 1.4),
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
          onPressed: () {
            Get.back(); // fecha diálogo
            resetForm();
            Get.offAllNamed(AppRoutes.home);
          },
          child: const Text('Ver Meus Anúncios', style: TextStyle(color: Colors.white)),
        ),
        barrierDismissible: false,
      );
    }
  }

  /// Confirmação para ambiente de teste
  Future<void> confirmPaymentSimulation() async {
    isSubmitting.value = true;
    try {
      stopPolling();
      await _activateAdSuccess();
    } catch (_) {
      Get.snackbar('Erro', 'Ocorreu um problema ao confirmar. Tente novamente.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetForm() {
    stopPolling();
    currentStep.value = 0;
    selectedCategory.value = null;
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    districtController.clear();
    phoneController.clear();
    selectedImages.clear();
    dynamicFieldValues.clear();
    currentTransaction.value = null;
    createdAd.value = null;
    selectedPlan.value = PlanModel.basic;
  }
}
