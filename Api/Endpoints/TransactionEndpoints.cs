using Api.Contracts;
using Api.Data;
using Api.Entities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Api.Endpoints;

public static class TransactionEndpoints
{
    private static async Task<IResult?> ValidateTransaction(ITransactionInput entry, FinanceDbContext db)
    {
        const int NoteLengthMax = 1000; // [dbo].[LedgerEntry].[Notes] = NVARCHAR(1000) NULL

        if (entry.Notes != null && entry.Notes.Length > NoteLengthMax)
            return Results.UnprocessableEntity($"Notes length cannot be over {NoteLengthMax} characters.");

        if (entry.CashBack != null && entry.CashBack < 0)
            return Results.UnprocessableEntity("CashBack cannot be less than $0.00.");

        var accountOk = await db.Account.OwnedBy(TempDefaults.DevGroupId).AnyAsync(a => a.Id == entry.AccountId);
        if (!accountOk)
            return Results.UnprocessableEntity($"Account {entry.AccountId} not found.");

        var merchantOk = await db.GroupMerchant.OwnedBy(TempDefaults.DevGroupId).AnyAsync(m => m.Id == entry.MerchantId);
        if (!merchantOk)
            return Results.UnprocessableEntity($"Merchant {entry.MerchantId} not found.");

        var categoryOk = await db.Category.OwnedBy(TempDefaults.DevGroupId).AnyAsync(c => c.Id == entry.CategoryId);
        if (!categoryOk)
            return Results.UnprocessableEntity($"Category {entry.CategoryId} not found.");

        return null;
    }

    public static void MapTransactionEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/transactions", async (FinanceDbContext db) => 
            await db.LedgerEntry.OwnedBy(TempDefaults.DevGroupId).Select(TransactionLi.FromLedgerEntry).ToListAsync()
        );

        app.MapGet("/transactions/{id:int}", async (int id, FinanceDbContext db) =>
        {
            var entry = await db.LedgerEntry
                .OwnedBy(TempDefaults.DevGroupId)
                .Where(t => t.Id == id)
                .Select(TransactionDto.FromLedgerEntry)
                .SingleOrDefaultAsync();

            if (entry is null)
                return Results.NotFound();
            
            return Results.Ok(entry);
        });

        app.MapPost("/transactions", async (CreateTransactionRequest req, FinanceDbContext db) =>
        {
            IResult? validationError = await ValidateTransaction(req, db);
            if (validationError is not null)
                return validationError;

            var transactionById = async (int id) => await db.LedgerEntry
                .OwnedBy(TempDefaults.DevGroupId)
                .Where(l => l.Id == id)
                .Select(TransactionLi.FromLedgerEntry)
                .SingleAsync();

            var findGuidMatch = async () => await db.LedgerEntry
                .OwnedBy(TempDefaults.DevGroupId)
                .Where(e => e.IdempotencyKey == req.IdempotencyKey)
                .SingleOrDefaultAsync();
            
            var compareReqGuid = (CreateTransactionRequest request, LedgerEntry match) => request.AccountId == match.AccountId
                    && request.Amount == match.Amount
                    && request.CashBack == match.CashBack
                    && request.CategoryId == match.CategoryId
                    && request.MerchantId == match.MerchantId
                    && request.Notes == match.Notes
                    && request.UserDate == match.UserDate;

            LedgerEntry? guidMatch = await findGuidMatch();

            if (guidMatch is not null)
            {
                if (compareReqGuid(req, guidMatch))
                    return Results.Created($"/transactions/{guidMatch.Id}", await transactionById(guidMatch.Id));
                else
                    return Results.Conflict("This UUID is already in use.");
            }

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
                LastModifiedUtc = DateTime.UtcNow,
                IdempotencyKey = req.IdempotencyKey
            };

            db.LedgerEntry.Add(entry);
            try
            {
                await db.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
                when (ex.InnerException is SqlException sqlEx && (sqlEx.Number == 2627))
            {
                guidMatch = await findGuidMatch();

                if (guidMatch is not null)
                {
                    if (compareReqGuid(req, guidMatch))
                        return Results.Created($"/transactions/{guidMatch.Id}", await transactionById(guidMatch.Id));
                    else
                        return Results.Conflict("This UUID is already in use.");
                }
                else throw;
            }

            return Results.Created($"/transactions/{entry.Id}", await transactionById(entry.Id));
        });

        app.MapPut("/transactions/{id:int}", async (int id, UpdateTransactionRequest req, FinanceDbContext db) =>
        {
            IResult? validationError = await ValidateTransaction(req, db);
            if (validationError is not null)
                return validationError;

            var entry = await db.LedgerEntry
                .OwnedBy(TempDefaults.DevGroupId)
                .Where(t => t.Id == id)
                .SingleOrDefaultAsync();

            if (entry is null)
                return Results.NotFound($"There is no entry with Id {id}.");

            // Updating database entity
            entry.AccountId = req.AccountId;
            entry.MerchantId = req.MerchantId;
            entry.CategoryId = req.CategoryId;
            entry.Amount = req.Amount;
            entry.CashBack = req.CashBack;
            entry.UserDate = req.UserDate;
            entry.Notes = req.Notes;
            entry.LastModifiedUtc = DateTime.UtcNow;

            await db.SaveChangesAsync();
            return Results.NoContent();
        });

        app.MapDelete("/transactions/{id:int}", async (int id, FinanceDbContext db) =>
        {
            var entry = await db.LedgerEntry
                .OwnedBy(TempDefaults.DevGroupId)
                .Where(t => t.Id == id)
                .SingleOrDefaultAsync();

            if (entry is null)
                return Results.NotFound($"There is no entry with Id {id}.");
            
            db.LedgerEntry.Remove(entry);
            await db.SaveChangesAsync();
            return Results.NoContent();
        });
    }
}
