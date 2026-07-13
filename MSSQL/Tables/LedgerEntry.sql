CREATE TABLE LedgerEntry (
    Id INT IDENTITY(1,1),
    AccountId INT NOT NULL,
    MerchantId INT NOT NULL,
    CategoryId INT NOT NULL,
    Amount DECIMAL(19,4) NOT NULL,
    CashBack DECIMAL(19,4) NULL,
    UserDateUtc DATETIME2 NOT NULL,
    Notes NVARCHAR(1000) NULL,
    OriginalStatement NVARCHAR(500) NULL,
    OriginalDateUtc DATETIME2 NULL,
    LastModifiedUtc DATETIME2 NOT NULL CONSTRAINT DF_LedgerEntry_LastModifiedUtc DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_LedgerEntry PRIMARY KEY (Id),
    CONSTRAINT FK_LedgerEntry_Account FOREIGN KEY (AccountId) REFERENCES Account(Id),
    CONSTRAINT FK_LedgerEntry_Merchant FOREIGN KEY (MerchantId) REFERENCES Merchant(Id),
    CONSTRAINT FK_LedgerEntry_Category FOREIGN KEY (CategoryId) REFERENCES Category(Id)
);
