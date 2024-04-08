# TSG/NTUA Connector Configuration Guide

This repository contains the installation instructions for the TSG IDS Connector customized to the specifications of NTUA as part of the Enershare project. 
It is the basis for deploying and configuring the components related to the connector (core container, administration UI, and data apps). The guide has been heavily inspired by TSG's [guide](https://gitlab.com/tno-tsg/projects/enershare).

## Requirements

### 1. Setup deployment environment.

Install the [microk8s](https://microk8s.io/) system. This requires:
- An Ubuntu 22.04 LTS, 20.04 LTS, 18.04 LTS or 16.04 LTS environment to run the commands (or another operating system which supports snapd - see the snapd documentation)
- At least 540MB of memory, but to accommodate workloads, it is recommended a system with at least 20G of disk space and 4G of memory.
- An internet connection

See more details regarding its configuration in the [Prerequisites](#prerequisites) section

### 2. Request dataspace certificates

You nee to become a participant in a dataspace as well as create your connector credentials in the [Εnershare](https://daps.enershare.dataspac.es/#home) (or [TSG Playground](https://daps.playground.dataspac.es/#management)) dataspace. This is important to acquire the necessary certificate files and keys, as well as connector/partificant IDs (used in is secrets and `values.yaml` respectively). 
1. Create an account at the Enershare Identity Provider
2. Go to the sub-tab `Participants` within the `Management` tab and `request a Participant certificate` via the button at the bottom of the page. You can choose your own participant ID, our suggestion is to use an identifier in the form of `urn:ids:enershare:participants:ORGANISATION_NAME` (where spaces can be replaced with hypens). You can either choose to create a private key and certificate signing request via the OpenSSL CLI or use the form under `Create private key in browser`. When using the form to generate the private key, ensure you download it, since it won't be stored anywhere by default.
3. Go to the sub-tab `Connectors` withing the `Management` tab and `request a Connector certificate` via the button at the bottom of the page. The process is similar to the Participant certificate, but it requires a participant certificate. For the connector ID, our suggestion is to use an identifier in the form of `urn:ids:enershare:connectors:ORGANISATION_NAME:CONNECTOR_NAME` (where spaces can be replaced with hyphens). The connector name can be a human readable name for the connector. 

At the end of this step, a participant and connector (with appropriate IDs) should be registered and the following files should be place in the directory of your connector:  
```bash
├── cachain.crt     # certificate authority key
├── component.crt   # connector id certificate
├── component.key   # connector id key
├── participant.crt # participant/organization id certificate
└── participant.key # participant/organization id key
```    

Send a message to Maarten and Willem, or ask during one of the calls, to activate the certificates.

### 3. SwaggerHub 

(For provider connectors) you need to have uploaded your API's documentation in [SwaggerHub](https://app.swaggerhub.com/home), when deploying APIs through the connector. See more details regarding its use in the [Deployment](#deployment) section 

## Prerequisites

1. **Install microk8s system using `snap`:** We use microk8s since it provides easy installation for many important compoments for the connector (kubectl, helm, ingress, cert-manager)

    ```bash
    sudo snap install microk8s --classic
    microk8s status --wait-ready # check status of microk8s cluster
    ```

    Optionally, add the following quality-of-life commands: 
    ```bash
    alias mkctl="microk8s kubectl" # set alias for kubectl
    sudo usermod -a -G microk8s ${USER} # set sudo user for microk8s 
    ```

2. Ensure which ports are already opened in your current working enviroment using:
    ```bash
    sudo ufw status numbered # check port status
    ```

3. **Enable ingress addon:** An ingress controller acts as a reverse proxy and load balancer. It adds a layer of abstraction to traffic routing, accepting traffic from outside the Kubernetes platform and load balancing it to Pods running inside the platform
    ```bash
    # cert-manager requires ports 80,443 to be allowed from the firewall
    sudo ufw allow 80 
    sudo ufw allow 443
    sudo microk8s enable ingress
    ```

4. **Enable cert-manager addon:** Cert-manager is a tool for Kubernetes that makes it easy to get and manage security certificates for your websites or applications. Cert-manager talks to certificate authorities (like Let's Encrypt) automatically to get certificates for your domain.
    ```bash
    # cert-manager requires port 9402 to be allowed from the firewall
    sudo ufw allow 9402
    # It might require to lower the firewall at the initial installation  
    # sudo ufw disable
    sudo microk8s enable cert-manager
    # sudo ufw enable
    ```

5. **Configure clusterIssuer:** ClusterIssuer is a Kubernetes resource that represents a specific certificate authority or a way to obtain certificates for cluster-wide issuance. It uses the ACME protocol to interact with certificate authorities (e.g Let's Encrypt) and automate the certificate issuance process.
Apply `cluster-issuer.yaml` file provided using:
    ```bash
    microk8s kubectl apply -f cluster-issuer.yaml
    ```

6. Ensure DNS A records (or a wildcard DNS A record) is set to point to the public IP address of the VM.
    ```bash
    # This returns VM's public IP address in ipv4 (e.g 147.102.6.27)
    curl -4 ifconfig.co 
    # Display the resolved IP address associated with the domain name. See if it matches output of VM's public IP address
    nslookup {domain-name}
    ```

7. Ensure dns ports (53/9153) are available:
    ```bash
    sudo ufw allow 9153 
    sudo ufw allow 53
    ```
8. **Enable Helm addon:** [Helm](https://helm.sh/docs/intro/using_helm/) is a package manager software for Kubernetes applications. If not installed by default when initializing microk8s cluster, enable it manually:
   ```bash
    sudo microk8s enable helm
   ```

## Deployment

1. Configure the Helm Chart: update the `values.yaml` file with the modifications to the configuration (see `/examples/values.ntua.yml` as an example).

    In this guide, it is assumed that you have followed the instructions in the [Requirements](#requirements) section. 
    Please refer to the official TSG gitlab [page](https://gitlab.com/tno-tsg/helm-charts/connector/-/blob/master/README.md?ref_type=heads) for further information with regards to the configuration.
    
    The minimal configuration required to get your first deployment running, without data apps and ingresses, is as follows:
    
    - Modify `host` to the domain name you configured with the ingress controller:
        ```yaml
        host: {domain-name}
        ```
    - Modify `ids.info.idsid`, `ids.info.curator`, `ids.info.maintainer` in the `values.yml` file to the corresponding identifiers that you filled in during creation of the certificates. `ids.info.idsid` should be the Connector ID, and `ids.info.curator`, `ids.info.maintainer` should be the Participant ID. (Optionally) change `titles`and `descriptions` to the connector name, and a more descriptive description of your service in the future:
        ```yaml
        ids:
          info:
            idsid: {IDS_COMPONENT_ID}
            curator: {IDS_PARTICIPANT_ID}
            maintainer: {IDS_PARTICIPANT_ID}
            titles:
              - {CONNECTOR TITLE@en}
            descriptions:
              - {CONNECTOR DESCRIPTION@en}
            accessUrl:
              - https://CONNECTOR_ACCESS_URL/router
        ```
    - Modify fields in the `agents` tab: Keep in mind that `api-version` is the version number you have used for your API when you uploaded in SwaggerHub (e.g 0.5). It is important to note that in order to retrieve the API spec for the data app, the URL used in the config should be the `/apiproxy/registry/` variant instead of the `/apis/` link from Swagger hub.
      ```yaml
      agents:
          - id: {IDS_COMPONENT_ID}:{AgentName} # custom agent defined by user
            backEndUrlMapping:
              {api-version}: http://{service-name}:{internal-service-port}
            title: SERVICE TITLE
            openApiBaseUrl: https://app.swaggerhub.com/apiproxy/registry/{username}/{api-name}/
            versions: 
            - {api-version}
      ```
   - **When using multiple connectors in the same cluster**: deploy connectors at different namespaces to avoid confusion between their certificates. Each connector namespace must contain the connector helm chart as well as its respective identity-secret. The data-app path must also be modified to avoid overlap. Both data-app path and the name of the identity secret can be configured in `values.yaml` respectively at:
     ```
      secrets:
        idsIdentity:
          name: {ids-identity-secret}

     ...

     services:
      - port: 8080
        name: http
        ingress:
          path: /{data-app}/(.*)
          rewriteTarget: /$1
          clusterIssuer: letsencrypt
          ingressClass: public
     ```
     
    - (Optionally) Modify `apiKey` and `key` fields: Change the bit after ``APIKEY-`` to a random API key used for interaction between the core container and the data app.
      ```yaml
      key: APIKEY-sgqgCPJWgQjmMWrKLAmkETDE # CHANGE
      ...
      apiKey: APIKEY-sgqgCPJWgQjmMWrKLAmkETDE # CHANGE 
      ```
    - (Optionally) Modify `password` field: Create your own BCrypt encoded password for the admin user of the connector (also used in the default configuration to secure the ingress of the data app).
      ```yaml
      users:
          - id: admin
              # -- BCrypt encoded password
              password: $2a$12$cOEhdassfs/gcpyCasafrefeweQ0axdsaafrswIuKysZdeJMArNxfsasjfbeajsaf
              roles:
                  - ADMIN
      ```
    
3. Create IDS Identity secret: Cert-manager stores TLS certificates as Kubernetes secrets, making them easily accessible to your applications. When certificates are renewed, the updated certificates are automatically stored in the corresponding secrets. Create an Kubernetes secret containing the certificates acquired from identity creation.
    ```bash
    microk8s kubectl create secret generic ids-identity-secret --from-file=ids.crt=./component.crt \
                                                               --from-file=ids.key=./component.key \
                                                               --from-file=ca.crt=./cachain.crt 
    ```

4. Add the Helm repository of the TSG components:
    ```bash
    helm repo add tsg https://nexus.dataspac.es/repository/tsg-helm
    helm repo update
    ```

5. To install the Helm chart, execute:
    ```bash
    microk8s helm upgrade --install \
            -n {namespace} \
            --repo https://nexus.dataspac.es/repository/tsg-helm \
            --version 3.2.8 \
            -f values.yaml \
            {deployment-name} \
            tsg-connector
    ```
    please update to appropriate names the `namespace` (e.g default) and `deployment-name` (e.g my-connector) fields

6. Wait till you ensure connector pods are all in a ready (1/1) state (it might take at least a minute). You can watch the state of the pods using this command:
   ```bash
    watch microk8s kubectl get all --all-namespaces
   ```  

## Interacting
After deployment, the user interfaces for the : 
- data space connector (`https://{domain-name}/ui/`)
- connector data-app (`https://{domain-name}/data-app/`)

will be available, with the login matching the admin user with the provided BCrypt password. 

The connector address that other connectors will use to communicate with your connector will be `https://{domain-name}/router`. 

Also, after successful deployment, your connector should be available in the [Metadata Broker](https://broker.enershare.dataspac.es/#connectors).

## Usage

In the OpenAPI data app UI:
1. go to `Tester` and click on `Query`
2. expand the agent with id `urn:ids:enershare:connectors:MeterDataService:ServiceAgent` and click on `Use`. The fields appropriate to said agent should be filled
3. Select a sender agent from the list and provide as `path` "/powermeters"
4. This should result in a JSON array of observer Ids.

## Clean-up

To delete the connector and remove all related resources:
```bash
microk8s kubectl delete clusterissuer lets-encrypt
microk8s kubectl delete secret/ids-identity-secret
microk8s helm uninstall {deployment-name} -n {namespace}
```
