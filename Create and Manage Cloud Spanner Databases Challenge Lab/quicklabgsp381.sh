wget https://raw.githubusercontent.com/quiccklabs/Labs_solutions/ed8351d0beeecc1302b039edefc2f4a2d13edf5f/Create%20and%20Manage%20Cloud%20Spanner%20Databases%20Challenge%20Lab/Customer_List_500.csv

gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com

sleep 20

gcloud spanner instances create banking-ops-instance --config=regional-$REGION --description="Banking Ops Instance" --nodes=1

gcloud spanner databases create banking-ops-db \
--instance=banking-ops-instance


gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Portfolio (PortfolioId INT64 NOT NULL, Name STRING(MAX), ShortName STRING(MAX), PortfolioInfo STRING(MAX)) PRIMARY KEY (PortfolioId)"


gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Category (CategoryId INT64 NOT NULL, PortfolioId INT64 NOT NULL, CategoryName STRING(MAX), PortfolioInfo STRING(MAX)) PRIMARY KEY (CategoryId)"


gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Product (ProductId INT64 NOT NULL, CategoryId INT64 NOT NULL, PortfolioId INT64 NOT NULL, ProductName STRING(MAX), ProductAssetCode STRING(25), ProductClass STRING(25)) PRIMARY KEY (ProductId)"


gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Customer (CustomerId STRING(36) NOT NULL, Name STRING(MAX) NOT NULL, Location STRING(MAX) NOT NULL) PRIMARY KEY (CustomerId)"



gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (1, 'Banking', 'Bnkg', 'All Banking Business'), (2, 'Asset Growth', 'AsstGrwth', 'All Asset Focused Products'), (3, 'Insurance', 'Insurance', 'All Insurance Focused Products')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (1, 1, 'Cash'), (2, 2, 'Investments - Short Return'), (3, 2, 'Annuities'), (4, 3, 'Life Insurance')"


gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (1, 1, 1, 'Checking Account', 'ChkAcct', 'Banking LOB'), (2, 2, 2, 'Mutual Fund Consumer Goods', 'MFundCG', 'Investment LOB'), (3, 3, 2, 'Annuity Early Retirement', 'AnnuFixed', 'Investment LOB'), (4, 4, 3, 'Term Life Insurance', 'TermLife', 'Insurance LOB'), (5, 1, 1, 'Savings Account', 'SavAcct', 'Banking LOB'), (6, 1, 1, 'Personal Loan', 'PersLn', 'Banking LOB'), (7, 1, 1, 'Auto Loan', 'AutLn', 'Banking LOB'), (8, 4, 3, 'Permanent Life Insurance', 'PermLife', 'Insurance LOB'), (9, 2, 2, 'US Savings Bonds', 'USSavBond', 'Investment LOB')"


#SUBSCRIBE TO QUICKLAB

gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com

cat > manifest.json <<EOF
{
  "tables": [
    {
      "table_name": "Customer",
      "file_patterns": [
        "gs://$DEVSHELL_PROJECT_ID/Customer_List_500.csv"
      ],
      "columns": [
        {"column_name" : "CustomerId", "type_name" : "STRING" },
        {"column_name" : "Name", "type_name" : "STRING" },
        {"column_name" : "Location", "type_name" : "STRING" }
      ]
    }
  ]
}

EOF

gsutil mb gs://$DEVSHELL_PROJECT_ID
touch emptyfile
gsutil cp emptyfile gs://$DEVSHELL_PROJECT_ID/tmp/emptyfile

gsutil cp Customer_List_500.csv gs://$DEVSHELL_PROJECT_ID

gsutil cp manifest.json gs://$DEVSHELL_PROJECT_ID

sleep 60

gcloud dataflow jobs run quicklab --gcs-location gs://dataflow-templates-us-west1/latest/GCS_Text_to_Cloud_Spanner --region us-west1 --staging-location gs://$DEVSHELL_PROJECT_ID/tmp/ --parameters instanceId=banking-ops-instance,databaseId=banking-ops-db,importManifest=gs://$DEVSHELL_PROJECT_ID/manifest.json


gcloud spanner databases ddl update banking-ops-db \
--instance=banking-ops-instance \
--ddl='ALTER TABLE Category ADD COLUMN MarketingBudget INT64;'






