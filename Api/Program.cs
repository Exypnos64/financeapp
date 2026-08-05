using Api.Contracts;
using Api.Data;
using Api.Entities;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
var originPolicy = "_allowLocal";

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddDbContext<FinanceDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: originPolicy,
    policy =>
    {
        policy.WithOrigins("http://localhost:5173");
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
else
{
    app.UseHttpsRedirection();
}

app.UseCors(originPolicy);

app.MapGet("/accounts", async (FinanceDbContext db) => await db.Account.ToListAsync());
app.MapGet("/transactions", async (FinanceDbContext db) => 
    await db.LedgerEntry.Select(e => new TransactionLi
    {
        Id = e.Id,
        Account = e.Account.Name,
        Merchant = e.Merchant.Name ?? e.Merchant.Merchant.Name,
        Category = e.Category.Name,
        Amount = e.Amount,
        CashBack = e.CashBack,
        UserDate = e.UserDate
    }).ToListAsync()
);

app.MapPost("/transactions", async (CreateTransactionRequest req, FinanceDbContext db) =>
{
    const int DevGroupId = 1; // stands in for the authenticated identity
    const int NoteLengthMax = 1000; // [dbo].[LedgerEntry].[Notes] = NVARCHAR(1000) NULL

    if (req.Notes != null && req.Notes.Length > NoteLengthMax)
        return Results.UnprocessableEntity($"Notes length cannot be over {NoteLengthMax} characters.");

    if (req.CashBack != null && req.CashBack < 0)
        return Results.UnprocessableEntity("CashBack cannot be less than $0.00.");

    var accountOk = await db.Account.AnyAsync(a => a.Id == req.AccountId && a.GroupId == DevGroupId);
    if (!accountOk)
        return Results.UnprocessableEntity($"Account {req.AccountId} not found.");

    var merchantOk = await db.GroupMerchant.AnyAsync(m => m.Id == req.MerchantId && m.GroupId == DevGroupId);
    if (!merchantOk)
        return Results.UnprocessableEntity($"Merchant {req.MerchantId} not found.");

    var categoryOk = await db.Category.AnyAsync(c => c.Id == req.CategoryId && c.GroupId == DevGroupId);
    if (!categoryOk)
        return Results.UnprocessableEntity($"Category {req.CategoryId} not found.");

    var entry = new LedgerEntry
    {
        GroupId = DevGroupId,
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
        .Where(l => l.Id == entry.Id)
        .Select(l => new TransactionLi
        {
            Id = l.Id,
            Account = l.Account.Name,
            Merchant = l.Merchant.Name ?? l.Merchant.Merchant.Name,
            Category = l.Category.Name,
            Amount = l.Amount,
            CashBack = l.CashBack,
            UserDate = l.UserDate
        })
        .SingleAsync();

    return Results.Created($"/transactions/{entry.Id}", created);
});

app.Run();
