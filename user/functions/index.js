const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Endpoint untuk kirim kode verifikasi
app.post('/send-code', async (req, res) => {
  const { email } = req.body;

  if (!email) return res.status(400).json({ success: false, message: 'Email wajib diisi' });

  // Generate kode 4 digit
  const code = Math.floor(1000 + Math.random() * 9000).toString();

  // Konfigurasi transporter Gmail
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.SENDER_EMAIL,
      pass: process.env.SENDER_PASS,
    },
  });

  const mailOptions = {
    from: `"Sembuh TBC App" <${process.env.SENDER_EMAIL}>`,
    to: email,
    subject: 'Kode Verifikasi Reset Password',
    text: `Kode verifikasi Anda adalah: ${code}. Berlaku selama 10 menit.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`✅ Kode ${code} terkirim ke ${email}`);
    return res.status(200).json({ success: true, code });
  } catch (error) {
    console.error('❌ Gagal mengirim email:', error);
    return res.status(500).json({ success: false, message: 'Gagal mengirim email' });
  }
});

// Cek server aktif
app.get('/', (req, res) => {
  res.send('✅ API Verifikasi aktif!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
});
