using Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Api.Endpoints;

public static class AccountEndpoints
{
    public static void MapAccountEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/accounts", async (FinanceDbContext db) => await db.Account.ToListAsync());
    }
}
