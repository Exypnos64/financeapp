CREATE TABLE GroupMember (
    UserId INT NOT NULL,
    GroupId INT NOT NULL,
    PermissionLevel TINYINT NOT NULL,
    GrantedByUserId INT NULL,
    GrantedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_GroupMember_GrantedAtUtc DEFAULT SYSUTCDATETIME(),
    ExpireAtUtc DATETIME2 NULL,

    CONSTRAINT PK_GroupMember PRIMARY KEY (UserId, GroupId),
    CONSTRAINT FK_GroupMember_EndUser_UserId FOREIGN KEY (UserId) REFERENCES EndUser(Id),
    CONSTRAINT FK_GroupMember_EndUser_GrantedByUserId FOREIGN KEY (GrantedByUserId) REFERENCES EndUser(Id),
    CONSTRAINT FK_GroupMember_UserGroup FOREIGN KEY (GroupId) REFERENCES UserGroup(Id),
    CONSTRAINT CK_GroupMember_PermissionLevel CHECK (PermissionLevel BETWEEN 1 AND 3)
);
