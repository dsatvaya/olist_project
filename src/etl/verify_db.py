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

def verify_data():
    print("🔎 Starting Final Integrity Audit...\n")
    
    try:
        with engine.connect() as conn:
            # 1. Dynamic Row Counts (No hardcoded lists)
            print(f"{'Table':<35} | {'Row Count':<10}")
            print("-" * 50)
            
            # Fetch all table names dynamically from the public schema
            tables_query = text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema='public' 
                ORDER BY table_name;
            """)
            result = conn.execute(tables_query)
            tables = [row[0] for row in result]

            if not tables:
                print("❌ No tables found! Database is empty.")
                return

            for table in tables:
                # Count rows for each table found
                count_query = text(f"SELECT COUNT(*) FROM {table}")
                count = conn.execute(count_query).scalar()
                print(f"{table:<35} | {count:<10}")

            print("\n🔎 DATA TYPE CHECKS:")
            
            # 2. Check Timestamp
            ts_check = text("SELECT data_type FROM information_schema.columns WHERE table_name='orders' AND column_name='order_purchase_timestamp'")
            ts_type = conn.execute(ts_check).scalar()
            
            # SAFE CHECK: Handle None if table/column doesn't exist
            is_ts_valid = ts_type and ('timestamp' in str(ts_type).lower())
            print(f"   * Orders Timestamp:   {str(ts_type):<25} " + ("✅" if is_ts_valid else "❌"))

            # 3. Check Money
            price_check = text("SELECT data_type FROM information_schema.columns WHERE table_name='order_items' AND column_name='price'")
            price_type = conn.execute(price_check).scalar()
            
            is_price_valid = price_type and ('numeric' in str(price_type).lower() or 'decimal' in str(price_type).lower())
            print(f"   * Price (Money):      {str(price_type):<25} " + ("✅" if is_price_valid else "❌ (Float risk)"))

            # 4. Check Zip Codes (Leading Zeros)
            zip_check = text("SELECT customer_zip_code_prefix FROM customers WHERE length(customer_zip_code_prefix) = 5 AND customer_zip_code_prefix LIKE '0%' LIMIT 1")
            zip_sample = conn.execute(zip_check).scalar()
            
            is_zip_valid = zip_sample and str(zip_sample).startswith('0')
            print(f"   * Zip Code Check:     {str(zip_sample):<25} " + ("✅ (Leading zero preserved)" if is_zip_valid else "⚠️ (No leading zero sample found)"))

    except Exception as e:
        print(f"\n❌ Verification Failed: {e}")

if __name__ == "__main__":
    verify_data()