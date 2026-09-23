namespace Api.Contracts;

public record CreateTransactionRequest : ITransactionInput
{
    public required int AccountId { get; init; }
    public required int MerchantId { get; init; }
    public required int CategoryId { get; init; }
    public required decimal Amount { get; init; }
    public decimal? CashBack { get; init; }
    public required DateTimeOffset UserDate { get; init; }
    public string? Notes { get; init; }
    public required Guid IdempotencyKey { get; init; }
}
