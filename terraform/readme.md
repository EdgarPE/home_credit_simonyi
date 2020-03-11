# How to use terraform script to create MLFlow server on GCP

1. Open Cloud Shell
2. Clone the project repo

        
        git clone https://github.com/EdgarPE/home_credit_simonyi.git
        
3. Clone the terraform installer
        
        git clone https://github.com/robertpeteuil/terraform-installer.git
        
4. Run the terraform installler
    ```
    chmod +x ./terraform-installer/terraform-install.sh \
    ./terraform-installer/terraform-install.sh -a
    ```
6. Apply terraform configuration. The URL of the MLFlow server will be displayed.
    ```
    cd home_credit_simonyi/terraform && \
    terraform init && \
    terraform apply -auto-approve -var "project=$(gcloud config list project --format 'value(core.project)')"
    ```




# Cleanup

1. In terraform directory issue then approve the prompt with yes.
    ```
    terraform destroy
    ```
2. Delete all Cloud Storage buckets
3. Stop all VM instances