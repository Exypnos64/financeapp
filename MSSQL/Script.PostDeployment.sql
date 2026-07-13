/*
  Post-deployment script — runs on EVERY publish, AFTER the schema is applied.
  This is where reference/seed data goes (sentinel rows), never structural changes.

  Rules to honor as you fill this in:
    - Idempotent: guard every insert so re-running never duplicates a row or errors.
    - Order matters here (top-to-bottom, imperative) — unlike the schema build.
      Insert a CategoryGroup BEFORE the Category that references it.
    - To write an explicit value into an IDENTITY Id column, wrap the insert:
        SET IDENTITY_INSERT dbo.<Table> ON;  ...  SET IDENTITY_INSERT dbo.<Table> OFF;
      (only one table may have IDENTITY_INSERT ON at a time).

  Sentinels to seed (needed because these FKs are NOT NULL on LedgerEntry):
    1. a CategoryGroup to hold the Uncategorized category
    2. the "Uncategorized" Category (in that group)
    3. the "Unknown" Merchant
*/
IF NOT EXISTS (SELECT 1 FROM dbo.CategoryGroup)
BEGIN
  SET IDENTITY_INSERT dbo.CategoryGroup ON;
  INSERT INTO dbo.CategoryGroup (Id, Name) VALUES
    (1, 'Income'),
    (2, 'Gifts & Donations'),
    (3, 'Shopping'),
    (4, 'Food & Dining'),
    (5, 'Bills & Utilities'),
    (6, 'Housing'),
    (7, 'Auto & Transport'),
    (8, 'Travel & Lifestyle'),
    (9, 'Children'),
    (10, 'Education'),
    (11, 'Health & Wellness'),
    (12, 'Financial'),
    (13, 'Other'),
    (14, 'Transfers');
  SET IDENTITY_INSERT dbo.CategoryGroup OFF;
END;



IF NOT EXISTS (SELECT 1 FROM dbo.Category WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.Category ON;
  INSERT INTO dbo.Category (Id, GroupId, Name, IconName) VALUES
    (1, 13, 'Uncategorized', '');
  SET IDENTITY_INSERT dbo.Category OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Category WHERE Id != 1)
BEGIN
  SET IDENTITY_INSERT dbo.Category ON;
  INSERT INTO dbo.Category (Id, GroupId, Name, IconName) VALUES
    ( 2,  1, 'Paycheck',                   ''),
    ( 3,  1, 'Interest',                   ''),
    ( 4,  1, 'Holiday Gifts',              ''),
    ( 5,  2, 'Charity',                    ''),
    ( 6,  2, 'Gifts',                      ''),
    ( 7,  2, 'Tithe',                      ''),
    ( 8,  3, 'Shopping',                   ''),
    ( 9,  3, 'Clothing',                   ''),
    (10,  3, 'Furniture & Housewares',     ''),
    (11,  3, 'Electronics',                ''),
    (12,  4, 'Groceries',                  ''),
    (13,  4, 'Restaurants & Bars',         ''),
    (14,  4, 'Coffee Shops',               ''),
    (15,  5, 'Garbage',                    ''),
    (16,  5, 'Water',                      ''),
    (17,  5, 'Gas & Electric',             ''),
    (18,  5, 'Internet & Cable',           ''),
    (19,  5, 'Phone',                      ''),
    (20,  6, 'Mortgage',                   ''),
    (21,  6, 'Rent',                       ''),
    (22,  6, 'Home Improvement',           ''),
    (23,  7, 'Auto Payment',               ''),
    (24,  7, 'Public Transit',             ''),
    (25,  7, 'Gas',                        ''),
    (26,  7, 'Auto Maintenance',           ''),
    (27,  7, 'Parking & Tolls',            ''),
    (28,  7, 'Taxi & Ride Shares',         ''),
    (29,  8, 'Travel & Vacation',          ''),
    (30,  8, 'Entertainment & Recreation', ''),
    (31,  8, 'Personal',                   ''),
    (32,  8, 'Fun Money',                  ''),
    (33,  9, 'Pets',                       ''),
    (34,  9, 'Child Care',                 ''),
    (35,  9, 'Child Activities',           ''),
    (36, 10, 'Student Loans',              ''),
    (37, 10, 'Education',                  ''),
    (38, 11, 'Medical',                    ''),
    (39, 11, 'Dentist',                    ''),
    (40, 11, 'Fitness',                    ''),
    (41, 12, 'Loan Repayment',             ''),
    (42, 12, 'Financial & Legal Services', ''),
    (43, 12, 'Financial Fees',             ''),
    (44, 12, 'Cash & ATM',                 ''),
    (45, 12, 'Insurance',                  ''),
    (46, 12, 'Taxes',                      ''),
    (47, 13, 'Check',                      ''),
    (48, 13, 'Miscellaneous',              ''),
    (49, 14, 'Transfer',                   ''),
    (50, 14, 'Credit Card Payment',        ''),
    (51, 14, 'Balance Adjustments',        '');
  SET IDENTITY_INSERT dbo.Category OFF;
