# Automatically deploy an A100 with MIG enabled and run containers

## Prerequisites

1. Access to an OCI tenancy with region activated and service limits for BM.GPU4.8, our A100 shape. These requests can be completed through the [support portal](https://support.oracle.com/portal/)
2. Download this repository as a zip file. Click the green "Code" button and select "Download Zip"

## GPU Availability Chart

| Region | Shape     | Availability Domain | Tesla GPU Family |
|--------|-----------|---------------------|------------------|
| IAD    | BM.GPU4.8 | 2                   | A100             |
| FRA    | BM.GPU4.8 | 1                   | A100             |
| LHR    | BM.GPU4.8 | 2                   | A100             |
| KIX    | BM.GPU4.8 | 1                   | A100             |
| NRT    | BM.GPU4.8 | 1                   | A100             |
| SJC    | BM.GPU4.8 | 1                   | A100             |

## Deployment Instructions

1. Referencing the chart above, select the appropriate region, then navigate to the Resource Manager: OCI Dashboard Menu > Solutions and Platform > Resource Manager > Stacks then click "Create Stack"
2. Change the "Stack Configuration" radio button to `.zip file` and drop in the downloaded zip file. Click "Next" at the bottom or "Configure Variables" on the left.
3. Complete the form fields
   
   ### Compute Configuration
   
   **Compute Compartment**: Select the compartment where you'd like the system to be deployed
   
   **Instance Name**: Create a unique name for the instance
   
   **DNS Hostname Label**: Create a hostname for the system, should be similar to Instance Name
   
   **Compute Shape with MIG Support**: Select the shape you'd like to deploy. Currently only BM.GPU4.8 supports MIG
   
   **Image**: !!IMPORTANT!! Select an image labelled with GPU for pre-configured NVIDIA drivers. If a GPU image is not selected, deployment will fail
   
   **Availability Domain**: Select based on the chart above
   
   **Public SSH Key**: Either choose a `.pub` file, or paste an SSH key for access
   
   ### Docker Configuration
   
   This deployment will download an image with docker and start the image on each MIG device
   For private repositories: use the optional Registry fields to add your docker login information
   
   **Image Name**: Name of the image to be downloaded and run. To test Jupyter Notebooks, enter `jupyter/datascience-notebook`
   
   **Run Image Options**: Any options you'd like to run with the image. To mount an NFS drive to the container that is located on the host at `/data` for the Jupyter Notebook, enter `-v /data:/home/jovyan/work`
   
   ### Persistent Storage
   
   The deployed system is intended to be ephemeral, so a persistent storage system needs to be mounted in order for data to persist after the GPU system is terminated.
   
   **Create FSS**: If an NFS mount point does not exist, it is recommended to create one with OCI File Storage System (FSS). Check this box to create an FSS and mount point
   
   **FSS Compartment**: (Appears when Create FSS is checked) Select the same compartment as the compute deployment
   
   **FSS Availability Domain**: (Appears when Create FSS is checked) Select the same AD as the compute deployment
   
   **File Storage Name**: Create a name for the FSS
   
   **NFS Path**: The path where the NFS should be mounted on the node
   
   **NFS Export Path**: The export path for the NFS mount
   
   **NFS Server IP**: (Appears when Create FSS is unchecked) The IP address for the existing NFS system
   
   ### Virtual Cloud Network
   
   It is recommended to deploy a new VCN for this deployment, as the terraform creates the appropriate security lists to communicate with FSS. Otherwise, select an existing VCN that has the appropriate network configuration for your environment
   
   ### Additional Configuration Options
   
   These options allow you to tag the system in order to create reports in OCI. [Follow this guide](https://docs.oracle.com/en-us/iaas/Content/Tagging/Concepts/taggingoverview.htm) to learn more about tagging.
   
4. SSH into the system in order to get instructions on how to connect to Jupyter sessions. Navigate to the `playbooks` directory located in the HOME directory of the instance. Run `sh list-tokens.sh`. This script will find all running containers and execute `jupyter notebook list` in each and output the connection instruction for each Jupyter session running. Users can first execute the `ssh -L <port>:localhost:<port> opc@<ip-address>` command to open a tunnel from their device to the remote. Then they can navigate to the token link provided by the script for secure access.

   If you'd like to run a different container than the one selected in the launch script, first set export values
   
     `export DOCKER_RUN_OPTIONS=<additional-docker-options>`
   
     `export DOCKER_IMAGE_OPTIONS=<target-image-name>`
   
   Then run `sh save-mig-dev.sh`
   
# Note on using the 'destroy' command:

If you deployed this stack with **Create FSS** checked, and then you use the `destroy` action, it will DELETE THE FSS AND ASSOCIATED DATA. If this is an issue, deploy FSS separately and provide the IP address and export path in the deployment.
