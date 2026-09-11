using Api.Contracts;
using Api.Data;
using Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Api.Endpoints;

public static class TransactionEndpoints
{
    public static void MapTransactionEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/transactions", async (FinanceDbContext db) => 
            await db.LedgerEntry.OwnedBy(TempDefaults.DevGroupId).Select(TransactionLi.FromLedgerEntry).ToListAsync()
        );

        app.MapPost("/transactions", async (CreateTransactionRequest req, FinanceDbContext db) =>
        {
            const int NoteLengthMax = 1000; // [dbo].[LedgerEntry].[Notes] = NVARCHAR(1000) NULL

            if (req.Notes != null && req.Notes.Length > NoteLengthMax)
                return Results.UnprocessableEntity($"Notes length cannot be over {NoteLengthMax} characters.");

            if (req.CashBack != null && req.CashBack < 0)
                return Results.UnprocessableEntity("CashBack cannot be less than $0.00.");

            var accountOk = await db.Account.OwnedBy(TempDefaults.DevGroupId).AnyAsync(a => a.Id == req.AccountId);
            if (!accountOk)
                return Results.UnprocessableEntity($"Account {req.AccountId} not found.");

            var merchantOk = await db.GroupMerchant.OwnedBy(TempDefaults.DevGroupId).AnyAsync(m => m.Id == req.MerchantId);
            if (!merchantOk)
                return Results.UnprocessableEntity($"Merchant {req.MerchantId} not found.");

            var categoryOk = await db.Category.OwnedBy(TempDefaults.DevGroupId).AnyAsync(c => c.Id == req.CategoryId);
            if (!categoryOk)
                return Results.UnprocessableEntity($"Category {req.CategoryId} not found.");

            var entry = new LedgerEntry
            {
                GroupId = TempDefaults.DevGroupId,
                AccountId = req.AccountId,
                MerchantId = req.MerchantId,
                CategoryId = req.CategoryId,
                Amount = req.Amount,
                CashBack = req.CashBack,
                UserDate = req.UserDate,
                Notes = req.Notes,
                LastModifiedUtc = DateTime.UtcNow
            };

            db.LedgerEntry.Add(entry);
            await db.SaveChangesAsync();

            var created = await db.LedgerEntry
                .OwnedBy(TempDefaults.DevGroupId)
                .Where(l => l.Id == entry.Id)
                .Select(TransactionLi.FromLedgerEntry)
                .SingleAsync();

            return Results.Created($"/transactions/{entry.Id}", created);
        });
    }
}
