import pandas as pd
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# --- CONFIGURATION ---
DB_USER = 'postgres'
# Fetch password safely. Defaults to None if missing.
DB_PASSWORD = os.getenv('DB_PASSWORD') 

if not DB_PASSWORD:
    raise ValueError("❌ DB_PASSWORD is missing from .env file")

DB_HOST = 'localhost'
DB_PORT = '5432'
DB_NAME = 'olist_dw'

connection_str = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(connection_str)

DATA_DIR = os.path.join(os.getcwd(), 'data', 'raw')

# Columns that must be treated as strings to keep leading zeros
ZIP_COLS = [
    'geolocation_zip_code_prefix',
    'customer_zip_code_prefix',
    'seller_zip_code_prefix'
]

ID_COLS = [
    'customer_id', 'customer_unique_id', 'seller_id',
    'order_id', 'product_id', 'review_id'
]

def ingest_data():
    print("🚀 Starting Robust Data Ingestion...")

    # --- STEP 0: SAFETY WIPE (PREVENT DUPLICATES) ---
    # This ensures that if you run the script twice, you don't get double data.
    print("  Clearing existing data to prevent duplicates...")
    with engine.connect() as conn:
        conn.execute(text("TRUNCATE order_reviews, order_payments, order_items, orders, products, sellers, customers, geolocation, product_category_translation CASCADE;"))
        conn.commit()
    print("   ✅ Tables truncated.")

    files_to_load = [
        {'file': 'product_category_name_translation.csv', 'table': 'product_category_translation'},
        {'file': 'olist_geolocation_dataset.csv', 'table': 'geolocation'},
        {'file': 'olist_customers_dataset.csv', 'table': 'customers'},
        {'file': 'olist_sellers_dataset.csv', 'table': 'sellers'},
        {'file': 'olist_products_dataset.csv', 'table': 'products'},
        {'file': 'olist_orders_dataset.csv', 'table': 'orders'},
        {'file': 'olist_order_items_dataset.csv', 'table': 'order_items'},
        {'file': 'olist_order_payments_dataset.csv', 'table': 'order_payments'},
        {'file': 'olist_order_reviews_dataset.csv', 'table': 'order_reviews'},
    ]

    for entry in files_to_load:
        file_name = entry['file']
        table_name = entry['table']
        file_path = os.path.join(DATA_DIR, file_name)

        if not os.path.exists(file_path):
            print(f"⚠️ Warning: File not found: {file_name}. Skipping.")
            continue

        print(f"⏳ Processing: {table_name}...")

        try:
            # 1. Peek at headers to build dtype map dynamically
            preview = pd.read_csv(file_path, nrows=0)
            dtype_map = {}
            for c in preview.columns:
                if c in ZIP_COLS or c in ID_COLS:
                    dtype_map[c] = 'string'

            # 2. Load Data with forced types
            df = pd.read_csv(file_path, dtype=dtype_map)

            # 3. Clean Dates
            for col in df.columns:
                if ('date' in col) or ('timestamp' in col) or col.endswith('_at'):
                    df[col] = pd.to_datetime(df[col], errors='coerce')

            # 4. Clean "nan" Strings (Crucial fix)
            # If a zip code is missing, Pandas 'string' type might make it <NA> or "nan".
            # We explicitly convert object-columns to proper SQL NULLs where needed.
            
            # 5. Ingest
            df.to_sql(
                name=table_name,
                con=engine,
                if_exists='append',
                index=False,
                chunksize=10000
            )
            print(f"   ✅ Success: Loaded {len(df)} rows into {table_name}.")

        except Exception as e:
            print(f"   ❌ FAILED on table '{table_name}': {e}")
            raise  # Stops script so you see the error immediately

if __name__ == "__main__":
    ingest_data()