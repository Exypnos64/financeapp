USE FinanceDb;
TRUNCATE Table dbo.LedgerEntry;

DECLARE @CurUtc AS DATETIME2(7);
SET @CurUtc = SYSUTCDATETIME();

-- DECLARE @CurLocal AS DATETIMEOFFSET;
-- SET @CurLocal = SYSDATETIMEOFFSET();

IF NOT EXISTS (SELECT 1 FROM dbo.LedgerEntry)
BEGIN
  INSERT INTO dbo.LedgerEntry (AccountId, MerchantId, GroupId, CategoryId, Amount, UserDate, LastModifiedUtc) VALUES
      (1, 3, 1, (SELECT Id FROM Category WHERE GroupId = 1 AND DefaultId = 49), 505.00,   '2025-02-21 00:00:00 -06:00', @CurUtc)
    , (1, 6, 1, (SELECT Id FROM Category WHERE GroupId = 1 AND DefaultId = 13), -5.99,    '2025-03-21 00:00:00 -05:00', @CurUtc)
    , (1, 4, 1, (SELECT Id FROM Category WHERE GroupId = 1 AND DefaultId = 25), -38.73,   '2025-03-26 00:00:00 -05:00', @CurUtc)
    , (1, 7, 1, (SELECT Id FROM Category WHERE GroupId = 1 AND DefaultId = 12), -173.22,  '2025-03-31 00:00:00 -05:00', @CurUtc)
    , (1, 7, 1, (SELECT Id FROM Category WHERE GroupId = 1 AND DefaultId = 32), -65,      '2025-04-06 00:00:00 -05:00', @CurUtc)
    , (1, 3, 1, (SELECT Id FROM Category WHERE GroupId = 1 AND DefaultId = 49), 500,      '2025-04-13 00:00:00 -05:00', @CurUtc);
END
GO
