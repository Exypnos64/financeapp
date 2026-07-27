namespace Api.Contracts;

public record TransactionLi
{
    public int Id { get; init; }
    public required string Account { get; init; }
    public required string Merchant { get; init; }
    public required string Category { get; init; }
    public decimal Amount { get; init; }
    public decimal? CashBack { get; init; }
    public DateTime UserDateUtc { get; init; }
}
