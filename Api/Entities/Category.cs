namespace Api.Entities;

public class Category
{
    public int Id { get; set; }

    public int GroupId { get; set; }
    public UserGroup Group { get; set; } = null!;

    public int? DefaultId { get; set; }
    public DefaultCategory? Default { get; set; } = null;
    
    public int SetId { get; set; }
    public CategorySet? Set { get; set; } = null;

    public required string Name { get; set; }
    public required string IconName { get; set; }
}
