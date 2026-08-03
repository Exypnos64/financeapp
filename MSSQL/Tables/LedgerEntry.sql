CREATE TABLE LedgerEntry (
    Id INT IDENTITY(1,1),
    AccountId INT NOT NULL,
    MerchantId INT NOT NULL,
    GroupId INT NOT NULL,
    CategoryId INT NOT NULL,
    Amount DECIMAL(19,4) NOT NULL,
    CashBack DECIMAL(19,4) NULL,
    UserDate DATETIMEOFFSET NOT NULL,
    Notes NVARCHAR(1000) NULL,
    OriginalStatement NVARCHAR(500) NULL,
    OriginalDate DATETIMEOFFSET NULL,
    LastModifiedUtc DATETIME2 NOT NULL CONSTRAINT DF_LedgerEntry_LastModifiedUtc DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_LedgerEntry PRIMARY KEY (Id),

    CONSTRAINT FK_LedgerEntry_UserGroup FOREIGN KEY (GroupId) REFERENCES UserGroup(Id),

    CONSTRAINT FK_LedgerEntry_Account FOREIGN KEY (GroupId, AccountId) REFERENCES Account(GroupId, Id),
    CONSTRAINT FK_LedgerEntry_GroupMerchant FOREIGN KEY (GroupId, MerchantId) REFERENCES GroupMerchant(GroupId, Id),
    CONSTRAINT FK_LedgerEntry_Category FOREIGN KEY (GroupId, CategoryId) REFERENCES Category(GroupId, Id)
);
