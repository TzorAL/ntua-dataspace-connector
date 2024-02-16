# TSG/NTUA Connector Helm Chart

This repository contains the Helm Chart for the [TSG IDS Connector](https://gitlab.com/tno-tsg/helm-charts/connector) customized to the specifications of NTUA as part of the Enershare project. 
It is the basis for deploying and configuring the components related to the connector (core container, administration UI, and data apps).

# Requirements
For our implementation, it is necessary to: 
- install the [microk8s](https://microk8s.io/) system. This requires:
    - An Ubuntu 22.04 LTS, 20.04 LTS, 18.04 LTS or 16.04 LTS environment to run the commands (or another operating system which supports snapd - see the snapd documentation)
    - At least 540MB of memory, but to accommodate workloads, it is recommended a system with at least 20G of disk space and 4G of memory.
    - An internet connection
- have uploaded your API's documentation in [SwaggerHub](https://app.swaggerhub.com/home), when deploying APIs through the connector
- become a participant in a dataspace as well as create your connector credentials in the [tsg playground](https://daps.playground.dataspac.es/#home) or [enershare](https://daps.enershare.dataspac.es/#home) dataspace. This is important to acquire the necessary certificate files and keys, as well as connector/partificant IDs (used in is secrets and `values.yaml` respectively). At the end of this step, a participant and connector (with appropriate IDs) should be registered and the following files should be place in the directory of your connector:  
    ```bash
    ├── cachain.crt     # certificate authority key
    ├── component.crt   # connector id certificate
    ├── component.key   # connector id key
    ├── participant.crt # participant/organization id certificate
    └── participant.key # participant/organization id key
    ```    

# Prerequisites

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
    sudo ufw status numbered # check port status (when firewall is enabled)
    # Optionally, for a simple implementation, you can lower the firewall and enable it again once all components are configured
    sudo ufw disable # completely disable firewall
    sudo ufw enable # enable firewall
    ```

3. **Enable ingress addon:** An ingress controller acts as a reverse proxy and load balancer. It adds a layer of abstraction to traffic routing, accepting traffic from outside the Kubernetes platform and load balancing it to Pods running inside the platform
    ```bash
    # cert-manager requires ports 80,443 to be allowed from the firewall
    sudo ufw allow 80 
    sudo ufw allow 443
    # It might require to temporarily disable firewall during the installation of this addon
    # sudo ufw disable # completely disable firewall
    sudo microk8s enable ingress
    # sudo ufw enable # enable firewall
    ```

4. **Enable cert-manager addon:** Cert-manager is a tool for Kubernetes that makes it easy to get and manage security certificates for your websites or applications. Cert-manager talks to certificate authorities (like Let's Encrypt) automatically to get certificates for your domain.
    ```bash
    # cert-manager requires port 9402 to be allowed from the firewall
    sudo ufw allow 9402
    sudo microk8s enable cert-manager
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
    nslookup domain-name
    ```

7. Ensure dns ports (53/9153) are available:
    ```bash
    sudo ufw allow 9153 
    sudo ufw allow 53
    ```

# Deployment

1. Configure the Helm Chart: create a `values.ntua.yaml` file with the modifications to the configuration.

    Please refer to the official TSG gitlab [page](https://gitlab.com/tno-tsg/helm-charts/connector/-/blob/master/README.md?ref_type=heads) for further information with regards to the configuration.
    In this guide, it is assumed that you have followed the instructions in the **Requirements** section
    
    The minimal configuration required to get your first deployment running, without data apps and ingresses, is as follows:
    
    - Modify `host` to the domain name you configured with the ingress controller:
        ```yaml
        host: domain-name
        ```
    - Modify `ids.info.idsid`, `ids.info.curator`, `ids.info.maintainer` in the `values.ntua.yaml` file to the corresponding identifiers that you filled in during creation of the certificates. `ids.info.idsid` should be the Connector ID, and `ids.info.curator`, `ids.info.maintainer` should be the Participant ID.
        ```yaml
        ids:
          info:
            idsid: IDS_COMPONENT_ID
            curator: IDS_PARTICIPANT_ID
            maintainer: IDS_PARTICIPANT_ID
            titles:
              - CONNECTOR TITLE@en
            descriptions:
              - CONNECTOR DESCRIPTION@en
            accessUrl:
              - https://CONNECTOR_ACCESS_URL/router
        ```
    - Modify fields in the `agents` tab: Keep in mind that `API-version` is the version number you have used for your API when you uploaded in SwaggerHub. It is important to note that in order to retrieve the API spec for the data app, the URL used in the config should be the `/apiproxy/registry/` variant instead of the `/apis/` link from Swagger hub.
      ```yaml
      agents:
          - id: {IDS_COMPONENT_ID}:AgentA # custom agent defined by user
            backEndUrlMapping:
              {API-version}: http://{service-name}:{internal-service-port}
            title: SERVICE TITLE
            openApiBaseUrl: https://app.swaggerhub.com/apiproxy/registry/{USERNAME}/{API-NAME}/
            versions: 
            - {API-version}
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
            -n default \
            --repo https://nexus.dataspac.es/repository/tsg-helm \
            --version 3.2.8 \
            -f values.ntua.yml \
            ntua-connector \
            tsg-connector
    ```

The default data app should appear at: `https://domain-name/data-app/` (forward slash at the end is necessary - not for show :))

# Clean-up
To delete the connector and remove all related resources:
```bash
microk8s kubectl delete clusterissuer lets-encrypt
microk8s kubectl delete secret/ids-identity-secret
microk8s helm uninstall ntua-connector -n default
```
