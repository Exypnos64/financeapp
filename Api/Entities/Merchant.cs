namespace Api.Entities;

public class Merchant
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public string? PicPath { get; set; }
    public bool Reviewed { get; set; }
    public bool Approved { get; set; }
}
