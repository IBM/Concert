# concert-sample

The script uploads sample JSON files required by Concert for power usecases including the inventory and risk information. The configuration is centralized in the environment variables file.


## Folder Structure
```
concert_sample_p/
├── README.md
├── concert_data/
│   └── sample_data_load_envs_p.variables      # Update this file with your environment-specific values.
├── input_sample_set/                          # Folder containing your sample JSON files.
│   ├── inventory-data.json                    # Inventory upload sample file.
│   ├── viossec-risks-data.json                # Risks upload sample file.
│   └── firmware-risks-data.json          # Risks upload sample file.
└── scripts/
    └── load_sample_data_p.sh                  # Shell script that uploads files to the specified endpoints.
```

## Prerequisites
•	Operating System: Linux or macOS.  
•	Shell: POSIX-compliant shell (e.g., bash).  
•	cURL: Ensure cURL is installed (curl --version).  
•	Network: Proper connectivity to your IBM Concert endpoint.  

## Setup Instructions
1.	Configure Environment Variables -

    Navigate to the concert_data directory and open the file `sample_data_load_envs_p.variables` Update it with the correct values for your IBM Concert setup:
    ```
    export CONCERT_URL="Your IBM Concert URL"
    export INSTANCE_ID="0000-0000-0000-0000"
    export API_KEY="Your API Key"
    ```

2.	Make the Shell Script Executable

    The script that invokes the APIs is located in the scripts folder as load_sample_data_p.sh. To make it executable, run:
    ```
    chmod +x scripts/load_sample_data_p.sh
    ```


## Running the Script
From your project root, execute the following command in your terminal:  
    ```
    ./scripts/load_sample_data_p.sh
    ```

### The script performs the following actions:
	
•	Loads Environment Variables:
It sources the `concert_data/sample_data_load_envs_p.variables` file for the API configuration.
	
•	Invokes the Inventory API:
Uploads inventory-data.json to the `/power_maintenance/inventory/upload` endpoint.
	
•	Invokes the Risks API:
Uploads viossec-risks-data.json and firmware-risks-data.json individually to the `/power_maintenance/risks/upload` endpoint.

Each API call is executed with a built-in retry mechanism (3 attempts by default) and a timeout (30 seconds). 
