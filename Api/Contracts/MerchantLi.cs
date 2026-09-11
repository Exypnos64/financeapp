namespace Api.Contracts;

public record MerchantLi
{
    public int Id { get; init; }
    public required string Name { get; init; }
}