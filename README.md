# 🚕 Uber Ride Analytics Dashboard

### Project Overview 
Developed an end-to-end Uber Ride Analytics solution using SQL Server and Power BI. The project involved data profiling, cleaning, dimensional modeling using a star schema, and interactive dashboard development to uncover operational insights and business recommendations.

## 📊 Key Findings
- **62% completion rate** across 150K bookings
- **25% cancellation rate** — primary driver: wrong pickup address
- **Auto** generated the highest revenue (~₹12.9M)
- Evening time period had the highest demand
- Top 3 vehicle types follow Pareto (80/20) revenue distribution

### Process Flow 
```text
📥 Excel Dataset
      ↓
🔍 SQL Data Profiling
      ↓
🧹 Data Cleaning & Transformation
      ↓
⭐ Star Schema Design
      ↓
🗄️ SQL Analysis
      ↓
📊 Power BI Dashboard Development
      ↓
💡 Business Insights & Recommendations
```

### 🔗 Dataset
This dataset was sourced from Kaggle and appears to be synthetically generated for educational purposes. During profiling, duplicate Booking IDs were identified and handled using surrogate keys in the fact table.
https://www.kaggle.com/datasets/yashdevladdha/uber-ride-analytics-dashboard/data
