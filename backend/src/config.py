from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Define what settings you expect
    plaid_client_id: str              # Type hints for validation
    plaid_secret: str
    plaid_env: str = "sandbox"        # Default value if not in .env
    
    mysql_host: str
    mysql_port: int = 3306
    mysql_user: str
    mysql_password: str
    mysql_database: str
    
    class Config:
        env_file = ".env"             # Tell pydantic to load from .env

# Create a single instance to use throughout your app
settings = Settings()