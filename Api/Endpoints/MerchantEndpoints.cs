using Api.Contracts;
using Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Api.Endpoints;

public static class MerchantEndpoints
{
    public static void MapMerchantEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/merchants", async (FinanceDbContext db) => {
            const int DevGroupId = 1; // stands in for the authenticated identity

            var merchants = await db.GroupMerchant
                .Where(m => m.GroupId == DevGroupId)
                .OrderBy(m => m.Name ?? m.Merchant.Name).ThenBy(m => m.Id)
                .Select(m => new MerchantLi
                {
                    Id = m.Id,
                    Name = m.Name ?? m.Merchant.Name
                })
                .ToListAsync();

            return merchants;
        });

    }
}
