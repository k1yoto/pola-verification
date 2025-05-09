# Pola PCE Interface verification for BGP-LS Service Segment

## Setup

1. Clone the repository with submodules:

    ```bash
    git clone --recurse-submodules -b feature/bgp-ls-service-segment https://github.com/k1yoto/pola-verification
    ```

2. Build GoBGP:

    ```bash
    cd pola-verification/gobgp/cmd/gobgp
    go build .
    cd ../gobgpd
    go build .
    ```

3. Build Pola PCE:
    Before building Pola PCE, edit go.mod to change it to reference local GoBGP.

    ```go.mod
    replace github.com/osrg/gobgp/v3 => ../gobgp
    ```

    ```bash
    cd ../../../pola-verification/pola
    go mod tidy

    cd ./cmd/pola
    go build .
    cd ../polad
    go build .
    ```

4. Build Docker image:

    ```bash
    cd ../../../bgp-ls-service-segment
    docker build . -t ubuntu:k1yoto
    ```

## Verify GoBGP only

1. Deploy the network using containerlab:

    ```bash
    sudo clab deploy -t bgp-ls-service-segment-gobgp-pola.clab.yml
    ```

2. Set GoBGP Sender

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp1 bash
    gobgpd -f config/gobgpd.yml
    gobgp global rib add -a ls srv6sid bgp identifier 1 local-asn 65000 local-bgp-ls-id 10 local-bgp-router-id 10.0.0.1 local-bgp-confederation-member 1 sids fc00:0:1::2 multi-topology-id 1 service-type 1 traffic-type 1 opaque-type 1 value test
    ```

3. Set GoBGP Receiver

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp2 bash
    gobgpd -f config/gobgpd.yml
    gobgp global rib -a ls
    ```

4. Set Pola PCE

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp2 bash
    polad -f config/polad.yaml
    ```

    ```
    root@gobgp2:/# polad -f config/polad.yaml
    2025-03-31T15:03:09.040Z	info	Start listening on gRPC port	{"server": "grpc", "listenInfo": "127.0.0.1:50052"}
    2025-03-31T15:03:09.040Z	info	Start listening on PCEP port	{"address": "172.100.200.102:4189"}
    2025-03-31T15:03:09.043Z	info	Request TED update	{"source": "GoBGP", "session": "127.0.0.1:50051"}
    Before State Update TED: &{1 map[]}
    After State Update TED: &{1 map[65000:map[:0xc000449d40]]}
    Node: 1

    Hostname:
    ISIS Area ID:
    SRGB: 0 - 0
    Prefixes:
    Links:
    SRv6 SIDs:
        SIDs: [fc00:0:1::2]
        EndpointBehavior: 0
        MultiTopoIDs: [1]
        ServiceType: 1
        TrafficType: 1
        OpaqueType: 1
        Value: [116 101 115 116]
    ```

## Verify GoBGP and IOS-XRv9k (in progress)

1. Deploy the network using containerlab:
    
    ```bash
    sudo clab deploy -t bgp-ls-service-segment-gobgp-pola-xrv9k.clab.yml
    ```

2. Set GoBGP Receiver

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp2 bash
    gobgpd -f config/gobgpd.yml
    gobgp global rib -a ls
    ```

