DECLARE @CurUtc AS DATETIME2(7);
SET @CurUtc = SYSUTCDATETIME();

DECLARE @CurLocal AS DATETIMEOFFSET;
SET @CurLocal = SYSDATETIMEOFFSET();

-- ===================== Default Category Sets ======================
IF NOT EXISTS (SELECT 1 FROM dbo.DefaultCategorySet)
BEGIN
  SET IDENTITY_INSERT dbo.DefaultCategorySet ON;
  INSERT INTO dbo.DefaultCategorySet (Id, Name) VALUES
    ( 1, 'Income'),
    ( 2, 'Gifts & Donations'),
    ( 3, 'Shopping'),
    ( 4, 'Food & Dining'),
    ( 5, 'Bills & Utilities'),
    ( 6, 'Housing'),
    ( 7, 'Auto & Transport'),
    ( 8, 'Travel & Lifestyle'),
    ( 9, 'Children'),
    (10, 'Education'),
    (11, 'Health & Wellness'),
    (12, 'Financial'),
    (13, 'Other'),
    (14, 'Transfers');
  SET IDENTITY_INSERT dbo.DefaultCategorySet OFF;
END;



-- ==================== Default Categories ===========================
IF NOT EXISTS (SELECT 1 FROM dbo.DefaultCategory WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.DefaultCategory ON;
  INSERT INTO dbo.DefaultCategory (Id, SetId, Name, IconName) VALUES
    (1, 13, 'Uncategorized', '');
  SET IDENTITY_INSERT dbo.DefaultCategory OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.DefaultCategory WHERE Id != 1)
BEGIN
  SET IDENTITY_INSERT dbo.DefaultCategory ON;
  INSERT INTO dbo.DefaultCategory (Id, SetId, Name, IconName) VALUES
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
  SET IDENTITY_INSERT dbo.DefaultCategory OFF;
END;



-- ====================== Master Merchant List =======================
IF NOT EXISTS (SELECT 1 FROM dbo.Merchant WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.Merchant ON;
  INSERT INTO dbo.Merchant (Id, Name, Reviewed, Approved) VALUES (1, 'Unknown', 1, 1);
  SET IDENTITY_INSERT dbo.Merchant OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Merchant WHERE Id != 1)
BEGIN
  SET IDENTITY_INSERT dbo.Merchant ON;
  INSERT INTO dbo.Merchant (Id, Name, Reviewed, Approved) VALUES
    ( 2, 'Academy Sports + Outdoors', 1, 1),
    ( 3, 'AliExpress',                1, 1),
    ( 4, 'Amazon',                    1, 1),
    ( 5, 'Apple',                     1, 1),
    ( 6, 'Baskin Robins',             1, 1),
    ( 7, 'Best Buy',                  1, 1),
    ( 8, 'Buffalo Wild Wings',        1, 1),
    ( 9, 'Burger King',               1, 1),
    (10, 'Caseys''s',                 1, 1),
    (11, 'Chick-fil-A',               1, 1),
    (12, 'Chili''s',                  1, 1),
    (13, 'Culver''s',                 1, 1),
    (14, 'Discover',                  1, 1),
    (15, 'Domino''s',                 1, 1),
    (16, 'eBay',                      1, 1),
    (17, 'Etsy',                      1, 1),
    (18, 'Exxon Mobil',               1, 1),
    (19, 'Facebook Marketplace',      1, 1),
    (20, 'Five Below',                1, 1),
    (21, 'GameStop',                  1, 1),
    (22, 'Great Clips',               1, 1),
    (23, 'Harbor Freight',            1, 1),
    (24, 'HEYDUDE',                   1, 1),
    (25, 'Hobby Lobby',               1, 1),
    (26, 'Huck''s',                   1, 1),
    (27, 'Humble Bundle',             1, 1),
    (28, 'Intuit QuickBooks',         1, 1),
    (29, 'IRS',                       1, 1),
    (30, 'JCPenney',                  1, 1),
    (31, 'Jimmy John''s',             1, 1),
    (32, 'Kinguin',                   1, 1),
    (33, 'Little Caesar''s',          1, 1),
    (34, 'Lowe''s',                   1, 1),
    (35, 'Marcus Theatres',           1, 1),
    (36, 'Mastercard',                1, 1),
    (37, 'Mazda',                     1, 1),
    (38, 'McDonald''s',               1, 1),
    (39, 'Menards',                   1, 1),
    (40, 'Mercy',                     1, 1),
    (41, 'Meta Platforms',            1, 1),
    (42, 'Micro Center',              1, 1),
    (43, 'Mint Mobile',               1, 1),
    (44, 'Newegg',                    1, 1),
    (45, 'Nintendo',                  1, 1),
    (46, 'Old Navy',                  1, 1),
    (47, 'Panda Express',             1, 1),
    (48, 'Papa John''s',              1, 1),
    (49, 'PayPal',                    1, 1),
    (50, 'Pizza Inn',                 1, 1),
    (51, 'Progressive',               1, 1),
    (52, 'Rally''s',                  1, 1),
    (53, 'Rhodes 101',                1, 1),
    (54, 'Sam''s Club',               1, 1),
    (55, 'Sierra Trading Post',       1, 1),
    (56, 'Spotify',                   1, 1),
    (57, 'Steam',                     1, 1),
    (58, 'Subway',                    1, 1),
    (59, 'Success Vision Express',    1, 1),
    (60, 'Taco Bell',                 1, 1),
    (61, 'Target',                    1, 1),
    (62, 'TJ Maxx',                   1, 1),
    (63, 'Trader Joe''s',             1, 1),
    (64, 'Venmo',                     1, 1),
    (65, 'Vintage Stock',             1, 1),
    (66, 'Walmart',                   1, 1),
    (67, 'Wells Fargo',               1, 1);
  SET IDENTITY_INSERT dbo.Merchant OFF;
