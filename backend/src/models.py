from sqlalchemy import String, ForeignKey, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from datetime import datetime


class Base(DeclarativeBase):
    pass


class Account(Base):
    __tablename__ = "accounts"        # Table name in MySQL
    
    # Define column type annotations with Mapped[]
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[str] = mapped_column(String(50))
    plaid_account_id: Mapped[str | None] = mapped_column(String(100), unique=True)
    plaid_access_token: Mapped[str | None] = mapped_column(String(200))      # Stores Plaid access token
    name: Mapped[str | None] = mapped_column(String(100))                    # Account nickname
    official_name: Mapped[str | None] = mapped_column(String(100))           # Bank's official name
    type: Mapped[str | None] = mapped_column(String(50))                     # checking, savings, credit, etc.
    subtype: Mapped[str | None] = mapped_column(String(50))                  # More specific type
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    
    # Relationships: one account has many transactions - note the list type annotation
    transactions: Mapped[list["Transaction"]] = relationship(back_populates="account", cascade="all, delete", passive_deletes=True)


class Transaction(Base):
    __tablename__ = "transactions"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id", ondelete="CASCADE"))      # Links to Account.id
    plaid_transaction_id: Mapped[str | None] = mapped_column(String(100), unique=True)
    amount: Mapped[float] = mapped_column()
    date: Mapped[datetime] = mapped_column()
    name: Mapped[str | None] = mapped_column(String(200))                                       # Transaction description
    merchant_name: Mapped[str | None] = mapped_column(String(200))
    category: Mapped[str | None] = mapped_column(String(100))                                   # e.g., "Food and Drink"
    pending: Mapped[int] = mapped_column(default=0)                                             # 0 = settled, 1 = pending
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    
    # Relationship: this transaction belongs to one account - single object
    account: Mapped["Account"] = relationship(back_populates="transactions")