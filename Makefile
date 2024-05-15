
# This makefile assumes that in your filesystem:
# 	1. there is a directory for each unique connector:
# 		- named after your connector's deployment name
# 		- containing the following files:
# 			- participant.crt
# 			- participant.key
# 			- component.key
# 			- component.crt
# 			- values.ntua.yaml
# 	2. everything related to all connectors (e.g cluster-issuer.yml) are in the common root directory like so:
# 		.
# 		├── cleanup_pods.sh
# 		├── cluster-issuer.yml
# 		├── Makefile
# 		├── misc
# 		├── notes.md
# 		├── ntua-consumer
# 		└── ntua-provider

# You can change the name at makefile's variables, please ensure that their values comply with your configuration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# set variables used to install connector
# In in recipes, dash "-" is used at the start of commands to ignore errors (usually when items already exists -namespaces,secrets etc-). Please check if that's the case for errors

# You can install connecector with modified name from command line by overwriting variables (e.g make install-connector name=consumer)

user = atzortzis
name = provider
deployment-name = ntua-$(name)
namespace = $(name)-namespace
secret-name = ids-$(name)-secret
values = $(deployment-name)/values.ntua.yml

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Individual recipe steps ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

install-microk8s:
	-sudo snap install microk8s --classic
	-sudo usermod -a -G microk8s $(user)

uninstall-microk8s:
	-sudo gpasswd -d $(user) microk8s
	-sudo snap remove microk8s

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

allow-firewall-ports:
	-sudo ufw allow 80 # allow HTTP
	-sudo ufw allow 443 # allow HTTPS
	-sudo ufw allow 9402 # allow cert-manager
	-sudo ufw allow 9153 # allow another service
	-sudo ufw allow 53 # allow DNS

disallow-firewall-ports:
	-sudo ufw deny 80 # deny HTTP
	-sudo ufw deny 443 # deny HTTPS
	-sudo ufw deny 9402 # deny cert-manager
	-sudo ufw deny 9153 # deny another service
	-sudo ufw deny 53 # deny DNS

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

enable-microk8s-services:
	-sudo microk8s enable ingress
	-sudo microk8s enable cert-manager
	-sudo microk8s enable helm

disable-microk8s-services:
	-sudo microk8s disable helm
	-sudo microk8s disable cert-manager
	-sudo microk8s disable ingress

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

apply-cluster-issuer:
	-microk8s kubectl apply -f cluster-issuer.yml

delete-cluster-issuer:
	-microk8s kubectl delete -f cluster-issuer.yml

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Important recipes ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

build-env: allow-firewall-ports enable-microk8s-services apply-cluster-issuer
delete-env: delete-cluster-issuer disallow-firewall-ports disable-microk8s-services

install-connector:
	-microk8s kubectl create namespace $(namespace)
	-microk8s kubectl create secret generic $(secret-name) -n $(namespace)  --from-file=ids.crt=./$(deployment-name)/component.crt  \
																			--from-file=ids.key=./$(deployment-name)/component.key  \
																			--from-file=ca.crt=./$(deployment-name)/cachain.crt	
	-microk8s helm upgrade  --install 												\
							-n $(namespace) 										\
							--repo https://nexus.dataspac.es/repository/tsg-helm 	\
							--version 3.2.8 										\
							-f $(values) 											\
							$(deployment-name) 										\
							tsg-connector

uninstall-connector:
	-microk8s kubectl delete secret/$(secret-name) -n $(namespace)
	-microk8s helm uninstall $(deployment-name) -n $(namespace)
