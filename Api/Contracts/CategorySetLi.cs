namespace Api.Contracts;

public record CategorySetLi
{
    public int Id { get; init; }
    public required string Name { get; init; }
}