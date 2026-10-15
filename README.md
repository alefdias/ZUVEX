<div align="center">

# 🚀 ZUVEX

### Compre e venda perto de você — O marketplace inteligente, rápido e seguro.

Desenvolvido com carinho por **[Alef Dias](https://github.com/alefdias)**

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![GetX](https://img.shields.io/badge/GetX-8B5CF6?style=for-the-badge&logo=getx&logoColor=white)](https://pub.dev/packages/get)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Hive](https://img.shields.io/badge/Hive-FFB300?style=for-the-badge&logo=hive&logoColor=white)](https://pub.dev/packages/hive)
[![Pix BACEN](https://img.shields.io/badge/Pix-00BDAE?style=for-the-badge&logo=pix&logoColor=white)](https://www.bcb.gov.br/estabilidadefinanceira/pix)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

<br/>

[Principais Recursos](#-principais-recursos) •
[Arquitetura](#-arquitetura-e-tecnologias) •
[Fluxos do App](#-fluxos-e-experiência) •
[Instalação](#-como-executar-o-projeto) •
[Autor](#-autor)

</div>

---

## 📱 Sobre o ZUVEX

O **ZUVEX** é uma plataforma moderna e completa de **classificados e marketplace local**, projetada para conectar compradores e vendedores da mesma cidade ou região com extrema velocidade, simplicidade e segurança. 

Diferente de plataformas genéricas, o ZUVEX foca na experiência regional: contato direto via WhatsApp oficial, verificação de vendedores com selos de reputação, pagamento de taxas e destaque via **Pix oficial com padrão BACEN**, e autenticação biométrica nativa para proteger seus dados.

---

## ✨ Principais Recursos

### 🛒 Marketplace & Anúncios
- **Publicação Completa de Anúncios**: Adicione fotos diretamente da **Câmera** ou selecione da **Galeria**, defina título, preço, categoria, cidade e descrição detalhada.
- **Rascunhos de Anúncios**: Não quer pagar ou publicar agora? Salve como rascunho com 1 toque e retome a qualquer momento.
- **Contato Direto via WhatsApp**: Negocie diretamente no WhatsApp do anunciante através do link nativo `wa.me`, sem intermediários desnecessários.
- **Filtro Geográfico & Cidades**: Explore produtos da sua cidade ou filtre por raio de proximidade e regiões.
- **Categorias Inteligentes**: Veículos, Imóveis, Eletrônicos, Moda, Serviços, Empregos e muito mais.

### 💳 Pagamentos Pix Integrados (Padrão Oficial BACEN)
- **Gateway Efí Bank / BotaPix**: Cobranças com conciliação automática.
- **QR Code Dinâmico & Copia e Cola**: Reconhecimento imediato em todos os bancos do Brasil (Nubank, Itaú, Bradesco, Inter, Caixa, Mercado Pago, etc.).
- **Fallback com CRC16 Oficial**: Cálculo matemático de redundância segundo a especificação oficial do Banco Central (`0014BR.GOV.BCB.PIX`).

### 🔒 Segurança & Acesso
- **Autenticação Biométrica**: Bloqueio inteligente por impressão digital (Touch ID / Fingerprint) ou reconhecimento facial (Face ID) gerenciado pelo `local_auth`.
- **Firebase Auth**: Login com e-mail/senha, validação em tempo real e redefinição de senha segura.
- **Selo de Vendedor Verificado**: Transparência e segurança com verificação de identidade e reputação da conta.

### 🎨 Experiência Visual & Design
- **25 Avatares Exclusivos Anti-Plágio**: Avatares modernos, coloridos e customizados em alta definição (512x512).
- **Interface Fluida & Responsiva**: Design pensado em micro-interações, estados de carregamento (shimmers), bottom sheet nativo e suporte a temas.
- **Modo Offline-First com Hive**: Cache instantâneo de anúncios, favoritos e perfil do usuário para abertura sem atrasos.

---

## 🛠️ Arquitetura e Tecnologias

O projeto utiliza o padrão de arquitetura **MVC com GetX**, priorizando modularidade, testabilidade e separação de responsabilidades.

| Tecnologia | Descrição / Uso |
|---|---|
| **Flutter 3.x & Dart** | Framework multiplataforma de alta performance |
| **GetX** | Gerenciamento de estado reativo, injeção de dependências e roteamento |
| **Firebase Auth** | Gerenciamento seguro de sessões e usuários |
| **Cloud Firestore** | Banco de dados NoSQL em tempo real para anúncios, chats e perfis |
| **Firebase Storage** | Armazenamento em nuvem de fotos de alta resolução dos anúncios |
| **Hive & Hive Flutter** | Armazenamento local leve e ultrarrápido para dados em cache e offline |
| **Local Auth** | Autenticação biométrica nativa (Biometria / Face Unlock) |
| **BotaPix / Efí Bank** | API de geração e leitura de pagamentos Pix BACEN |
| **Image Picker** | Captura de fotos via Câmera e seleção da Galeria |
| **URL Launcher** | Abertura direta de links de WhatsApp e telefones |

---

## 📂 Estrutura de Pastas

```bash
lib/
├── app/
│   ├── bindings.dart               # Injeção de dependências GetX
│   ├── routes.dart                 # Rotas nomeadas do aplicativo
│   └── theme.dart                  # Paleta de cores, tipografia e temas
├── data/
│   ├── models/
│   │   ├── ad_model.dart           # Modelo de Anúncio (preço, fotos, whatsapp, status)
│   │   ├── city_model.dart         # Cidades e regiões atendidas
│   │   ├── product_model.dart      # Modelos de produtos e itens
│   │   └── user_model.dart         # Modelo de usuário e perfil
│   ├── providers/                  # Provedores de API e serviços externos
│   └── services/
│       ├── firebase_service.dart   # Integrações com Firestore, Auth e Storage
│       ├── hive_service.dart       # Persistência local offline
│       └── payment_service.dart    # Motor de Pix BACEN (QR Code, CRC16)
├── modules/
│   ├── auth/                       # Login, Cadastro, Recuperação e Biometria
│   ├── home/                       # Feed principal, filtros, busca e categorias
│   ├── ads/                        # Criação, rascunhos, detalhes e edição de anúncios
│   ├── checkout/                   # Telas de pagamento Pix com QR Code
│   ├── favorites/                  # Anúncios salvos pelo usuário
│   ├── profile/                    # Perfil, escolha de avatar, meus anúncios e configurações
│   └── splash/                     # Splash screen com verificação de sessão e biometria
├── widgets/                        # Componentes reutilizáveis (cards, botões, modais)
├── firebase_options.dart           # Configurações do Firebase
└── main.dart                       # Ponto de entrada da aplicação
```

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado (versão 3.x+)
- [Dart SDK](https://dart.dev/get-dart)
- Dispositivo físico ou Emulador Android/iOS configurado
- Projeto Firebase configurado com Authentication, Firestore e Storage

### Passo a Passo

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/alefdias/ZUVEX.git
   cd ZUVEX
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Gere os adaptadores do Hive (se necessário):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Execute o aplicativo:**
   ```bash
   flutter run
   ```

### Gerar APK de Produção

```bash
flutter build apk --release
```

O arquivo gerado estará disponível em `build/app/outputs/flutter-apk/app-release.apk`.

---

## 👨‍💻 Autor

<div align="center">

**Alef Dias**  
*Desenvolvedor de Software & Criador do ZUVEX*

[![GitHub](https://img.shields.io/badge/GitHub-alefdias-181717?style=flat-square&logo=github)](https://github.com/alefdias)
[![Repository](https://img.shields.io/badge/Repositório-ZUVEX-blue?style=flat-square&logo=git)](https://github.com/alefdias/ZUVEX)

</div>

---

## 📄 Licença

Este projeto é distribuído sob a licença **MIT**. Consulte o arquivo [LICENSE](LICENSE) para obter mais informações.

Copyright © 2026 **Alef Dias**. Todos os direitos reservados.
