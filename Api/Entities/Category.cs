namespace Api.Entities;

public class Category
{
    public int Id { get; set; }
    public int GroupId { get; set; }
    public required string Name { get; set; }
    public required string IconName { get; set; }
}
