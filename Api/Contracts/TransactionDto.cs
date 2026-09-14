using System.Linq.Expressions;
using Api.Entities;

namespace Api.Contracts;

public record TransactionDto
{
    public int Id { get; init; }
    public int AccountId { get; init; }
    public int MerchantId { get; init; }
    public int CategoryId { get; init; }
    public decimal Amount { get; init; }
    public decimal? CashBack { get; init; }
    public DateTimeOffset UserDate { get; init; }
    public string? Notes { get; init; }
    public string? OriginalStatement { get; init; }
    public DateTimeOffset? OriginalDate { get; init; }
    public DateTime LastModifiedUtc { get; init; }

    public static readonly Expression<Func<LedgerEntry, TransactionDto>> FromLedgerEntry =
        e => new TransactionDto
        {
            Id = e.Id,
            AccountId = e.AccountId,
            MerchantId = e.MerchantId,
            CategoryId = e.CategoryId,
            Amount = e.Amount,
            CashBack = e.CashBack,
            UserDate = e.UserDate,
            Notes = e.Notes,
            OriginalStatement = e.OriginalStatement,
            OriginalDate = e.OriginalDate,
            LastModifiedUtc = e.LastModifiedUtc
        };
}
