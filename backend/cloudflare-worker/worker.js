/**
 * MoneyWork — proxy harga saham IDX (Cloudflare Workers).
 *
 * Alternatif gratis-tanpa-kartu dari Firebase Functions. Hasil JSON-nya
 * identik sehingga `price_service.dart` tidak perlu diubah.
 *
 * Endpoint: GET /?symbol=BBCA
 * Respons : { "symbol": "BBCA", "price": 9500, "currency": "IDR" }
 *
 * Deploy:
 *   1. npx wrangler login
 *   2. npx wrangler deploy
 *   3. salin URL workers.dev ke priceServiceProvider (stockProxyBase)
 */

export default {
  async fetch(request) {
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET",
    };
    if (request.method === "OPTIONS") {
      return new Response("", { status: 204, headers: cors });
    }

    const url = new URL(request.url);
    const symbol = (url.searchParams.get("symbol") || "").trim().toUpperCase();
    if (!symbol) {
      return json({ error: "Parameter 'symbol' wajib diisi." }, 400, cors);
    }

    try {
      const ySymbol = symbol.endsWith(".JK") ? symbol : `${symbol}.JK`;
      const upstream = await fetchYahoo(ySymbol);
      if (!upstream.ok) {
        return json({ error: `Yahoo error ${upstream.status}` }, 502, cors);
      }
      const data = await upstream.json();
      const meta = data?.chart?.result?.[0]?.meta;
      const price = meta?.regularMarketPrice;
      if (typeof price !== "number") {
        return json(
          { error: `Saham '${symbol}' tidak ditemukan.` },
          404,
          cors,
        );
      }
      return json(
        { symbol, price, currency: meta.currency || "IDR" },
        200,
        cors,
      );
    } catch (e) {
      return json({ error: String(e) }, 500, cors);
    }
  },
};

// Yahoo menolak request tanpa header browser (HTTP 429), terutama dari IP
// bersama seperti Cloudflare. Kirim User-Agent wajar, dan coba host kedua
// (query2) jika host pertama membatasi.
async function fetchYahoo(ySymbol) {
  const headers = {
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "application/json,text/plain,*/*",
    "Accept-Language": "en-US,en;q=0.9",
  };
  const hosts = [
    "https://query1.finance.yahoo.com",
    "https://query2.finance.yahoo.com",
  ];
  let last;
  for (const host of hosts) {
    const res = await fetch(
      `${host}/v8/finance/chart/${encodeURIComponent(ySymbol)}`,
      { headers },
    );
    if (res.ok) return res;
    last = res;
  }
  return last;
}

function json(body, status, cors) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });
}
