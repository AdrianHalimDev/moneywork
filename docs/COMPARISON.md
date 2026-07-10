# Perbandingan Field Input: Login/Register (BUG) vs Home Pages (AMAN)

## FIELD YANG BUG (login + register page)

| Field | keyboardType | autocorrect | enableSuggestions | inputFormatters | autofillHints |
|-------|-------------|-------------|-------------------|-----------------|---------------|
| Email | emailAddress | false | false | NONE | NONE |
| Name (daftar) | text (default) + textCapitalization:words | false | false | NONE | NONE |
| Password | visiblePassword | false | false | NONE | NONE |
| ConfirmPassword | visiblePassword | false | false | NONE | NONE |

## FIELD YANG AMAN (home pages — accounts, bills, debts, dll)

| Field (contoh: accounts_screen) | keyboardType | autocorrect | enableSuggestions | inputFormatters | autofillHints |
|--------------------------------|-------------|-------------|-------------------|-----------------|---------------|
| Nama akun | text (DEFAULT) | **DEFAULT (null)** | **DEFAULT (null)** | NONE | NONE |
| Nomor rekening | text | DEFAULT | DEFAULT | NONE | NONE |
| Saldo | number | DEFAULT | DEFAULT | [ThousandsInputFormatter] | NONE |
| Jumlah | number | DEFAULT | DEFAULT | [ThousandsInputFormatter] | NONE |
| Kategori | text | DEFAULT | DEFAULT | NONE | NONE |
| Catatan | text | DEFAULT | DEFAULT | NONE | NONE |

## PERBEDAAN KUNCI YANG TERUNGKAP

### 1. keyboardType: emailAddress (login page email field)
Login page email pakai `emailAddress` → Android `TYPE_TEXT_VARIATION_EMAIL_ADDRESS`
Home page fields pakai `text` atau `number` → default/variasi biasa

### 2. autocorrect: false + enableSuggestions: false (login/register page)
Login/register: **SELALU** set `autocorrect: false` + `enableSuggestions: false`
Home page: **TIDAK** set sama sekali (pakai default Flutter = null/true)

### 3. absence of inputFormatters
Login/register: TIDAK ada `inputFormatters`
Home page: BANYAK yang pakai `[ThousandsInputFormatter()]`

### 4. STRUCTURAL (paling mungkin)
Login/register page → di dalam `_AuthGate` yang `ref.watch(authStateProvider)`
Home pages → tidak ada watch auth state secara langsung
