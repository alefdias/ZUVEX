# 🛡️ ZUVEX — Backend de Pagamentos & Webhooks Pix

Backend Node.js/Express seguro e compatível com **Firebase Cloud Functions** e **Google Cloud Run**.

---

## 🔒 Por que usar este backend?
1. **Proteção da Chave de API:** A chave secreta do BotaPix (`btpx_...`) fica **100% no servidor**, isolada em variáveis de ambiente. Nenhum usuário ou invasor consegue extraí-la através de engenharia reversa do APK do aplicativo.
2. **Webhooks Oficiais em Tempo Real:** O BotaPix avisa este backend instantaneamente via HTTP POST assim que o Pix é pago, ativando o anúncio no Firestore na hora sem depender de polling do celular.
3. **Persistência Centralizada:** As transações são registradas na coleção `transactions` do Firestore, alimentando em tempo real o **Painel Administrativo do ZUVEX**.

---

## 🚀 Como Iniciar Localmente

```bash
cd backend
npm install
cp .env.example .env
npm start
```

O servidor iniciará em `http://localhost:3000`.

---

## 🌐 Endpoints Disponíveis

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/health` | Verificação de saúde da API |
| `POST` | `/api/create-pix` | Cria cobrança Pix segura no BotaPix e salva no Firestore |
| `GET` | `/api/status/:id` | Consulta status da cobrança Pix no BotaPix |
| `POST` | `/api/webhook` | Recebe a notificação de pagamento do BotaPix e ativa o anúncio |

---

## ☁️ Como Publicar na Nuvem

### Opção 1: Google Cloud Run (Recomendado com Firebase)
```bash
gcloud run deploy zuvex-backend \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars BOTAPIX_API_KEY="sua_chave_aqui",MASTER_PIX_KEY="devalefdias44@gmail.com"
```

### Opção 2: Render / Railway
Basta conectar o repositório e configurar as variáveis de ambiente:
- `BOTAPIX_API_KEY`
- `MASTER_PIX_KEY`

---

## 📱 Conectar o App Flutter ao Backend

Ao compilar o app Flutter ou no build do GitHub Actions, basta passar:
```bash
flutter build apk --release --dart-define=BACKEND_URL=https://seu-backend.run.app
```
O aplicativo automaticamente delegará todas as cobranças e consultas ao backend, mantendo 0 credenciais no código-fonte do cliente!
