import os
import sys 
import json

# This script is run in TeamCity
# It injects the changelist number into the build.version file in /Engine/Build/Build.version
# > python3 inject_json.py Changelist <Changelist_Number> 
# The path to the version file is from an environment variable "build.version.filepath" set in TeamCity

# Get the file path from the environment variable
current_dir = os.getcwd()
file_path = os.environ.get('build.version.filepath') or f"{current_dir}\filepath\Build.version"

# Get the key of the JSON to be modified
key = sys.argv[1] or 'Changelist'

# Get the new value from the environment variable
changelist_number = sys.argv[2] or os.environ.get('build.vcs.number') or "0"

try:
    # Open the JSON file and load its contents into a dictionary
    with open(file_path, 'r') as f:
        data = json.load(f)
        print(f"Opened the Build.version file {file_path}")

except FileNotFoundError:
    print(f"Could not open the Build.version file: {file_path} not found")

except json.JSONDecodeError:
    print(f"Failed to decode JSON file {file_path}")

else:
    # Modify the "Changelist" key
    data[key] = int(changelist_number)

    try:  
        # Write the modified data back to the same file
        with open(file_path, 'w') as f:
            json.dump(data, f, indent='\t')
        print(f"Wrote new {key}: {changelist_number} to Build.version file: {file_path}")
                
        # Read and print the contents of the file
        with open(file_path, 'r') as f:
            file_contents = f.read()
            print(f"New file contents:\n{file_contents}")
        sys.exit(0)
    except Exception as e:
        print(f"Couldn't write to Build.version file: {file_path}")
        print(e)
sys.exit(1)
