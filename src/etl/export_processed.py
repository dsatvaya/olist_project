import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
import os

# 1. Setup
load_dotenv()
DB_USER = 'postgres'
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = 'localhost'
DB_PORT = '5432'
DB_NAME = 'olist_dw'

connection_str = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(connection_str)

# 2. Configuration
OUTPUT_DIR = os.path.join(os.getcwd(), 'data', 'processed')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Map the SQL View Name -> Output Filename
VIEWS_TO_EXPORT = {
    'dim_customers': 'dim_customers.csv',
    'dim_products': 'dim_products.csv',
    'dim_sellers': 'dim_sellers.csv',
    'dim_geolocation': 'dim_geolocation.csv',
    'fact_orders': 'fact_orders.csv',
    'order_items': 'order_items.csv',         # Raw table, but needed for price
    'order_payments': 'order_payments.csv',   # Raw table, needed for payment types
    'order_reviews': 'order_reviews.csv'      # Raw table, needed for sentiment
}

def export_views():
    print(f"🚀 Starting Export to {OUTPUT_DIR}...")
    
    for view_name, file_name in VIEWS_TO_EXPORT.items():
        print(f"   ⏳ Exporting {view_name}...", end=" ")
        try:
            # We simply select everything from the clean view
            query = f"SELECT * FROM {view_name}"
            df = pd.read_sql(query, engine)
            
            # Save to CSV
            output_path = os.path.join(OUTPUT_DIR, file_name)
            df.to_csv(output_path, index=False)
            print(f"✅ Done! ({len(df)} rows)")
            
        except Exception as e:
            print(f"❌ Failed: {e}")

if __name__ == "__main__":
    export_views()