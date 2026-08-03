namespace Api.Entities;

using Microsoft.EntityFrameworkCore;

[PrimaryKey("UserId", "GroupId")]
public class GroupMember
{
    public int UserId { get; set; }
    public EndUser User { get; set; } = null!;

    public int GroupId { get; set; }
    public UserGroup Group { get; set; } = null!;

    public byte PermissionLevel { get; set; }

    public int? GrantedByUserId { get; set; }
    public EndUser? GrantedByUser { get; set; } = null;

    public DateTime GrantedAtUtc { get; set; }
    public DateTime? ExpireAtUtc { get; set; }
}
