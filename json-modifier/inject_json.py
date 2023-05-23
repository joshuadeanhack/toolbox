# This script runs in TeamCity
# It injects the changelist number into the build.version file in /Engine/Build/Build.version
# $> python3 inject_json.py --file ./Engine/Build/Build.version --modify Changelist <Changelist_Number> 
# The path to the version file can be set from an environment variable "build.version.filepath" set in TeamCity, cli arguments take priority

import os
import sys 
import argparse
import json
from dataclasses import dataclass

@dataclass
class JSONData:
    file_path: str = None
    modifications: dict = None
    loaded_data: dict = None

def get_value_from_env(arg_name, default_value):
    return os.environ.get(arg_name, default_value)

def load_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=str, default=get_value_from_env('build.version.filepath', "\Engine\Build\Build.version"))
    parser.add_argument("--modify", nargs=2, action='append')
    args = parser.parse_args()
    return args

def load_json_file(file_path):
    with open(file_path, 'r') as f:
        data = json.load(f)
        print(f"Opened the Build.version file {file_path}")
        return data

def write_json_file(file_path, data):
    try:
        with open(file_path, 'w') as f:
            json.dump(data, f, indent='\t')
            return True
    except Exception as e:
        print(f"Couldn't write to Build.version file: {file_path}")
        print(e)
        return False

def check_integer(value):
    try:
        return int(value)
    except:
        return value

def inject_json(injector):
    # Modify the values
    for key, value in injector.modifications.items():
        injector.loaded_data[key] = check_integer(value)
        print(f"Modifying {key}: {value}")
    if write_json_file(injector.file_path, injector.loaded_data):
        # Print the new file to STDOUT
        print(f"Final File: {injector.file_path}")
        print(json.dumps(injector.loaded_data, indent=4))

args = load_args()

# Set arguments
JSON_data = JSONData()
JSON_data.file_path = args.file
JSON_data.modifications = {key: value for key, value in args.modify} if args.modify else {}

try:
    # Load the JSON file
    JSON_data.loaded_data = load_json_file(JSON_data.file_path)

    # Write modifications to file
    inject_json(JSON_data)

except FileNotFoundError:
    print(f"Could not open the Build.version file: {JSON_data.file_path} not found")
    sys.exit(1)
except json.JSONDecodeError:
    print(f"Failed to decode JSON file {JSON_data.file_path}")
    sys.exit(1)
except Exception as e:
    print(f"Error: {str(e)}")
    print(f"Could not load JSON file {JSON_data.file_path} , it's possible the file is empty...")
    sys.exit(1)

sys.exit(0)