3. Set Pola PCE

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp2 bash
    polad -f config/polad.yaml
    pola ted -p 50052
    ```

### Show IOS-XRv9k Information

    ```
    RP/0/RP0/CPU0:r1#show bgp link-state link-state summary
    Sat Mar 29 10:10:54.716 UTC
    BGP router identifier 1.1.1.1, local AS number 65000
    BGP generic scan interval 60 secs
    Non-stop routing is enabled
    BGP table state: Active
    Table ID: 0x0   RD version: 19
    BGP table nexthop route policy:
    BGP main routing table version 19
    BGP NSR Initial initsync version 19 (Reached)
    BGP NSR/ISSU Sync-Group versions 0/0
    BGP scan interval 60 secs

    BGP is operating in STANDALONE mode.


    Process       RcvTblVer   bRIB/RIB   LabelVer  ImportVer  SendTblVer  StandbyVer
    Speaker              19         19         19         19          19           0

    Neighbor        Spk    AS MsgRcvd MsgSent   TblVer  InQ OutQ  Up/Down  St/PfxRcd
    172.100.200.102   0 65000     578     760       19    0    0 00:01:53          0
    ```

### Show GoBGP Information

    ```gobgpd
    root@gobgp2:/# gobgpd -f config/gobgpd-xrv9k.yml
    {"level":"info","msg":"gobgpd started","time":"2025-04-10T08:05:22Z"}
    {"Topic":"Config","level":"info","msg":"Finished reading the config file","time":"2025-04-10T08:05:22Z"}
    {"Key":"172.100.200.101","Topic":"config","level":"info","msg":"Add Peer","time":"2025-04-10T08:05:22Z"}
    {"Key":"172.100.200.101","Topic":"Peer","level":"info","msg":"Add a peer configuration","time":"2025-04-10T08:05:22Z"}
    {"Key":"172.100.200.101","State":"BGP_FSM_OPENCONFIRM","Topic":"Peer","level":"info","msg":"Peer Up","time":"2025-04-10T08:05:24Z"}
    Invalid IPv6 prefix length: 8
    Invalid IPv6 prefix length: 8
    Invalid IPv6 prefix length: 8
    ```

    ```gobgp global rib -a ls
    root@gobgp2:/# gobgp global rib -a ls
    Invalid IPv6 prefix length: 2
    Invalid IPv6 prefix length: 2
    Invalid IPv6 prefix length: 2
    Network                                                                                                                                                                                                                                                    Next Hop             AS_PATH              Age        Attrs
    *> NLRI { PREFIXv6 { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 51] PREFIX: [] } }                                                                                                                                                                   172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { NODE { AS:65000 BGP-LS ID:0 [48 48 48 48 46 48 48 48 48 46 48 48 48 49] ISIS-L2:32 } }                                                                                                                                                              172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { LINK { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 51] REMOTE_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 50] LINK: <nil>-><nil>} }                                                                                                       172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} {LsAttributes: {IGP metric: 10} {Max Link BW: 1.25e+08} }]
    *> NLRI { SRv6SID { LOCAL_NODE: {ASN: 65000, BGP LS ID: 0, OSPF AREA: 0, IGP ROUTER ID: [48 48 48 48 46 48 48 48 48 46 48 48 48 49]} SRv6_SID: {SIDs: fc00:b100:1:0:1::} MULTI_TOPO_IDs: {MultiTopoIDs: 2} SERVICE_CHAINING: <nil> OPAQUE_METADATA: <nil> } } 172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    Invalid IPv6 prefix length: 2
    *> NLRI { PREFIXv6 { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 50] PREFIX: [] } }                                                                                                                                                                   172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { LINK { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 50] REMOTE_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 51] LINK: <nil>-><nil>} }                                                                                                       172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} {LsAttributes: {IGP metric: 10} {Max Link BW: 1.25e+08} }]
    *> NLRI { LINK { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 51] REMOTE_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 49] LINK: <nil>-><nil>} }                                                                                                       172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} {LsAttributes: {IGP metric: 10} {Max Link BW: 1.25e+08} }]
    *> NLRI { LINK { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 49] REMOTE_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 51] LINK: <nil>-><nil>} }                                                                                                       172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} {LsAttributes: {IGP metric: 10} {Max Link BW: 1.25e+08} }]
    *> NLRI { LINK { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 50] REMOTE_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 49] LINK: <nil>-><nil>} }                                                                                                       172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} {LsAttributes: {IGP metric: 10} {Max Link BW: 1.25e+08} }]
    Invalid IPv6 prefix length: 2
    *> NLRI { PREFIXv6 { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 49] PREFIX: [] } }                                                                                                                                                                   172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { PREFIXv6 { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 50] PREFIX: [] } }                                                                                                                                                                   172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    Invalid IPv6 prefix length: 2
    *> NLRI { PREFIXv6 { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 51] PREFIX: [] } }                                                                                                                                                                   172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { SRv6SID { LOCAL_NODE: {ASN: 65000, BGP LS ID: 0, OSPF AREA: 0, IGP ROUTER ID: [48 48 48 48 46 48 48 48 48 46 48 48 48 51]} SRv6_SID: {SIDs: fc00:b100:3:0:1::} MULTI_TOPO_IDs: {MultiTopoIDs: 2} SERVICE_CHAINING: <nil> OPAQUE_METADATA: <nil> } } 172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { NODE { AS:65000 BGP-LS ID:0 [48 48 48 48 46 48 48 48 48 46 48 48 48 51] ISIS-L2:32 } }                                                                                                                                                              172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { LINK { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 49] REMOTE_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 50] LINK: <nil>-><nil>} }                                                                                                       172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} {LsAttributes: {IGP metric: 10} {Max Link BW: 1.25e+08} }]
    *> NLRI { PREFIXv6 { LOCAL_NODE: [48 48 48 48 46 48 48 48 48 46 48 48 48 49] PREFIX: [] } }                                                                                                                                                                   172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { NODE { AS:65000 BGP-LS ID:0 [48 48 48 48 46 48 48 48 48 46 48 48 48 50] ISIS-L2:32 } }                                                                                                                                                              172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    *> NLRI { SRv6SID { LOCAL_NODE: {ASN: 65000, BGP LS ID: 0, OSPF AREA: 0, IGP ROUTER ID: [48 48 48 48 46 48 48 48 48 46 48 48 48 50]} SRv6_SID: {SIDs: fc00:b100:2:0:1::} MULTI_TOPO_IDs: {MultiTopoIDs: 2} SERVICE_CHAINING: <nil> OPAQUE_METADATA: <nil> } } 172.100.200.101                           00:00:39   [{Origin: i} {LocalPref: 100} ]
    ```

### Show Pola Information

    ```polad
    root@gobgp2:/# polad -f config/polad.yaml
    2025-04-10T06:01:32.558Z	info	Start listening on gRPC port	{"server": "grpc", "listenInfo": "127.0.0.1:50052"}
    2025-04-10T06:01:32.558Z	info	start listening on PCEP port	{"address": "172.100.200.102:4189"}
    2025-04-10T06:01:34.881Z	info	start PCEP session	{"server": "pcep", "session": "172.100.200.101"}
    2025-04-10T06:06:23.240Z	info	Received GetTed API request	{"server": "grpc"}
    2025-04-10T06:11:32.589Z	error	Failed session with GoBGP	{"error": "failed to convert path to TED element: failed to process LS Link NLRI: failed to parse local IP address: ParseAddr(\"\"): unable to parse IP"}
    2025-04-10T06:21:32.619Z	error	Failed session with GoBGP	{"error": "failed to convert path to TED element: failed to process LS Link NLRI: failed to parse local IP address: ParseAddr(\"\"): unable to parse IP"}
    2025-04-10T06:31:32.649Z	error	Failed session with GoBGP	{"error": "failed to convert path to TED element: failed to process LS Node NLRI: expected 1 SR Capability TLV, got: 0"}
    ```