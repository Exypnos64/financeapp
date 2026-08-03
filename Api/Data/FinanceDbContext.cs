namespace Api.Data;

using Api.Entities;
using Microsoft.EntityFrameworkCore;

public class FinanceDbContext : DbContext
{
    public FinanceDbContext(DbContextOptions<FinanceDbContext> options) : base(options) { }

    public DbSet<Account> Account => Set<Account>();
    public DbSet<Category> Category => Set<Category>();
    public DbSet<CategorySet> CategorySet => Set<CategorySet>();
    public DbSet<DefaultCategory> DefaultCategory => Set<DefaultCategory>();
    public DbSet<DefaultCategorySet> DefaultCategorySet => Set<DefaultCategorySet>();
    public DbSet<EndUser> EndUser => Set<EndUser>();
    public DbSet<GroupMember> GroupMember => Set<GroupMember>();
    public DbSet<GroupMerchant> GroupMerchant => Set<GroupMerchant>();
    public DbSet<LedgerEntry> LedgerEntry => Set<LedgerEntry>();
    public DbSet<Merchant> Merchant => Set<Merchant>();
    public DbSet<UserGroup> UserGroup => Set<UserGroup>();
}
