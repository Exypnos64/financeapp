namespace Api.Data;

using Api.Models;
using Microsoft.EntityFrameworkCore;

public class FinanceDbContext : DbContext
{
    public FinanceDbContext(DbContextOptions<FinanceDbContext> options) : base(options) { }

    public DbSet<Access> Access => Set<Access>();
    public DbSet<Account> Account => Set<Account>();
    public DbSet<Category> Category => Set<Category>();
    public DbSet<CategoryGroup> CategoryGroup => Set<CategoryGroup>();
    public DbSet<EndUser> EndUser => Set<EndUser>();
    public DbSet<LedgerEntry> LedgerEntry => Set<LedgerEntry>();
    public DbSet<Merchant> Merchant => Set<Merchant>();
}
