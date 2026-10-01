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

test('PDF statement endpoint forwards PDF and returns reviewable rows', async () => {
  const originalFetch = globalThis.fetch;
  let upstreamBody;
  globalThis.fetch = async (_url, options) => {
    upstreamBody = JSON.parse(options.body);
    return new Response(JSON.stringify({
      candidates: [{finishReason: 'STOP', content: {parts: [{text: JSON.stringify({
        pageCount: 1,
        transactionCount: 2,
        openingBalance: 'Rp 100.000',
        closingBalance: 'Rp 95.000',
        transactions: [
          {date: '2026-09-01', direction: 'debit', amount: 'Rp 10.000', description: 'Belanja', page: 1},
          {date: '2026-09-02', direction: 'credit', amount: 'Rp 5.000', description: 'Transfer', page: 1},
        ],
      })}]}}],
    }), {status: 200});
  };
  try {
    const response = await worker.fetch(new Request('https://example.test/statement-scan', {
      method: 'POST',
      body: JSON.stringify({pdfBase64: Buffer.from('%PDF-1.4\n').toString('base64')}),
    }), {GEMINI_API_KEY: 'test-key'});
    assert.equal(response.status, 200);
    const data = await response.json();
    assert.equal(data.transactions.length, 2);
    assert.equal(data.transactions[0].amount, 10000);
    assert.equal(data.closingBalance, 95000);
    assert.equal(upstreamBody.contents[0].parts[1].inline_data.mime_type, 'application/pdf');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('PDF statement endpoint rejects truncated model output', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({
    candidates: [{finishReason: 'MAX_TOKENS', content: {parts: [{text: '{}'}]}}],
  }), {status: 200});
  try {
    const response = await worker.fetch(new Request('https://example.test/statement-scan', {
      method: 'POST',
      body: JSON.stringify({pdfBase64: Buffer.from('%PDF-1.4\n').toString('base64')}),
    }), {GEMINI_API_KEY: 'test-key'});
    assert.equal(response.status, 422);
    assert.deepEqual(await response.json(), {code: 'OUTPUT_TRUNCATED'});
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('PDF statement endpoint rejects a non-PDF before calling Gemini', async () => {
  const originalFetch = globalThis.fetch;
  let called = false;
  globalThis.fetch = async () => { called = true; throw Error('unexpected'); };
  try {
    const response = await worker.fetch(new Request('https://example.test/statement-scan', {
      method: 'POST',
      body: JSON.stringify({pdfBase64: Buffer.from('private bank data').toString('base64')}),
    }), {GEMINI_API_KEY: 'test-key'});
    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), {code: 'INVALID_PDF'});
    assert.equal(called, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('PDF statement endpoint rejects a reported page count above 40', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({
    candidates: [{finishReason: 'STOP', content: {parts: [{text: JSON.stringify({
      pageCount: 41, transactionCount: 0, transactions: [],
    })}]}}],
  }), {status: 200});
  try {
    const response = await worker.fetch(new Request('https://example.test/statement-scan', {
      method: 'POST',
      body: JSON.stringify({pdfBase64: Buffer.from('%PDF-1.4\n').toString('base64')}),
    }), {GEMINI_API_KEY: 'test-key'});
    assert.equal(response.status, 422);
    assert.deepEqual(await response.json(), {code: 'PAGE_LIMIT'});
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('OCR proxy never returns upstream text or key in an error', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response('secret upstream details', {status: 403});
  try {
    const response = await worker.fetch(new Request('https://example.test/scan', {
      method: 'POST',
      body: JSON.stringify({imageBase64: 'ZmFrZQ=='}),
    }), {GEMINI_API_KEY: 'secret-key'});
    const body = JSON.stringify(await response.json());
    assert.equal(response.status, 502);
    assert.equal(body.includes('secret upstream'), false);
    assert.equal(body.includes('secret-key'), false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
