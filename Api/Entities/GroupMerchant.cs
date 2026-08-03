namespace Api.Entities;

public class GroupMerchant
{
    public int Id { get; set; }

    public int GroupId { get; set; }
    public UserGroup Group { get; set; } = null!;

    public int MerchantId { get; set; }
    public Merchant Merchant { get; set; } = null!;

    public string? Name { get; set; }
    public string? PicPath { get; set; }
}
