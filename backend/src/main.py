from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import date, timedelta
from . import models, plaid_client
from .database import engine, get_db

# Create database tables if they don't exist
models.Base.metadata.create_all(bind=engine)

# Create FastAPI app
app = FastAPI(title="Finance API")

# CORS for Svelte frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Svelte dev server
    allow_credentials=True,
    allow_methods=["*"],                      # Allow GET, POST, etc.
    allow_headers=["*"],
)


# Pydantic models for request/response
class LinkTokenResponse(BaseModel):
    link_token: str


class PublicTokenRequest(BaseModel):
    public_token: str


class TransactionResponse(BaseModel):
    id: int
    amount: float
    date: date
    name: str
    category: str | None
    
    class Config:
        from_attributes = True  # Allows converting SQLAlchemy models to Pydantic


@app.get("/")
async def root():
    return {"message": "Finance API"}


@app.post("/api/plaid/create_link_token", response_model=LinkTokenResponse)
async def create_link_token_route():
    """Frontend calls this to get a link_token, then opens Plaid Link UI"""
    try:
        # In production, get user_id from authenticated session
        user_id = "test_user_123"  # Hardcoded for now, later get from auth session
        response = await plaid_client.create_link_token(user_id)
        return {"link_token": response['link_token']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/plaid/exchange_public_token")
async def exchange_token_route(request: PublicTokenRequest, db: Session = Depends(get_db)):
    """After user connects bank, frontend sends public_token here to be saved"""
    try:
        # Exchange token with Plaid
        response = await plaid_client.exchange_public_token(request.public_token)
        access_token = response['access_token']
        
        # Save account to database
        # In production, also fetch and save account details
        account = models.Account(
            user_id="test_user_123",
            plaid_access_token=access_token,
            name="Connected Account"
        )
        db.add(account)
        db.commit()
        
        return {"success": True, "account_id": account.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/transactions", response_model=list[TransactionResponse])
async def get_transactions_route(db: Session = Depends(get_db)):
    """Return first 100 transactions from database"""
    transactions = db.query(models.Transaction).order_by(models.Transaction.date.desc()).limit(100).all()
    return transactions


@app.post("/api/plaid/sync_transactions")
async def sync_transactions_route(account_id: int, db: Session = Depends(get_db)):
    """Sync transactions from Plaid for an account"""
    try:
        # Get account from database
        account = db.query(models.Account).filter(models.Account.id == account_id).first()
        if not account:
            raise HTTPException(status_code=404, detail="Account not found")
        
        # Get last 30 days of transactions
        end_date = date.today()
        start_date = end_date - timedelta(days=30)
        
        # Fetch from Plaid
        response = await plaid_client.get_transactions(
            account.plaid_access_token,
            start_date.isoformat(),
            end_date.isoformat()
        )
        
        # Save transactions to database
        for txn in response['transactions']:
            # Check if already exists (avoid duplicates)
            existing = db.query(models.Transaction).filter(
                models.Transaction.plaid_transaction_id == txn['transaction_id']
            ).first()
            
            if not existing:
                transaction = models.Transaction(
                    account_id=account.id,
                    plaid_transaction_id=txn['transaction_id'],
                    amount=txn['amount'],
                    date=txn['date'],
                    name=txn['name'],
                    merchant_name=txn.get('merchant_name'),
                    category=','.join(txn.get('category', [])),  # Join array into string
                    pending=1 if txn['pending'] else 0
                )
                db.add(transaction)
        
        db.commit()  # Save all transactions at once
        return {"success": True, "synced": len(response['transactions'])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)