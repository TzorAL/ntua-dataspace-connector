# Default OpenAPI deployment

This example default OpenAPI deployment deploys an TSG Connector with a core container and the OpenAPI data app.

The OpenAPI data app is configured with Policy Enforcement, so all message exchanged with the data app will be routed through the Policy Enforcement Framework in the core container. For managing the policies, an ingress is created on path `/data-app/` that is secured with credentials configured in the core container `ids.security.users`. 

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
- `ids.security.apiKeys[0].key`: Modify to create a unique API key
- `ids.security.users[0].password`: Modify to a unique BCrypt encoded password
- `containers[0].apiKey`: Synchronize with the value of `ids.security.apiKeys[0].key`
- `containers[0].config`: Modify the configuration of the OpenAPI data app, at least the Agent configuration with unique identifiers

## Deployment
First, add the Helm repository of the TSG components:
```bash
helm repo add tsg https://nexus.dataspac.es/repository/tsg-helm
```
To install the Helm chart, execute:
```bash
helm install --create-namespace -n NAMESPACE DEPLOYMENT_NAME tsg/connector --version 3.0.0 -f values.yaml
```

## Interacting
After deployment, the following user interfaces will be available:
- https://HOST/ui/
- https://HOST/data-app/

Both can be accessed with the credentials configured in `ids.security.users`.

The connector address that other connectors will use to communicate with your connector will be:
- https://HOST/router