END;


IF NOT EXISTS (SELECT 1 FROM dbo.Merchant WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.Merchant ON;
  INSERT INTO dbo.Merchant (Id, Name) VALUES (1, 'Unknown');
  SET IDENTITY_INSERT dbo.Merchant OFF;
END;

-- IF NOT EXISTS (SELECT 1 FROM dbo.Merchant WHERE Id != 1)
-- BEGIN
--   SET IDENTITY_INSERT dbo.Merchant ON;
--   INSERT INTO dbo.Merchant (Id, Name) VALUES
--     ( 2, 'Academy Sports + Outdoors'),
--     ( 3, 'AliExpress'),
--     ( 4, 'Amazon'),
--     ( 5, 'Apple'),
--     ( 6, 'Baskin Robins'),
--     ( 7, 'Best Buy'),
--     ( 8, 'Buffalo Wild Wings'),
--     ( 9, 'Burger King'),
--     (10, 'Caseys''s'),
--     (11, 'Chick-fil-A'),
--     (12, 'Chili''s'),
--     (13, 'Culver''s'),
--     (14, 'Discover'),
--     (15, 'Domino''s'),
--     (16, 'eBay'),
--     (17, 'Etsy'),
--     (18, 'Exxon Mobil'),
--     (19, 'Facebook Marketplace'),
--     (20, 'Five Below'),
--     (21, 'GameStop'),
--     (22, 'Great Clips'),
--     (23, 'Harbor Freight'),
--     (24, 'HEYDUDE'),
--     (25, 'Hobby Lobby'),
--     (26, 'Huck''s'),
--     (27, 'Humble Bundle'),
--     (28, 'Intuit QuickBooks'),
--     (29, 'IRS'),
--     (30, 'JCPenney'),
--     (31, 'Jimmy John''s'),
--     (32, 'Kinguin'),
--     (33, 'Little Caesar''s'),
--     (34, 'Lowe''s'),
--     (35, 'Marcus Theatres'),
--     (36, 'Mastercard'),
--     (37, 'Mazda'),
--     (38, 'McDonald''s'),
--     (39, 'Menards'),
--     (40, 'Mercy'),
--     (41, 'Meta Platforms'),
--     (42, 'Micro Center'),
--     (43, 'Mint Mobile'),
--     (44, 'Newegg'),
--     (45, 'Nintendo'),
--     (46, 'Old Navy'),
--     (47, 'Panda Express'),
--     (48, 'Papa John''s'),
--     (49, 'PayPal'),
--     (50, 'Pizza Inn'),
--     (51, 'Progressive'),
--     (52, 'Rally''s'),
--     (53, 'Rhodes 101'),
--     (54, 'Sam''s Club'),
--     (55, 'Sierra Trading Post'),
--     (56, 'Spotify'),
--     (57, 'Steam'),
--     (58, 'Subway'),
--     (59, 'Success Vision Express'),
--     (60, 'Taco Bell'),
--     (61, 'Target'),
--     (62, 'TJ Maxx'),
--     (63, 'Trader Joe''s'),
--     (64, 'Venmo'),
--     (65, 'Vintage Stock'),
--     (66, 'Walmart'),
--     (67, 'Wells Fargo');
--   SET IDENTITY_INSERT dbo.Merchant OFF;
-- END;

