# Overview

Initially created with

```shell
aztfy rg --generate-mapping-file "scicoria-ag"
```


Retrieve using mapping file

```shell
aztfy mapping-file -o .\generated\ -f aztfyResourceMapping.json
```

```shell
aztfy mapping-file -n -k -o .\generated\ -f aztfyResourceMapping.json
```


```
The client sends a request to the REST API through the DNS name of the Traffic Manager.
The client's DNS resolver sends a DNS query to the DNS server to resolve the DNS name of the Traffic Manager to an IP address.
The DNS server responds with the IP address of the Traffic Manager.
The client sends the request to the IP address of the Traffic Manager.
The Traffic Manager receives the request and uses the traffic routing method configured (such as round-robin or priority) to select an endpoint to route the request to.
The Traffic Manager forwards the request to the selected endpoint.
The REST API application receives the request and processes it.
The REST API application sends a response to the Traffic Manager.
The Traffic Manager receives the response and forwards it back to the client
```


```
sequenceDiagram
    car->>+DNS: resolve dms.gm.com
    DNS->>-car: CNAME is spc-poo40y72.trafficmanager.net with IP 40.117.233.151





    


```