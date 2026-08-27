namespace Api.Contracts;

public record CategoryLi
{
    public int Id { get; init; }
    public required string Name { get; init; }
    public required CategorySetLi Set { get; init; }
}