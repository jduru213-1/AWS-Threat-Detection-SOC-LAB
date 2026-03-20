# Create AWS indexes in Splunk (aws_cloudtrail, aws_config, aws_vpcflow).
# Usage: python setup_splunk.py [--host localhost] [--port 8089] [--username admin]

import argparse  # Importing the argparse module to handle command-line arguments.
import getpass  # Importing the getpass module to securely handle password input.
import importlib  # Used for dynamic import of the Splunk SDK.

try:
    # Dynamically import the splunklib.client module to interact with the Splunk API.
    client = importlib.import_module("splunklib.client")
except ImportError as e:
    # Provide a clear message if the Splunk SDK is not installed.
    raise ImportError(
        "The Splunk Python SDK is required but not installed.\n"
        "Install it with:\n"
        "    pip install splunk-sdk\n"
        "and then re-run this script."
    ) from e

# Indexes the lab uses; must exist before the Add-on sends data.
DEFAULT_INDEXES = [ # This is a list of the indexes that the lab uses.
    "aws_cloudtrail",
    "aws_config",
    "aws_vpcflow",
]


def connect_splunk(host, port, username, password): # Defining a function to connect to the Splunk API.
    """Connect to Splunk API. verify=False for self-signed cert (local Docker)."""
    return client.connect( # Returning the connection to the Splunk API.
        host=host, # The host of the Splunk API.
        port=port, # The port of the Splunk API.
        username=username, # The username of the Splunk API.
        password=password, # The password of the Splunk API.
        scheme="https", # The scheme of the Splunk API.
        verify=False, # The verify of the Splunk API.
    )


def ensure_indexes(service, index_names): # Defining a function to ensure the indexes exist.
    """Create each index if it doesn't exist."""
    for name in index_names:
        if name in service.indexes:
            print(f"[indexes] {name} already exists")
        else:
            service.indexes.create(name)
            print(f"[indexes] {name} created")

def main():
    parser = argparse.ArgumentParser(description="Create AWS indexes in Splunk")
    parser.add_argument("--host", default="localhost", help="Splunk host") 
    parser.add_argument("--port", default=8089, help="Splunk management port")
    parser.add_argument("--username", default="admin", help="Splunk user")
    parser.add_argument("--password", default="ChangeMe123!", help="Splunk password (default)") 
    args = parser.parse_args() 

    password = getpass.getpass(prompt="Enter your Splunk password: ")
    service = connect_splunk(host=args.host, port=args.port, username=args.username, password=password)
    ensure_indexes(service, DEFAULT_INDEXES)
    print("[setup] Splunk setup complete")


if __name__ == "__main__":
    main()
