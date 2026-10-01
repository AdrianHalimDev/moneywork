import assert from 'node:assert/strict';
import test from 'node:test';
import worker from './worker.js';

test('OCR proxy preserves discount and additional fees from Gemini', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({
    candidates: [{content: {parts: [{text: JSON.stringify({
      items: [{name: 'Makan', qty: 1, unitPrice: 'Rp 10.000', totalPrice: 'Rp 10.000'}],
      subtotal: 'Rp 10.000',
      serviceCharge: 'Rp 1.000',
      tax: 'Rp 1.000',
      discount: '-Rp 2.000',
      additionalFees: 'Rp 500',
      grandTotal: 'Rp 10.500',
    })}]}}],
  }), {status: 200});

  try {
    const response = await worker.fetch(new Request('https://example.test/scan', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({imageBase64: 'ZmFrZQ=='}),
    }), {GEMINI_API_KEY: 'test-key'});
    assert.equal(response.status, 200);
    const data = await response.json();
    assert.equal(data.items[0].unitPrice, 10000);
    assert.equal(data.discount, 2000);
    assert.equal(data.additionalFees, 500);
    assert.equal(data.grandTotal, 10500);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('discount returned as an item is moved into the discount field', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({
    candidates: [{content: {parts: [{text: JSON.stringify({
      items: [
        {name: 'Makan', qty: 1, unitPrice: 10000, totalPrice: 10000},
        {name: 'Diskon Promo', qty: 1, unitPrice: -2000, totalPrice: -2000},
      ],
      discount: 0,
      grandTotal: 8000,
    })}]}}],
  }), {status: 200});
  try {
    const response = await worker.fetch(new Request('https://example.test/scan', {
      method: 'POST',
      body: JSON.stringify({imageBase64: 'ZmFrZQ=='}),
    }), {GEMINI_API_KEY: 'test-key'});
    const data = await response.json();
    assert.equal(data.items.length, 1);
    assert.equal(data.discount, 2000);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
