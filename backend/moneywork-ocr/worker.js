/**
 * MoneyWork — OCR Receipt Scanner Proxy (Cloudflare Workers).
 *
 * Meneruskan gambar bon (Base64) ke Gemini API dan mengembalikan
 * data terstruktur (JSON) berisi daftar item, pajak, service, & grand total.
 *
 * API Key Gemini disimpan sebagai Cloudflare Secret — tidak pernah ada
 * di kode sumber maupun di aplikasi mobile.
 *
 * Endpoint: POST /scan
 * Body    : { "imageBase64": "..." }
 * Respons : { "items": [...], "subtotal": ..., "serviceCharge": ..., "tax": ..., "grandTotal": ... }
 *
 * Deploy:
 *   1. cd backend/moneywork-ocr
 *   2. npx wrangler login
 *   3. npx wrangler secret put GEMINI_API_KEY
 *   4. npx wrangler deploy
 */

const SYSTEM_PROMPT = `You are a receipt/bill data extractor. Analyze the receipt image and extract ALL items, quantities, prices, subtotal, service charge, tax, and grand total.

RULES:
1. Respond ONLY with valid JSON. No explanations, no markdown.
2. All prices must be numbers (not strings). Use the currency shown on the receipt (usually IDR for Indonesian receipts).
3. If quantity is not shown, assume 1.
4. "unitPrice" is the price per single unit. "totalPrice" is qty * unitPrice.
5. "subtotal" is the sum of all item totalPrice values.
6. "serviceCharge" is any service fee listed (0 if none).
7. "tax" is any tax/PPN listed (0 if none).
8. "grandTotal" is the final total printed on the receipt.
9. Extract item names exactly as printed. Keep them concise.

REQUIRED JSON FORMAT:
{
  "items": [
    { "name": "Item Name", "qty": 1, "unitPrice": 25000, "totalPrice": 25000 }
  ],
  "subtotal": 50000,
  "serviceCharge": 0,
  "tax": 5500,
  "grandTotal": 55500
}`;

export default {
  async fetch(request, env) {
    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response('', { status: 204, headers: cors });
    }

    // Only accept POST
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Only POST allowed' }, 405, cors);
    }

    // Parse request
    let body;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: 'Invalid JSON body' }, 400, cors);
    }

    const { imageBase64 } = body;
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      return jsonResponse(
        { error: 'Field "imageBase64" is required (string)' },
        400,
        cors,
      );
    }

    // Validate API key is configured
    const apiKey = env.GEMINI_API_KEY;
    if (!apiKey) {
      return jsonResponse(
        { error: 'GEMINI_API_KEY secret not configured' },
        500,
        cors,
      );
    }

    try {
     const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${apiKey}`;

      const geminiBody = {
        contents: [
          {
            parts: [
              { text: SYSTEM_PROMPT },
              {
                inline_data: {
                  mime_type: 'image/jpeg',
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 4096,
          responseMimeType: 'application/json',
        },
      };

      const geminiRes = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(geminiBody),
      });

      if (!geminiRes.ok) {
        const errText = await geminiRes.text();
        return jsonResponse(
          { error: `Gemini API error (${geminiRes.status}): ${errText} | URL: ${geminiUrl.substring(0, 80)}...` },
          502,
          cors,
        );
      }

      const geminiData = await geminiRes.json();

      // Extract the text content from Gemini response
      const textContent =
        geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!textContent) {
        return jsonResponse(
          { error: 'Empty response from Gemini' },
          502,
          cors,
        );
      }

      // Parse the JSON from Gemini's response
      let receiptData;
      try {
        // Clean potential markdown code fences
        const cleaned = textContent
          .replace(/```json\s*/g, '')
          .replace(/```\s*/g, '')
          .trim();
        receiptData = JSON.parse(cleaned);
      } catch {
        return jsonResponse(
          {
            error: 'Failed to parse Gemini response as JSON',
            raw: textContent,
          },
          502,
          cors,
        );
      }

      // Validate required fields
      if (!Array.isArray(receiptData.items)) {
        return jsonResponse(
          { error: 'Invalid response structure: missing items array' },
          502,
          cors,
        );
      }

      // Ensure numeric fields have defaults
      receiptData.subtotal = Number(receiptData.subtotal) || 0;
      receiptData.serviceCharge = Number(receiptData.serviceCharge) || 0;
      receiptData.tax = Number(receiptData.tax) || 0;
      receiptData.grandTotal = Number(receiptData.grandTotal) || 0;

      // Sanitize items
      receiptData.items = receiptData.items.map((item) => ({
        name: String(item.name || 'Unknown'),
        qty: Math.max(1, Math.round(Number(item.qty) || 1)),
        unitPrice: Number(item.unitPrice) || 0,
        totalPrice: Number(item.totalPrice) || 0,
      }));

      return jsonResponse(receiptData, 200, cors);
    } catch (e) {
      return jsonResponse({ error: `Server error: ${String(e)}` }, 500, cors);
    }
  },
};

function jsonResponse(body, status, cors) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...cors },
  });
}
