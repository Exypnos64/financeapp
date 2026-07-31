CREATE TABLE Category(
    Id INT IDENTITY(1,1),
    GroupId INT NOT NULL,
    DefaultId INT NULL,
    SetId INT NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    IconName NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_Category PRIMARY KEY (Id),
    CONSTRAINT FK_Category_UserGroup FOREIGN KEY (GroupId) REFERENCES UserGroup(Id),
    CONSTRAINT FK_Category_DefaultCategory FOREIGN KEY (DefaultId) REFERENCES DefaultCategory(Id),
    CONSTRAINT FK_Category_CategorySet FOREIGN KEY (GroupId, SetId) REFERENCES CategorySet(GroupId, Id),
    CONSTRAINT UQ_Category_GroupId_Id UNIQUE (GroupId, Id)
);
