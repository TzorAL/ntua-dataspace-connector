# Standalone Core Container deployment

This example standalone core container deployment deploys an TSG Connector with only a core container.

This could be used in scenarios where only the artifact handling feature of the core container is used and no other data apps are required.

## Prerequisites
* Nginx Ingress Controller
* Cert Manager with a ClusterIssuer named `letsencrypt`
* Identity secrets must be available in the namespace with secret name `ids-identity-secret`, e.g. by executing:
  ```bash
    kubectl create secret generic \
        -n NAMESPACE \
        ids-identity-secret \
        --from-file=ids.crt=./component.crt \
        --from-file=ids.key=./component.key \
        --from-file=ca.crt=./cachain.crt
  ```

## Configuration
Before using this example, you must change the following fields to reflect your situation:
- `host`: To a DNS name that is configured to point to the ingress controller
- `ids.info`: To the relevant IDs and metadata for the connector
- `ids.daps.url`: To the DAPS the connector will be connected to, where your identity is registered
- `ids.broker`: To the Broker identifier and access url, where you will register your connector instance
- `ids.security.users[0].password`: Modify to a unique BCrypt encoded password

## Deployment
First, add the Helm repository of the TSG components:
```bash
helm repo add tsg https://nexus.dataspac.es/repository/tsg-helm
```
To install the Helm chart, execute:
```bash
helm install --create-namespace -n NAMESPACE DEPLOYMENT_NAME tsg/connector --version 3.2.2 -f values.yaml
```

## Interacting
After deployment, the following user interfaces will be available:
- Core Container UI: https://HOST/ui/

The connector address that other connectors will use to communicate with your connector will be:
- https://HOST/router