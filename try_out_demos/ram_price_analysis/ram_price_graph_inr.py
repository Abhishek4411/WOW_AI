import os
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime

# Fixed exchange rate USD to INR
exchange_rate = 82

# Synthesize monthly dates from January 2024 to April 2026
start_date = datetime(2024, 1, 1)
end_date = datetime(2026, 4, 1)
months = []
current = start_date
while current <= end_date:
    months.append(current.strftime('%Y-%m'))
    # next month
    if current.month == 12:
        current = current.replace(year=current.year + 1, month=1)
    else:
        current = current.replace(month=current.month + 1)

# Generate synthetic price data (in USD) based on trends and benchmark info
np.random.seed(42)
num_months = len(months)

# Before price increase (until mid 2025, say June 2025)
before_end_index = months.index('2025-06') + 1
before_prices_usd = 4.0 - np.linspace(0, 0.2, before_end_index) + np.random.normal(0, 0.05, before_end_index)

# After price increase (starting July 2025)
after_len = num_months - before_end_index
base_after_price = 5.5
volatility = 0.3
after_prices_usd = base_after_price + np.linspace(0, -0.5, after_len) + np.random.normal(0, volatility, after_len)

# Convert prices from USD to INR
before_prices_inr = before_prices_usd * exchange_rate
after_prices_inr = after_prices_usd * exchange_rate

# Combine to full arrays by padding with NaN where applicable
before_prices_full = np.concatenate([before_prices_inr, np.full(after_len, np.nan)])
after_prices_full = np.concatenate([np.full(before_end_index, np.nan), after_prices_inr])

# Plot
plt.figure(figsize=(12, 6))
plt.plot(months, before_prices_full, label='Before Price Increase', marker='o')
plt.plot(months, after_prices_full, label='After Price Increase', marker='o')
plt.xticks(rotation=45)
plt.ylabel('Price (INR)')
plt.title('Monthly RAM Price Trends in INR (Jan 2024 to Apr 2026)')
plt.legend()
plt.grid(True)
plt.tight_layout()

# Save path
save_dir = r'C:\Users\Dancy Naik\Documents\VS_Code_Test\wow_ai\try_out_demos\ram_price_analysis'
os.makedirs(save_dir, exist_ok=True)
save_path = os.path.join(save_dir, 'ram_price_trend_inr.png')
plt.savefig(save_path)
plt.close()

print(f'Graph saved to {save_path}')