END;



-- ===================== Dummy User ==================================
IF NOT EXISTS (SELECT 1 FROM dbo.EndUser WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.EndUser ON;
  INSERT INTO dbo.EndUser (Id, Email, PasswordHash, FullName, PrefName)
    VALUES (1, 'mattmutt24@gmail.com', '5SE4TBA98E40G6E', 'Mathew Mutton', 'Matt');
  SET IDENTITY_INSERT dbo.EndUser OFF;
END

IF NOT EXISTS (SELECT 1 FROM dbo.UserGroup WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.UserGroup ON;
  INSERT INTO dbo.UserGroup (Id, Name) VALUES (1, 'Test Group');
  SET IDENTITY_INSERT dbo.UserGroup OFF;
END

IF NOT EXISTS (SELECT 1 FROM dbo.GroupMember WHERE UserId = 1 AND GroupId = 1)
BEGIN
  INSERT INTO dbo.GroupMember (UserId, GroupId, PermissionLevel, GrantedByUserId, GrantedAtUtc, ExpireAtUtc)
    VALUES (1, 1, 3, NULL, @CurUtc, NULL);
END



-- ======================= User Categories ===========================
IF NOT EXISTS (SELECT 1 FROM dbo.CategorySet)
BEGIN
  INSERT INTO dbo.CategorySet (GroupId, DefaultId, Name)
    SELECT 1, Id, Name FROM dbo.DefaultCategorySet;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Category)
BEGIN
  INSERT INTO dbo.Category (GroupId, DefaultId, SetId, Name, IconName)
    SELECT 1, dc.Id, cs.Id, dc.Name, dc.IconName FROM dbo.DefaultCategory AS dc
    JOIN dbo.CategorySet AS cs ON cs.DefaultId = dc.SetId AND cs.GroupId = 1;
END



-- ======================= User Merchants ============================
IF NOT EXISTS (SELECT 1 FROM dbo.GroupMerchant WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.GroupMerchant ON;
  INSERT INTO dbo.GroupMerchant (Id, GroupId, MerchantId, Name)
    VALUES (1, 1, 1, NULL);
  SET IDENTITY_INSERT dbo.GroupMerchant OFF;
END;



-- ====================== Bank Account ===============================
IF NOT EXISTS (SELECT 1 FROM dbo.Account WHERE Id = 1)
BEGIN
  SET IDENTITY_INSERT dbo.Account ON;
  INSERT INTO dbo.Account (Id, TypeId, GroupId, Name, StartDateUtc, StartBalance, LastModifiedUtc)
    VALUES (1, 2, 1, 'Bank of Missouri', '2025-02-21', 0, @CurUtc);
  SET IDENTITY_INSERT dbo.Account OFF;
END

DECLARE @Col AS INT;
SELECT @Col = Id FROM Category WHERE GroupId = 1 AND DefaultId = 1;

IF NOT EXISTS (SELECT 1 FROM dbo.LedgerEntry)
BEGIN
  INSERT INTO dbo.LedgerEntry (AccountId, MerchantId, GroupId, CategoryId, Amount, UserDate, LastModifiedUtc) VALUES
    (1, 1, 1, @Col, 505.00, '2025-02-21 00:00:00 -06:00', @CurUtc),
    (1, 1, 1, @Col, -5.99, '2025-03-21 00:00:00 -05:00', @CurUtc),
    (1, 1, 1, @Col, -38.73, '2025-03-26 00:00:00 -05:00', @CurUtc),
    (1, 1, 1, @Col, -173.22, '2025-03-31 00:00:00 -05:00', @CurUtc),
    (1, 1, 1, @Col, -65, '2025-04-06 00:00:00 -05:00', @CurUtc),
    (1, 1, 1, @Col, 500, '2025-04-13 00:00:00 -05:00', @CurUtc);
END
