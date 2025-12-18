from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import settings

# Build connection string (like a connection URL)
# Format: mysql+pymysql://user:password@host:port/database
DATABASE_URL = f"mysql+pymysql://{settings.mysql_user}:{settings.mysql_password}@{settings.mysql_host}:{settings.mysql_port}/{settings.mysql_database}"

# Create engine - this is the connection pool to MySQL
engine = create_engine(DATABASE_URL)

# SessionLocal is a factory for creating database sessions
# A session is like a workspace where you do database operations
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for all your database models
class Base(DeclarativeBase):
    pass

# Dependency function for FastAPI routes
def get_db():
    """
    Creates a database session for each request, 
    yields it to the route, 
    then closes it when done
    """
    db = SessionLocal()
    try:
        yield db              # Give the session to the route
    finally:
        db.close()            # Always close it when done