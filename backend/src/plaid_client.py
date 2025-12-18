import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.transactions_get_request import TransactionsGetRequest
from .config import settings

# Determine environment
if settings.plaid_env.lower() == "sandbox":
    plaid_env = plaid.Environment.Sandbox
elif settings.plaid_env.lower() == "development":
    plaid_env = plaid.Environment.Development
else:
    plaid_env = plaid.Environment.Production

# Initialize Plaid client with credentials
configuration = plaid.Configuration(
    host=plaid_env,
    api_key={
        'clientId': settings.plaid_client_id,
        'secret': settings.plaid_secret,
    }
)

# # Initialize Plaid client with credentials
# configuration = plaid.Configuration(
#     host=getattr(plaid.Environment, settings.plaid_env.capitalize()),
#     api_key={
#         'clientId': settings.plaid_client_id,
#         'secret': settings.plaid_secret,
#     }
# )

api_client = plaid.ApiClient(configuration)
client = plaid_api.PlaidApi(api_client)


async def create_link_token(user_id: str):
    """
    Creates a Link token - needed to initialize Plaid Link UI
    The Link UI is what users interact with to connect their bank
    """
    try:
        request = LinkTokenCreateRequest(
            products=[Products("transactions")],      # What data you want access to
            client_name="Finance App",                # Shown to users in Plaid Link
            country_codes=[CountryCode('US')],
            language='en',
            user=LinkTokenCreateRequestUser(client_user_id=user_id)  # Your internal user ID
        )
        response = client.link_token_create(request)  # Calls Plaid API
        return response.to_dict()                     # Returns {'link_token': '...'}
    except plaid.ApiException as e:
        raise Exception(f"Plaid API error: {e}")


async def exchange_public_token(public_token: str):
    """
    Exchange the temporary public_token for a permanent access_token
    Store this access_token in your database - you'll use it for all future API calls
    """
    try:
        from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
        request = ItemPublicTokenExchangeRequest(public_token=public_token)
        response = client.item_public_token_exchange(request)
        return response.to_dict()
    except plaid.ApiException as e:
        raise Exception(f"Plaid API error: {e}")


async def get_transactions(access_token: str, start_date: str, end_date: str):
    """
    Fetch transactions for a connected account
    Dates in ISO format: '2024-01-01'
    """
    try:
        request = TransactionsGetRequest(
            access_token=access_token,
            start_date=start_date,
            end_date=end_date
        )
        response = client.transactions_get(request)
        return response.to_dict()
    except plaid.ApiException as e:
        raise Exception(f"Plaid API error: {e}")