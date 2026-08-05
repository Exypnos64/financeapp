namespace Api.Entities;

public class LedgerEntry
{
    public int Id { get; set; }

    public int GroupId { get; set; }
    public UserGroup Group { get; set; } = null!;

    public int AccountId { get; set; }
    public Account Account { get; set; } = null!;

    public int MerchantId { get; set; }
    public GroupMerchant Merchant { get; set; } = null!;

    public int CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    public decimal Amount { get; set; }
    public decimal? CashBack { get; set; }
    public DateTimeOffset UserDate { get; set; }
    public string? Notes { get; set; }
    public string? OriginalStatement { get; set; }
    public DateTimeOffset? OriginalDate { get; set; }
    public DateTime LastModifiedUtc { get; set; }
}
