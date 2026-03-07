# JAVA Application Discovery through Workflow

This guide walks you through discovering Java applications running on virtual machines using IBM Concert's workflow-based discovery process.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Step 1: Download and import the prebuilt workflow](#step-1-download-and-import-the-prebuilt-workflow)
- [Step 2: Create Required Authentications](#step-2-create-required-authentications)
- [Step 3: Edit the Imported Workflow](#step-3-edit-the-imported-workflow)
- [Step 4: Run the Workflow](#step-4-run-the-workflow)
- [Step 5: Review ingested application and resilience assessment details](#step-5-review-ingested-application-and-resilience-assessment-details)
- [Step 6: Simulate Demo Actions and Remediations](#step-6-simulate-demo-actions-and-remediations)
- [Additional Resources](#additional-resources)

---

## Prerequisites

Before proceeding with Java application discovery, ensure you have completed the sample Java application installation as documented in:

**[FullbankDemoV2 Installation Guide](https://github.ibm.com/Concert-projects/FullbankDemoV2/blob/main/README.md)** 

The prerequisite installation includes:
- ✅ Java OpenJDK 17 or later installed
- ✅ Apache Tomcat 11 installed and configured
- ✅ Tomcat running as a system service
- ✅ SSL certificates configured (if required)
- ✅ Appropriate user permissions set up
- ✅ Network connectivity and firewall rules configured

Verify your Java installation:
```bash
java -version
```

Verify Tomcat is running:
```bash
sudo systemctl status tomcat
```

We have already done three Java application running on three different tomcat server. 
---

## Overview

The Java Application Discovery workflow automates the process of identifying and cataloging Java applications running on virtual machines. This workflow:
- Connects to target VMs using SSH credentials
- Scans for running Java processes
- Collects application metadata and configuration
- Registers discovered applications in IBM Concert

---

## Step 1: Download and import the prebuilt workflow

In Concert Workflows, in the Workflows page, Create folder (java_tomcat). Open the created folder, click Create workflow > Select from library, choose the Java Application Discovery workflow, and import it.

Once the flow (.zip file) is downloaded and imported into Concert Workflows, you have the following folders: 

   - The Identification folder is used to customize the flow.
   - The Prerequisites folder tests and validates the prerequisites.
   - The Discovery folder uses SSH credentials to discover Java applications and to collect raw metrics.
   - The Selection folder is used to filter the relevant components.
   - The Processing folder is used to compute the metrics.
   - The Upload to concert folder generates SBOMs and uploads them to Concert.
   - The JAVA Actuator Application Discovery file runs the flow.

## Step 2: Create Required Authentications

Set up the necessary authentication credentials for the workflow to access your target VMs. You can create authentications from the Authentications page. 

### IBM Concert API Key

 Click on Create authentication and add below details:
  ```
   name: concert_api_key
   Service: IBM Concert API Key
   host: <hostname>:12443
   API Key: <c_api_key>
   API Key Type: C_API_KEY 
  ```
 Test authentication and Create.

### VM SSH Credentials Setup

 1. Click on Create authentication and add below details:
    ```
      name: balance_auth
      service: SSH
      host: c37471v1.fyre.ibm.com
      port: 22
      username: root
      password: <password>
    ```
 2. Click on Create authentication and add below details:
    ```
      name: notification_auth
      service: SSH
      host: c36529v1.fyre.ibm.com
      port: 22
      username: root
      password: <passsword>
    ```
 3. Click on Create authentication and add below details:
    ```
      name: core_auth
      service: SSH
      host: c54211v1.fyre.ibm.com
      port: 22
      username: root
      password: <password>
    ```

## Step 3: Edit the Imported Workflow

After importing the workflow, you must provide input values, including authentications generated in the previous step.

  1. In Concert Workflows, click Workflows in the side navigation.
  2. Go inside the java_tomcat folder where Java Application Discovery workflow was imported.
  3. Open the 0 - id_target_list file from the 0 - identification folder.

     Update the below user variables in workflow editor
     ```
        app_name : "Fullbank-Demo"
        app_version : "1.1.0"
        environment : "Pre-production"
        deploy_number : "1"
        ignored_app_names : ["“test_tomcat”"]
        opt_OS : false
        opt_gen_appSBOM : true
        opt_gen_cycloneDX : false
        application_data_assessment_impact_risk : "5"
        application_criticality : "5"
        concert_auth_key : "ibmconcert/concert_api_key"
        resilience_profile : "fullbank_java_profile"
        assessment_period : "latest"
        vm_list : [{
                    "target": "c37471v1.fyre.ibm.com",
                    "cred": "ibmconcert/balance_auth",
                    "isConcertVault": true,
                    "port": 22,

                    "tomcat": {
                        "fileBased": true
                    }
                }, {
                    "target": "c36529v1.fyre.ibm.com",
                    "cred": "ibmconcert/notification_auth",
                    "isConcertVault": true,
                    "port": 22,

                    "tomcat": {
                        "fileBased": true
                    }
                }, {
                    "target": "c54211v1.fyre.ibm.com",
                    "cred": "ibmconcert/core_auth",
                    "isConcertVault": true,
                    "port": 22,

                    "tomcat": {
                        "fileBased": true
                    }
                }]
     ```
   4. Click Save to save the workflow.


## Step 4: Run the Workflow

Execute the discovery workflow manually or schedule it for automated runs.

### Manual Execution

1. **Navigate to Workflows Page**
   - Go to **Workflows** in the Concert console

2. **Locate Your Workflow**
   - Find the Java Application Discovery workflow in the list

3. **Execute the Workflow**
   - Click the **overflow menu** (⋮) in the **Actions** column next to the workflow
   - Click **Run**

4. **Monitor Execution**
   - The workflow status will change to "Running"
   - Click on the workflow name to view detailed execution logs
   - Monitor progress through each workflow step

### Scheduled Execution (Optional)

To run the workflow on a schedule:

1. **Edit Workflow Schedule**
   - Click the overflow menu (⋮) next to the workflow
   - Select **Schedule**

2. **Configure Schedule**
   ```yaml
   Schedule Type: Recurring
   Frequency: Daily
   Time: 02:00 AM
   Timezone: UTC
   ```

3. **Save Schedule**
   - Click **Save** to activate the schedule

## Step 5: Review ingested application and resilience assessment details
After running the workflow, you can review the ingested application details and corresponding resilience metrics.
To view Java application details:
   1. In your Concert instance, go to Inventory > Application inventory from the main navigation.
   2. In the Applications tab, click the name of the ingested application to view details.

To view resilience assessment details:
   1. In your Concert instance, go to Dimensions > Resilience from the main navigation.
   2. In the Postures tab, scroll down and click the name of the posture assessment plan from the list to view details.
   3. In the Assessment summary tab, scroll down to view a list of Input metrics.The list contains all the resilience metrics collected related to this application, including those observed from the ingested images. Refer to the Source column in the table to verify the origin of each ingested metric.

## Step 6: Simulate Demo Actions and Remediations

After discovering the Java applications, you can simulate security issues and their remediations to demonstrate Concert's action and recommendation capabilities.

### Prerequisites

Install `sshpass` on the host where the remediation scripts will be run:

**Ubuntu/Linux:**
```bash
sudo apt-get update
sudo apt-get install -y sshpass
```

**macOS:**
```bash
# Download and compile sshpass
curl -O -L https://sourceforge.net/projects/sshpass/files/sshpass/1.09/sshpass-1.09.tar.gz
tar xvzf sshpass-1.09.tar.gz
cd sshpass-1.09
./configure
make
sudo make install
```

### Remediation Scripts

Two remediation scripts are available to demonstrate security issue creation and remediation:

1. **`remediate_usehttponly_all.sh`** - Manages HttpOnly flag configuration
2. **`remediate_running_as_root_all.sh`** - Manages Tomcat running as root user issue
3. **`remediate_thread_usage_all.sh`** - Manages Thread Pool usage for Tomcat running.

Each script supports two modes:

**Remediation Mode:**
Apply the Patch on running tomcat server, which remediates the generated action.

```bash
./remediate_usehttponly_all.sh remediate
./remediate_running_as_root_all.sh remediate
./remediate_thread_usage_all.sh remediate
```

**Create Issue Mode:**
Apply the changes on Tomcat server, which leads to action/recommendation generation in Concert.

```bash
./remediate_usehttponly_all.sh create-issue
./remediate_running_as_root_all.sh create-issue
./remediate_thread_usage_all.sh create-issue
```

### NOTE:
```
Use Apache Bench command ab -n 40000 -c 200 http://c36529v1.fyre.ibm.com:8080/app/slow to simulate high thread usage to generate action/recommendation for thread pool usage in concert.
```
### How to Use the Remediation Scripts

#### Step 1: Set Server Password for SSH Access

Export the server password as an environment variable:

```bash
export SERVER_PASSWORD="password"
```

#### Step 2: Run Scripts for Remediation
To remediate existing issues:

```bash
./remediate_usehttponly_all.sh remediate
./remediate_running_as_root_all.sh remediate
./remediate_thread_usage_all.sh remediate
```
#### Step 3: Veriify Remediation
   - Run the Java Application Discovery workflow again
   - Confirm the security issues are resolved in Concert
   - Verify the actions are marked as Successful in Action Center.

#### Step 4: Recreate Issues for Testing
Before running the workflow again you need to run the `./remediate_usehttponly_all.sh create-issue` and `./remediate_running_as_root_all.sh create-issue` to reset the flags to true. This will allow the workflow to run again and create new actions in Concert.

---

## Additional Resources

- [FullbankDemoV2 Installation Guide](./FullbankDemoV2/README.md)
- [IBM Concert Documentation](https://www.ibm.com/docs/en/concert/2.2.x)

