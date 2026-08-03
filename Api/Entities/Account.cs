namespace Api.Entities;

public class Account
{
    public int Id { get; set; }


    public int GroupId { get; set; }

    public UserGroup Group { get; set; } = null!;

    public byte TypeId { get; set; }
    public required string Name { get; set; }
    public DateTime StartDateUtc { get; set; }
    public bool IsActive { get; set; }
    public decimal StartBalance { get; set; }
    public DateTime LastModifiedUtc { get; set; }
}
