# Infrastructure Monitoring and Alerting Deployments

## Table of contents

- [About this repository](#about-this-repository)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Set up AWS Vault](#set-up-aws-vault)
- [Usage](#usage)
  - [Accessing the cluster](#accessing-the-cluster)
  - [Send metrics from your local prometheus](documentation/prometheus-remote-write.md)
  - [Deploy to your namespace](#deploy-to-your-namespace)
  - [Azure metrics exporter](documentation/azure-metrics-exporter.md)
  - [Cloudwatch metrics Exporter](documentation/cloudwatch-exporter.md) (including adding custom metrics)
  - [Removing your namespace and associated resources](#removing-your-namespace-and-associated-resources)
  - [Troubleshooting](#troubleshooting)
- [Other Documentation](#other-documentation)
- [Our other repositories](#our-other-repositories)
- [License](#license)

## About this repository

The IMA deployments repo holds the configuration for applications which are
deployed to the IMA platform using Helm/Kubernetes. See the [IMA Platform infrastructure repository](https://github.com/ministryofjustice/staff-infrastructure-monitoring) for information on the platform as a whole.

## Getting started
### Prerequisites:

Before you start you should ensure that you have installed the following:
- [AWS Vault](https://github.com/99designs/aws-vault) (>= 6.0.0) - to easily manage and switch between AWS account profiles on the command line
- [helm](https://helm.sh/docs/intro/install/) - to manage kubernetes deployments
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - to manage kubernetes resources

| :bangbang: IMPORTANT |  
|:-----|  
| If you are a MoJ AWS SSO user, it is highly recommended that you follow the CloudOps best practices provided [step-by-step guide](https://ministryofjustice.github.io/cloud-operations/documentation/team-guide/best-practices/use-aws-sso.html#re-configure-aws-vault) to configure your AWS Vault with AWS SSO. | 

### Set up your AWS Vault with SSO
To set up AWS Vault follow the instructions [here.](https://ministryofjustice.github.io/cloud-operations/documentation/team-guide/best-practices/use-aws-sso.html#re-configure-aws-vault)

## Usage

### Accessing the cluster

| :bangbang: IMPORTANT |  
|:-----|  
| Only access the cluster directly when absolutely necessary, changes should always be applied by committing to this repo, if you make changes using `kubectl` they will be overwritten when the pipeline runs. Please pair when possible if working with the cluster directly. | 

In order to run `kubectl` commands against the cluster you will need to do the following:

1. Ensure your AWS vault is setup and using the `shared-services-cli` profile.

2. Create a `.env` file.

```sh
cp `.env.example` `.env`
```

3. Populate the `.env` and the `KUBERNETES_NAMESPACE` fields with the environment you wish to connect to e.g
```
ENV=development
KUBERNETES_NAMESPACE=development
```
4. Run `make deploy`

5. Depending on your setup, you may have to manually copy your kubeconfig by using this command 
```sh
cp ./kubernetes/kubeconfig ~/.kube/config
```

6. Test by running `kubectl get pods`

### Deploy to your namespace
This will deploy prometheus, thanos, cloudwatch & azure metrics exporters to the development EKS cluster in a dedicated namespace.

1. Deploy the alerting configuration charts in [Staff Infrastructure Monitoring Config repo](https://github.com/ministryofjustice/staff-infrastructure-monitoring-datasource-config#ima-development).

2. Create a `.env` file.

```sh
cp `.env.example` `.env`
```
3. Modify the `.env` file and replace all necessary values. `KUBERNETES_NAMESPACE` should match the namespace name you used in the [configuration repository](https://github.com/ministryofjustice/staff-infrastructure-monitoring-datasource-config).
4. Deploy the charts in this repo by running

```sh
make deploy
```

5. The script will output a prometheus endpoint. You can use this endpoint when adding a prometheus data source in the development grafana instance.

### Removing your namespace and associated resources
This will delete your namespace on the cluster and all pods/services etc. associated with it. Included the alerting configuration which is deployed from the [Staff Infrastructure Monitoring Config repo](https://github.com/ministryofjustice/staff-infrastructure-monitoring-datasource-config).

```sh
  make remove-workspace
```

### Troubleshooting

Switch Role (AWS Console)

As the EKS clusters are deployed using an assumed role from Shared Services, to access them directly in the console you will need to manually assume that role.

1.	Login to AWS Shared-Services console and open the parameter store, lookup required role `/codebuild/pttp-ci-ima-pipeline/$ENV/assume_role` and note down, account number and role name. 
```
Account Number: 0123456789 
Role Name: LandingZone 
```

2.	 Still within the AWS console click on your account name in the top right and then select ‘Switch role’

![image](https://user-images.githubusercontent.com/41325732/164258408-b03ba5bc-64cd-4e99-9b87-e9bebe870ca9.png)

3.	Input account number and role followed a Display Name of your choice i.e. "Dev Landing Zone" and then click on ‘Switch Role’ 

![image](https://user-images.githubusercontent.com/41325732/164258480-6c2504b3-5f05-4ac0-8ffa-2bfae5581079.png)

You will now be able to drill down into the EKS cluster config within the AWS console.

Further information can be found at https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html


## Other Documentation

- [Azure metrics exporter](documentation/azure-metrics-exporter.md)

## Our other repositories

- [IMA Platform](https://github.com/ministryofjustice/staff-infrastructure-monitoring) - to monitor MoJ infrastructure and physical devices
- [Configuration](https://github.com/ministryofjustice/staff-infrastructure-monitoring-datasource-config) - to provision configuration for the IMA Platform
- [SNMP Exporter](https://github.com/ministryofjustice/staff-infrastructure-monitoring-snmpexporter) - to scrape data from physical devices (Docker image)
- [Blackbox Exporter](https://github.com/ministryofjustice/staff-infrastructure-monitoring-blackbox-exporter) - to probe endpoints over HTTP, HTTPS, DNS, TCP and ICMP.s (Docker image)
- [Metric Aggregation Server](https://github.com/ministryofjustice/staff-infrastructure-metric-aggregation-server) - to pull data from the SNMP exporter (Docker image)
- [Shared Services Infrastructure](https://github.com/ministryofjustice/staff-device-shared-services-infrastructure) - to manage our CI/CD pipelines

## License

[MIT License](LICENSE)
