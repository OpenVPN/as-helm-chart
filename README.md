![openvpn-as](https://as-prod-public.s3.us-west-1.amazonaws.com/openvpn_logo.svg)
# OpenVPN Access Server Helm chart

## Introduction

This chart installs `openvpn/openvpn-as` Docker Hub image on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `my-vpn`:

```console
helm install my-vpn ./as-helm-chart
```

These commands deploy openvpn-as on the Kubernetes cluster in the default configuration.

## Uninstalling the Chart

To uninstall/delete the `my-vpn` deployment:

```console
helm delete my-vpn
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The configurable parameters of the openvpn-as chart can be found in `values.yaml`.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```console
helm install my-vpn -f values.yaml ./as-helm-chart
```

## Access server custom configuration

Custom configuration is possible via Kubernetes [postStart](https://kubernetes.io/docs/tasks/configure-pod-container/attach-handler-lifecycle-event/) feature.

***Important: If you plan to use `sacli` in the `postStart` script, ensure that the Access Server service is fully up and running beforehand.***  
You can find an example of how to wait for the service in the Inline Script below.

If you set `postStart.enabled=true`, this chart runs default `scripts/configure.sh` from the chart.
However, that default script is just an example which waits while AS initialization is finished.
The default `scripts/configure.sh` can be overridden.

#### Override with Inline Script
To override the `postStart` script you can provide the script directly via the `values.yaml`.

```yaml
postStart:
  enabled: true
  customScript: |
    #!/bin/bash
    # Waiting for AS service initialization
    until /usr/local/openvpn_as/scripts/sacli status 2>/dev/null |grep -q '"api": "on"'
    do
        sleep 2
    done
    /usr/local/openvpn_as/scripts/sacli --user "openvpn" --new_pass "secure123" SetLocalPassword
```

#### Use a separate Kubernetes Secret
The chart will create a Kubernetes secret out of the provided script. Instead you can also provide your own secret directly with the `postStart.secretRefName` key. Note that the the script must be available as `configure.sh` in the secret.
```yaml
postStart:
  enabled: true
  secretRefName: my-custom-script
```

Create it:

```console
kubectl create secret generic my-custom-script \
  --from-file=configure.sh=./custom.sh
```

## TUN device in Kubernetes

A TUN device in Kubernetes is a virtual network interface that allows for packet routing between user space and the kernel, commonly used for applications like VPNs. To use a TUN device, pods typically need specific permissions, and starting from Kubernetes version 1.31.3, they must run in privileged mode to create and access the TUN device.

To create and use TUN devices within Kubernetes pods, specific permissions are necessary:
- Kubernetes versions prior to 1.31.3: The NET_ADMIN capability was sufficient for creating TUN devices.
- Kubernetes version 1.31.3 and later: Pods must run in privileged mode to create TUN devices. This change was made due to security improvements that restrict access to certain system resources.

Instead of using privileged mode [Device Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/) can be used.

Kubernetes supports device plugins that can expose host devices to pods. For TUN devices, you can deploy a device plugin that allows access to /dev/net/tun. This can be done using a DaemonSet that runs on each node.
