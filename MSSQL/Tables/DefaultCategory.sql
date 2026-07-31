CREATE TABLE DefaultCategory (
    Id INT IDENTITY(1,1),
    SetId INT NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    IconName NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_DefaultCategory PRIMARY KEY (Id),
    CONSTRAINT FK_DefaultCategory_DefaultCategorySet FOREIGN KEY (SetId) REFERENCES DefaultCategorySet(Id)
);
