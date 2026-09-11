using Api.Entities;

namespace Api.Data;

public static class GroupOwnedQuery
{
    public static IQueryable<T> OwnedBy<T>(this IQueryable<T> source, int groupId) where T : IGroupOwned
    {
        return source.Where(c => c.GroupId == groupId);
    }
}