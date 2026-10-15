require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const admin = require('firebase-admin');

// Inicialização do Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
  console.log('✅ Firebase Admin inicializado');
} catch (e) {
  try {
    admin.initializeApp();
    console.log('✅ Firebase Admin inicializado com credenciais padrão');
  } catch (err) {
    console.warn('⚠️ Firebase Admin inicializado em modo offline/sem credenciais de serviço');
  }
}

const db = admin.firestore ? admin.firestore() : null;

const app = express();
app.use(cors());
app.use(express.json());

const BOTAPIX_API_KEY = process.env.BOTAPIX_API_KEY || 'btpx_5a17bdc85093c45ad64c995b8f3b4800969d1f36abc3eb9a3b7bb490';
const BOTAPIX_BASE_URL = process.env.BOTAPIX_BASE_URL || 'https://botapix.com/api/v1';
const MASTER_PIX_KEY = process.env.MASTER_PIX_KEY || 'devalefdias44@gmail.com';
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'ZUVEX Payment Backend', timestamp: new Date().toISOString() });
});

// 1. Criar Cobrança Pix Segura (Chaves protegidas no servidor)
app.post('/api/create-pix', async (req, res) => {
  try {
    const { adId, adTitle, planId, planName, amount, userEmail, userName, contactPhone, durationDays } = req.body;

    if (!adId || !amount) {
      return res.status(400).json({ error: 'adId e amount são obrigatórios.' });
    }

    const amountInCents = Math.max(100, Math.round(Number(amount) * 100));
    const externalRef = `zuvex_ad_${adId}_${Date.now()}`;

    const clientName = (userName || 'Usuario ZUVEX').trim();
    const clientEmail = (userEmail || MASTER_PIX_KEY).trim();
    const clientPhone = (contactPhone || '').trim();

    const desc = `ZUVEX | ${clientName}${clientPhone ? ` | Tel: ${clientPhone}` : ''} | ${clientEmail} - ${planName || 'Plano'} (${adTitle || adId})`;
    const cleanDesc = desc.substring(0, 250);

    // Chama o gateway BotaPix com a chave segura do backend
    const botapixRes = await axios.post(
      `${BOTAPIX_BASE_URL}/charges`,
      {
        amount: amountInCents,
        external_reference: externalRef,
        description: cleanDesc,
        expiration: 3600,
        customer: {
          name: clientName,
          email: clientEmail,
          ...(clientPhone ? { phone: clientPhone } : {}),
        },
      },
      {
        headers: {
          'Authorization': `Bearer ${BOTAPIX_API_KEY}`,
          'Content-Type': 'application/json',
          'User-Agent': USER_AGENT,
          'Idempotency-Key': externalRef,
        },
        timeout: 10000,
      }
    );

    const chargeData = botapixRes.data?.data || {};
    const chargeId = chargeData.id || externalRef;
    const pixCopiaECola = chargeData.pix?.payload || chargeData.pix_copy_paste || '';
    const pixQrCode = chargeData.pix?.qr_code || chargeData.payment_url || '';
    const qrCodeBase64 = chargeData.pix?.qr_code_base64 || '';

    // Salva a transação diretamente no Firestore sob a coleção 'transactions'
    if (db) {
      await db.collection('transactions').doc(chargeId).set({
        id: chargeId,
        adId: adId,
        adTitle: adTitle || '',
        planId: planId || '',
        planName: planName || '',
        amount: Number(amount),
        status: 'pending',
        userEmail: clientEmail,
        pixKey: MASTER_PIX_KEY,
        qrCode: pixQrCode,
        qrCodeBase64: qrCodeBase64,
        copyPaste: pixCopiaECola,
        durationDays: durationDays || 30,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ [Backend] Transação criada no Firestore: ${chargeId} (${clientEmail} - R$ ${amount})`);
    }

    return res.json({
      success: true,
      transactionId: chargeId,
      copyPaste: pixCopiaECola,
      qrCodeUrl: pixQrCode,
      qrCodeBase64: qrCodeBase64,
      amount: Number(amount),
      expiresInSeconds: 3600,
    });

  } catch (error) {
    console.error('❌ [Backend] Erro ao criar cobrança Pix:', error.response?.data || error.message);
    return res.status(500).json({
      error: 'Erro ao gerar cobrança Pix no gateway.',
      details: error.response?.data || error.message,
    });
  }
});

// 2. Consultar Status da Cobrança Pix
app.get('/api/status/:chargeId', async (req, res) => {
  try {
    const { chargeId } = req.params;

    // Primeiro consulta o Firestore
    if (db) {
      const doc = await db.collection('transactions').doc(chargeId).get();
      if (doc.exists && doc.data().status === 'confirmed') {
        return res.json({ status: 'confirmed' });
      }
    }

    // Consulta no gateway BotaPix
    const botapixRes = await axios.get(`${BOTAPIX_BASE_URL}/charges/${chargeId}`, {
      headers: {
        'Authorization': `Bearer ${BOTAPIX_API_KEY}`,
        'Content-Type': 'application/json',
        'User-Agent': USER_AGENT,
      },
      timeout: 8000,
    });

    const data = botapixRes.data?.data || {};
    const status = (data.status || '').toLowerCase();

    if (status === 'paid') {
      // Confirma e ativa no Firestore
      if (db) {
        const doc = await db.collection('transactions').doc(chargeId).get();
        if (doc.exists) {
          const txData = doc.data();
          const batch = db.batch();

          batch.update(db.collection('transactions').doc(chargeId), {
            status: 'confirmed',
            confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          if (txData.adId) {
            const duration = txData.durationDays || 30;
            const expires = new Date();
            expires.setDate(expires.getDate() + duration);

            batch.update(db.collection('ads').doc(txData.adId), {
              status: 'active',
              isPixVerified: true,
              expiresAt: admin.firestore.Timestamp.fromDate(expires),
            });
          }

          await batch.commit();
          console.log(`🎉 [Backend] Transação ${chargeId} confirmada e anúncio ${txData.adId} ativado!`);
        }
      }
      return res.json({ status: 'confirmed' });
    }

    return res.json({ status: status === 'expired' ? 'expired' : 'pending' });

  } catch (error) {
    console.warn(`⚠️ [Backend] Consulta status de ${req.params.chargeId}:`, error.message);
    return res.json({ status: 'pending' });
  }
});

// 3. Webhook Oficial BotaPix (Notificação Instantânea Push)
app.post('/api/webhook', async (req, res) => {
  try {
    const event = req.body;
    console.log('🔔 [Backend] Webhook Pix Recebido:', JSON.stringify(event));

    const chargeId = event.data?.id || event.id || event.charge_id;
    const status = (event.data?.status || event.status || '').toLowerCase();

    if (status === 'paid' && chargeId && db) {
      const doc = await db.collection('transactions').doc(chargeId).get();
      if (doc.exists) {
        const txData = doc.data();
        const batch = db.batch();

        batch.update(db.collection('transactions').doc(chargeId), {
          status: 'confirmed',
          confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (txData.adId) {
          const duration = txData.durationDays || 30;
          const expires = new Date();
          expires.setDate(expires.getDate() + duration);

          batch.update(db.collection('ads').doc(txData.adId), {
            status: 'active',
            isPixVerified: true,
            expiresAt: admin.firestore.Timestamp.fromDate(expires),
          });
        }

        await batch.commit();
        console.log(`🚀 [Webhook] Pagamento Pix aprovado! Anúncio ${txData.adId} ativado com sucesso.`);
      }
    }

    return res.status(200).json({ received: true });
  } catch (err) {
    console.error('❌ [Webhook] Erro no processamento:', err);
    return res.status(500).json({ error: 'Erro no processamento do webhook' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 ZUVEX Payment Backend rodando na porta ${PORT}`);
});
