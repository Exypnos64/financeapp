CREATE TABLE Category(
    Id INT IDENTITY(1,1),
    GroupId INT NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    IconName NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_Category PRIMARY KEY (Id),
    CONSTRAINT FK_Category_CategoryGroup FOREIGN KEY (GroupId) REFERENCES CategoryGroup(Id)
);
