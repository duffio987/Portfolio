import os
import pandas as pd

# File Path for .csv
folder_path = r"C:\\Users\\Your_File_Folder_Path"
csv_files = [f for f in os.listdir(folder_path) if f.endswith(".csv")]
total_files = len(csv_files)

# Check Empty
if not csv_files:
    print(" No CSV files found.")
    exit()

#  Read header from reference file
ref_file = csv_files[0]
ref_path = os.path.join(folder_path, ref_file)
ref_columns = pd.read_csv(ref_path, nrows=0).columns.tolist()
ref_columns_set = set(ref_columns)

print(f" Reference file: {ref_file}")
print(f" Column names:\n{ref_columns}\n")

# Check header consistency (column names, ignore order)
header_issues = []

for file in csv_files[1:]:
    path = os.path.join(folder_path, file)
    try:
        cols = pd.read_csv(path, nrows=0).columns.tolist()
        if set(cols) != ref_columns_set:
            missing = list(set(ref_columns) - set(cols))
            extra = list(set(cols) - set(ref_columns))
            header_issues.append((file, cols, missing, extra))
    except Exception as e:
        header_issues.append((file, [], [], f"Error: {e}"))

if header_issues:
    print(" Header inconsistencies found:\n")
    for file, cols, missing, extra in header_issues:
        print(f" {file}")
        print(f"    Columns: {cols}")
        print(f"    Missing: {missing}")
        print(f"    Extra:   {extra}\n")
    exit()

print(" All files have consistent headers.\n")

# Check data types from first 50 rows
column_types = {col: set() for col in ref_columns}
type_errors = {}

for file in csv_files:
    path = os.path.join(folder_path, file)
    try:
        df = pd.read_csv(path, nrows=500)  # check first 500
        for col in ref_columns:
            inferred_types = set(type(x).__name__ for x in df[col].dropna())
            column_types[col].update(inferred_types)
            if len(column_types[col]) > 1:
                if col not in type_errors:
                    type_errors[col] = {}
                type_errors[col][file] = inferred_types
    except Exception as e:
        print(f" Error reading {file}: {e}")

if type_errors:
    print(" Data type inconsistencies found:\n")
    for col, files in type_errors.items():
        print(f" Column: {col}")
        for file, types in files.items():
            print(f"    {file}: {types}")
        print()
    exit()

#  Final Report
print(f" All column data types are consistent across first 500 rows of {total_files} file(s).\n")
print(" Final Column Types:")
for col, types in column_types.items():
    print(f" - {col}: {list(types)[0]}")
