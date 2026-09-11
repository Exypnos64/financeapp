using Api.Contracts;
using Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Api.Endpoints;

public static class CategoryEndpoints
{
    public static void MapCategoryEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/categories", async (FinanceDbContext db) => {
            var categories = await db.Category
                .OwnedBy(TempDefaults.DevGroupId)
                .OrderBy(c => c.Set.Name).ThenBy(c => c.SetId).ThenBy(c => c.Name)
                .Select(c => new CategoryLi
                {
                    Id = c.Id,
                    Name = c.Name,
                    Set = new CategorySetLi
                    {
                        Id = c.Set.Id,
                        Name = c.Set.Name
                    }
                })
                .ToListAsync();

            return categories;
        });

    }
}
