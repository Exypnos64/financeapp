CREATE TABLE CategorySet(
    Id INT IDENTITY(1,1),
    GroupId INT NOT NULL,
    DefaultId INT NULL,
    Name NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_CategorySet PRIMARY KEY (Id),
    CONSTRAINT FK_CategorySet_UserGroup FOREIGN KEY (GroupId) REFERENCES UserGroup(Id),
    CONSTRAINT FK_CategorySet_DefaultCategorySet FOREIGN KEY (DefaultId) REFERENCES DefaultCategorySet(Id),
    CONSTRAINT UQ_CategorySet_GroupId_Id UNIQUE (GroupId, Id)
);
