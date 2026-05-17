# claude.md — Supabase

You are setting up Supabase for "Spent" — a personal expense tracking app.  
Responsibilities: Auth, Database schema, Row Level Security, Realtime.

---

## Project Setup

1. Create project at supabase.com
2. Note: `Project URL` and `anon key`
3. Enable Email auth (Dashboard → Auth → Providers → Email)
4. Disable email confirmation for MVP (Auth → Settings → "Confirm email" → off)

---

## Database Schema

Run this SQL in the Supabase SQL editor in order:

### 1. Categories Table (static reference)

```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,           -- 'food', 'transport', etc.
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT NOT NULL            -- hex string
);

INSERT INTO categories VALUES
  ('food',          'Food',          'fork-knife',    '#FF6B6B'),
  ('transport',     'Transport',     'car',           '#4ECDC4'),
  ('shopping',      'Shopping',      'shopping-bag',  '#FFE66D'),
  ('bills',         'Bills',         'receipt',       '#A8E6CF'),
  ('entertainment', 'Entertainment', 'tv',            '#C77DFF'),
  ('health',        'Health',        'heart',         '#FF8B94'),
  ('education',     'Education',     'book',          '#74B9FF'),
  ('travel',        'Travel',        'plane',         '#FFEAA7'),
  ('others',        'Others',        'grid',          '#636E72');
```

### 2. Expenses Table

```sql
CREATE TABLE expenses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount          NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  category_id     TEXT NOT NULL REFERENCES categories(id),
  note            TEXT,
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method  TEXT NOT NULL DEFAULT 'cash'
                    CHECK (payment_method IN ('cash', 'upi', 'card')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for common queries
CREATE INDEX idx_expenses_user_date ON expenses(user_id, date DESC);
CREATE INDEX idx_expenses_user_category ON expenses(user_id, category_id);
```

### 3. Budgets Table

```sql
CREATE TABLE budgets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  monthly_limit NUMERIC(12, 2) NOT NULL CHECK (monthly_limit > 0),
  month         SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year          SMALLINT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, month, year)
);
```

### 4. Updated_at trigger

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

## Row Level Security (RLS)

Enable RLS and add policies:

```sql
-- Enable RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Expenses: users can only access their own
CREATE POLICY "expenses_select" ON expenses FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "expenses_insert" ON expenses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "expenses_update" ON expenses FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "expenses_delete" ON expenses FOR DELETE
  USING (auth.uid() = user_id);

-- Budgets: users can only access their own
CREATE POLICY "budgets_select" ON budgets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "budgets_insert" ON budgets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "budgets_update" ON budgets FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "budgets_delete" ON budgets FOR DELETE
  USING (auth.uid() = user_id);

-- Categories: public read
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categories_public_read" ON categories FOR SELECT
  USING (true);
```

---

## Realtime

Enable realtime for the expenses table:

```sql
-- In Supabase Dashboard: Database → Replication → enable expenses table
-- OR via SQL:
ALTER PUBLICATION supabase_realtime ADD TABLE expenses;
```

In Flutter, use `.stream()` not `.select()` for realtime updates on the home screen.

---

## Useful Queries (for FastAPI to use)

### Monthly total
```sql
SELECT COALESCE(SUM(amount), 0) as total
FROM expenses
WHERE user_id = $1
  AND date_part('month', date) = $2
  AND date_part('year', date) = $3;
```

### Category breakdown for month
```sql
SELECT category_id, SUM(amount) as total
FROM expenses
WHERE user_id = $1
  AND date_part('month', date) = $2
  AND date_part('year', date) = $3
GROUP BY category_id
ORDER BY total DESC;
```

### Daily spending (last 7 days)
```sql
SELECT date, SUM(amount) as total
FROM expenses
WHERE user_id = $1
  AND date >= CURRENT_DATE - INTERVAL '6 days'
GROUP BY date
ORDER BY date ASC;
```

### Monthly comparison (last 6 months)
```sql
SELECT 
  date_part('month', date) as month,
  date_part('year', date) as year,
  SUM(amount) as total
FROM expenses
WHERE user_id = $1
  AND date >= (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '5 months')
GROUP BY month, year
ORDER BY year ASC, month ASC;
```

---

## Auth Flow Notes

- Supabase Flutter SDK handles session persistence automatically
- `supabase.auth.onAuthStateChange` stream → update GoRouter redirect
- Access token is available via `supabase.auth.currentSession?.accessToken`
- Pass this Bearer token to FastAPI for analytics endpoints

---

## Environment Variables

Store these in your CI / `.env` (never commit):
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...   # FastAPI backend only
```

FastAPI uses `SERVICE_ROLE_KEY` to bypass RLS when running aggregations.

---

## What NOT to Do

- Do NOT store user PII beyond email (auth.users handles it)
- Do NOT disable RLS on any table
- Do NOT use service role key in Flutter
- Do NOT create custom auth tables — use `auth.users` reference only
- Do NOT add more tables for MVP (no recurring_expenses yet)
