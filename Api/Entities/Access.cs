namespace Api.Entities;

using Microsoft.EntityFrameworkCore;

[PrimaryKey("UserId", "AccountId")]
public class Access
{
    public int UserId { get; set; }
    public int AccountId { get; set; }
    public byte PermissionLevel { get; set; }
    public int? GrantedByUserId { get; set; }
    public DateTime GrantedAtUtc { get; set; }
    public DateTime? ExpireAtUtc { get; set; }
}
