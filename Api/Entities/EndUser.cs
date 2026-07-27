namespace Api.Entities;

public class EndUser
{
    public int Id { get; set; }
    public required string Email { get; set; }
    public required string PasswordHash { get; set; }
    public required string FullName { get; set; }
    public required string PrefName { get; set; }
}
