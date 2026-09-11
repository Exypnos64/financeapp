-- This changes if more seed rows are added.
DECLARE @Rows AS INT;
SET @Rows = 6;

DELETE FROM [dbo].[LedgerEntry]
  WHERE Id > @Rows;

DBCC CHECKIDENT('dbo.LedgerEntry', RESEED, @Rows);
GO
