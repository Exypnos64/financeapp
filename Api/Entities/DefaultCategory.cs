namespace Api.Entities;

public class DefaultCategory
{
    public int Id { get; set; }

    public int SetId { get; set; }
    public DefaultCategorySet Set { get; set; } = null!;

    public required string Name { get; set; }
    public required string IconName { get; set; }
}
