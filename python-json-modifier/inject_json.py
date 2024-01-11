# This script runs in TeamCity
# It injects the changelist number into the build.version file in /Engine/Build/Build.version
# $> python3 inject_json.py --file ./Engine/Build/Build.version --modify Changelist <CL_Number> --modify Branch "++UE5+Release"
# The path to the version file can be set from an environment variable "build.version.filepath" set in TeamCity, cli arguments take priority

import os
import sys 
import argparse
import json
from dataclasses import dataclass

# Cast a value to an int
def cast_integer(value):
    try:
        return int(value)
    except ValueError:
        return value

# Get environment variable value and set default value if null or empty
def get_value_from_env(arg_name, default_value):
    return os.environ.get(arg_name, default_value)

# Capture the CLI arguments
def load_args():
    parser = argparse.ArgumentParser()
    
    # Set the file path from CLI arg, then use Env Variable if set, then default Build.version path if others are not set
    parser.add_argument("--file", type=str, default=get_value_from_env('build.version.filepath', ".\Engine\Build\Build.version"))
    
    # Set the key-value pairs to be modified
    parser.add_argument("--modify", nargs=2, action='append')

    args = parser.parse_args()
    return args

@dataclass
class JSONData:
    # Path to json file
    file_path: str = None
    
    # Dictionary for JSON file
    data: dict = None

    # Loads JSON data from the file path
    def load(self) -> None:
        with open(self.file_path, 'r') as f:
            self.data = json.load(f)
            print(f"Opened the file: {self.file_path}")

    # Modify a JSON key value pair
    def update(self, key, value) -> None:
        self.data[key] = cast_integer(value)
        print(f"Modifying JSON Data -> {key}: {value}")

    # Writes the data to a JSON file at the file_path
    def write(self) -> None:  
        try:
            with open(self.file_path, 'w') as f:
                json.dump(self.data, f, indent='\t')
                print(f"Writing to file: {self.file_path}")
        except Exception as e:
            print(f"Error: Couldn't write to file: {self.file_path}")
            print(e)
            sys.exit(1)

    # Print the JSON file
    def print(self) -> None:
        print(json.dumps(self.data, indent=4))

try:
    JSON = JSONData()
    args = load_args()

    # Set the file path to the JSON file
    JSON.file_path = args.file

    # Load the JSON file
    JSON.load()

    # Modify the JSON data
    for key, value in args.modify:
        JSON.update(key, value)

    # Write the new JSON file
    JSON.write()

    # Print the new file on disk 
    print(f"\nChecking File on Disk...")
    JSON.data = {}
    JSON.load()
    JSON.print()

except FileNotFoundError as e:
    print(f"Could not open the Build.version file: {JSON.file_path} not found")
    print(f"Error: {str(e)}")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Failed to decode JSON file {JSON.file_path}")
    print("Is the JSON invalid?")
    print(f"Error: {str(e)}")
    sys.exit(1)
except Exception as e:
    print("Encountered a general error while modifying the JSON file...")
    print(f"Error: {str(e)}")
    sys.exit(1)

sys.exit(0)