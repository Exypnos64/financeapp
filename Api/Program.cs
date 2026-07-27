using Api.Contracts;
using Api.Data;
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

app.UseHttpsRedirection();

app.UseCors(originPolicy);

app.MapGet("/accounts", async (FinanceDbContext db) => await db.Account.ToListAsync());
app.MapGet("/transactions", async (FinanceDbContext db) => 
    await db.LedgerEntry.Select(e => new TransactionLi
    {
        Id = e.Id,
        Account = e.Account.Name,
        Merchant = e.Merchant.Name,
        Category = e.Category.Name,
        Amount = e.Amount,
        CashBack = e.CashBack,
        UserDateUtc = e.UserDateUtc
    }).ToListAsync()
);

app.Run();
