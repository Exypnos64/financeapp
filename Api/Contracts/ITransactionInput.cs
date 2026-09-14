namespace Api.Contracts;

public interface ITransactionInput
{
    int AccountId { get; }
    int MerchantId { get; }
    int CategoryId { get; }
    DateTimeOffset UserDate { get; }
    decimal? CashBack { get; }
    string? Notes { get; }
}