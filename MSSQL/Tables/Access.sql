CREATE TABLE Access (
    UserId INT NOT NULL,
    AccountId INT NOT NULL,
    PermissionLevel TINYINT NOT NULL,
    GrantedByUserId INT NULL,
    GrantedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Access_GrantedAtUtc DEFAULT SYSUTCDATETIME(),
    ExpireAtUtc DATETIME2 NULL,

    CONSTRAINT PK_Access PRIMARY KEY (UserId, AccountId),
    CONSTRAINT FK_Access_EndUser_UserId FOREIGN KEY (UserId) REFERENCES EndUser(Id),
    CONSTRAINT FK_Access_EndUser_GrantedByUserId FOREIGN KEY (GrantedByUserId) REFERENCES EndUser(Id),
    CONSTRAINT FK_Access_Account FOREIGN KEY (AccountId) REFERENCES Account(Id),
    CONSTRAINT CK_Access_PermissionLevel CHECK (PermissionLevel BETWEEN 1 AND 3)
);
