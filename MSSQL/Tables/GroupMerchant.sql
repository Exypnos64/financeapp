CREATE TABLE GroupMerchant (
    Id INT IDENTITY(1,1),
    GroupId INT NOT NULL,
    MerchantId INT NOT NULL,
    Name NVARCHAR(100) NULL,
    PicPath NVARCHAR(500) NULL,

    CONSTRAINT PK_GroupMerchant PRIMARY KEY (Id),
    CONSTRAINT FK_GroupMerchant_UserGroup FOREIGN KEY (GroupId) REFERENCES UserGroup(Id),
    CONSTRAINT FK_GroupMerchant_Merchant FOREIGN KEY (MerchantId) REFERENCES Merchant(Id),
    CONSTRAINT UQ_GroupMerchant_GroupId_MerchantId UNIQUE (GroupId, MerchantId),
    CONSTRAINT UQ_GroupMerchant_GroupId_Id UNIQUE (GroupId, Id)
);
