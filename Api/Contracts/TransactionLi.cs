using System.Linq.Expressions;
using Api.Entities;

namespace Api.Contracts;

public record TransactionLi
{
    public int Id { get; init; }
    public required string Account { get; init; }
    public required string Merchant { get; init; }
    public required string Category { get; init; }
    public decimal Amount { get; init; }
    public decimal? CashBack { get; init; }
    public DateTimeOffset UserDate { get; init; }

    public static readonly Expression<Func<LedgerEntry, TransactionLi>> FromLedgerEntry =
        e => new TransactionLi
        {
            Id = e.Id,
            Account = e.Account.Name,
            Merchant = e.Merchant.Name ?? e.Merchant.Merchant.Name,
            Category = e.Category.Name,
            Amount = e.Amount,
            CashBack = e.CashBack,
            UserDate = e.UserDate
        };
}
