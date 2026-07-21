/**
 * MoneyWork — proxy harga saham IDX.
 *
 * Mengambil harga terkini dari Yahoo Finance (tanpa API key) dan
 * meneruskannya sebagai JSON sederhana. Berfungsi sebagai perantara agar
 * aplikasi web (yang terkena pembatasan CORS) tetap bisa mendapat harga.
 *
 * Endpoint: GET /quote?symbol=BBCA
 * Respons : { "symbol": "BBCA", "price": 9500, "currency": "IDR" }
 *
 * Deploy:
 *   1. firebase login
 *   2. firebase init functions   (pilih project, JavaScript)
 *   3. salin file ini ke functions/index.js
 *   4. firebase deploy --only functions
 *   5. salin URL hasil deploy ke priceServiceProvider (stockProxyBase)
 *
 * Catatan: deploy Cloud Functions kini memerlukan paket Blaze. Kuota
 * gratisnya besar; pemakaian pribadi praktis tidak berbiaya, tetapi tetap
 * perlu mengaktifkan billing.
 */

const functions = require("firebase-functions");

// Saham IDX di Yahoo Finance memakai akhiran ".JK" (Jakarta).
const YF_BASE = "https://query1.finance.yahoo.com/v8/finance/chart";

exports.quote = functions.https.onRequest(async (req, res) => {
  // Izinkan akses dari aplikasi web.
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const symbol = String(req.query.symbol || "").trim().toUpperCase();
  if (!symbol) {
    res.status(400).json({ error: "Parameter 'symbol' wajib diisi." });
    return;
  }

  try {
    const ySymbol = symbol.endsWith(".JK") ? symbol : `${symbol}.JK`;
    const url = `${YF_BASE}/${encodeURIComponent(ySymbol)}`;
    const upstream = await fetch(url);
    if (!upstream.ok) {
      res.status(502).json({ error: `Yahoo error ${upstream.status}` });
      return;
    }
    const data = await upstream.json();
    const meta = data?.chart?.result?.[0]?.meta;
    const price = meta?.regularMarketPrice;
    if (typeof price !== "number") {
      res.status(404).json({ error: `Saham '${symbol}' tidak ditemukan.` });
      return;
    }
    res.json({
      symbol,
      price,
      currency: meta.currency || "IDR",
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});
