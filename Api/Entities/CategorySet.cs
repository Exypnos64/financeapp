namespace Api.Entities;

public class CategorySet
{
    public int Id { get; set; }

    public int GroupId { get; set; }
    public UserGroup Group { get; set; } = null!;

    public int DefaultId { get; set; }
    public DefaultCategorySet Default { get; set; } = null!;

    public required string Name { get; set; }
}
