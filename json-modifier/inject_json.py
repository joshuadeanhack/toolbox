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

    # Dictionary of key-values to set
    modifications: dict = None

    # Dictionary for original JSON file
    data: dict = None

    # Loads JSON data from the file path
    def load_data_from_file(self) -> None:
        with open(self.file_path, 'r') as f:
            self.data = json.load(f)
            print(f"Opened the file: {self.file_path}")

    # Sets the modifications dictionary based on the --modify args specified.
    def set_modifications_from_args(self, args) -> None:
        if args.modify:
            self.modifications = {key: value for key, value in args.modify}
        else:
            self.modifications = {}

    # Modify the JSON object data values, using the modifications dict.
    def apply_JSON_modifications(self) -> None:
        for key, value in self.modifications.items():
            self.data[key] = cast_integer(value)
            print(f"Modifying {key}: {value}")

    # Writes the data to a JSON file at the file_path
    def write_data_to_file(self) -> None:  
        try:
            with open(self.file_path, 'w') as f:
                json.dump(self.data, f, indent='\t')
                print(f"Writing to file: {self.file_path}")
        except Exception as e:
            print(f"Error: Couldn't write to file: {self.file_path}")
            print(e)
            sys.exit(1)

    # Print the JSON file on disk to STD_OUT
    def print_file_on_disk(self) -> None:
        self.data = {}
        self.load_data_from_file()
        print(f"File on Disk: {self.file_path}")
        print(json.dumps(self.data, indent=4))

try:
    JSON_data = JSONData()

    # Load CLI arguments
    args = load_args()

    # Set the file path to the JSON file
    JSON_data.file_path = args.file

    # Load the JSON file
    JSON_data.load_data_from_file()

    # Create the dictionary of modifications from the CLI arguments 
    JSON_data.set_modifications_from_args(args)

    # Modify the data dict, based on the modifications dict 
    JSON_data.apply_JSON_modifications()

    # Write modifications to file
    JSON_data.write_data_to_file()

    # Print the new file on disk 
    print("\nChecking file on disk...")
    JSON_data.print_file_on_disk()

except FileNotFoundError as e:
    print(f"Could not open the Build.version file: {JSON_data.file_path} not found")
    print(f"Error: {str(e)}")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Failed to decode JSON file {JSON_data.file_path}")
    print(f"Error: {str(e)}")
    sys.exit(1)
except Exception as e:
    print("Encountered a general error while modifying the JSON file...")
    print(f"Error: {str(e)}")
    sys.exit(1)

sys.exit(0)