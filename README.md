# Pola Interface verification for BGP-LS Service Segment

## Setup

1. Clone the repository with submodules:

    ```bash
    git clone --recurse-submodules https://github.com/k1yoto/pola-verification
    ```

2. Build GoBGP:

    ```bash
    cd pola-verification/gobgp/cmd/gobgp
    go build .
    cd ../gobgpd
    go build .
    ```

3. Build Pola:

    ```bash
    cd ../../../pola-verification/pola/cmd/pola
    go build .
    cd ../polad
    go build .
    ```

4. Build the Docker image:

    ```bash
    cd ../../../bgp-ls-service-segment
    docker build . -t ubuntu:k1yoto
    ```

## Verify GoBGP only

1. Deploy the network using [containerlab]:

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

4. Set Pola

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

1. Deploy the network using [containerlab]:
    
    ```bash
    sudo clab deploy -t bgp-ls-service-segment-gobgp-pola-xrv9k.clab.yml
    ```

2. Set GoBGP Receiver

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp2 bash
    gobgpd -f config/gobgpd.yml
    gobgp global rib -a ls
    ```

3. Set Pola

    ```bash
    docker exec -it clab-bgp-ls-service-segment-gobgp-only-gobgp2 bash
    polad -f config/polad.yaml
    ```

### Show IOS-XRv9k Information

    ```
    RP/0/RP0/CPU0:r1#show bgp link-state link-state
    Sat Mar 29 09:27:48.497 UTC
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

    Status codes: s suppressed, d damped, h history, * valid, > best
                i - internal, r RIB-failure, S stale, N Nexthop-discard
    Origin codes: i - IGP, e - EGP, ? - incomplete
    Prefix codes: E link, V node, T IP reachable route, S SRv6 SID, SP SRTE Policy, u/U unknown
                I Identifier, N local node, R remote node, L link, P prefix, S SID, C candidate path
                L1/L2 ISIS level-1/level-2, O OSPF, D direct, ST static/peer-node, SR Segment Routing
                a area-ID, l link-ID, t topology-ID, s ISO-ID,
                c confed-ID/ASN, b bgp-identifier, r router-ID, te te-router-ID, sd SID
                i if-address, n nbr-address, o OSPF Route-type, p IP-prefix
                d designated router address, po protocol-origin, f flag
                e endpoint-ip, cl color, as originator-asn oa originator-address
                di discriminator
    Network            Next Hop            Metric LocPrf Weight Path
    *> [V][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0001.00]]/328
                        0.0.0.0                                0 i
    *> [V][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0002.00]]/328
                        0.0.0.0                                0 i
    *> [V][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0003.00]]/328
                        0.0.0.0                                0 i
    *> [E][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0001.00]][R[c65000][b0.0.0.0][s0000.0000.0002.00]][L[l9.6][t0x0002]]/712
                        0.0.0.0                                0 i
    *> [E][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0001.00]][R[c65000][b0.0.0.0][s0000.0000.0003.00]][L[l10.8][t0x0002]]/712
                        0.0.0.0                                0 i
    *> [E][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0002.00]][R[c65000][b0.0.0.0][s0000.0000.0001.00]][L[l6.9][t0x0002]]/712
                        0.0.0.0                                0 i
    *> [E][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0002.00]][R[c65000][b0.0.0.0][s0000.0000.0003.00]][L[l7.9][t0x0002]]/712
                        0.0.0.0                                0 i
    *> [E][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0003.00]][R[c65000][b0.0.0.0][s0000.0000.0001.00]][L[l8.10][t0x0002]]/712
                        0.0.0.0                                0 i
    *> [E][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0003.00]][R[c65000][b0.0.0.0][s0000.0000.0002.00]][L[l9.7][t0x0002]]/712
                        0.0.0.0                                0 i
    *> [T][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0001.00]][P[t0x0002][pfc00:b100:1::/64]]/480
                        0.0.0.0                                0 i
    *> [T][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0001.00]][P[t0x0002][pfc00:b100:1::1/128]]/544
                        0.0.0.0                                0 i
    *> [T][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0002.00]][P[t0x0002][pfc00:b100:2::/64]]/480
                        0.0.0.0                                0 i
    *> [T][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0002.00]][P[t0x0002][pfc00:b100:2::1/128]]/544
                        0.0.0.0                                0 i
    *> [T][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0003.00]][P[t0x0002][pfc00:b100:3::/64]]/480
                        0.0.0.0                                0 i
    *> [T][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0003.00]][P[t0x0002][pfc00:b100:3::1/128]]/544
                        0.0.0.0                                0 i
    *> [S][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0001.00]][S[t0x0002][sdfc00:b100:1:0:1::]]/536
                        0.0.0.0                                0 i
    *> [S][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0002.00]][S[t0x0002][sdfc00:b100:2:0:1::]]/536
                        0.0.0.0                                0 i
    *> [S][L2][I0x20][N[c65000][b0.0.0.0][s0000.0000.0003.00]][S[t0x0002][sdfc00:b100:3:0:1::]]/536
                        0.0.0.0                                0 i

    Processed 18 prefixes, 18 paths
    ```

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

    ```
    root@gobgp2:/# gobgp neighbor
    Peer               AS  Up/Down State       |#Received  Accepted
    172.100.200.101 65000 00:02:34 Establ      |       18        18
    root@gobgp2:/#
    root@gobgp2:/# gobgp global rib -a ls
    panic: runtime error: index out of range [1] with length 1

    goroutine 1 [running]:
    github.com/osrg/gobgp/v3/pkg/packet/bgp.(*LsTLVIPReachability).ToIPNet(0xc0002d10e0, 0x1)
        /home/nakata/dev/pola-verification/gobgp/pkg/packet/bgp/bgp.go:7494 +0x225
    github.com/osrg/gobgp/v3/pkg/packet/bgp.(*LsPrefixDescriptor).ParseTLVs(0xc000225688, {0xc0002d1100?, 0x20?, 0x148fa80?}, 0x1)
        /home/nakata/dev/pola-verification/gobgp/pkg/packet/bgp/bgp.go:5548 +0x93
    github.com/osrg/gobgp/v3/pkg/packet/bgp.(*LsPrefixV6NLRI).String(0xc0002d3300)
        /home/nakata/dev/pola-verification/gobgp/pkg/packet/bgp/bgp.go:5740 +0xaa
    github.com/osrg/gobgp/v3/pkg/packet/bgp.(*LsAddrPrefix).String(0xc000154ae0?)
        /home/nakata/dev/pola-verification/gobgp/pkg/packet/bgp/bgp.go:9773 +0x22
    main.makeShowRouteArgs(0xc0001a5e00, 0x0?, {0xc000225910?, 0x8b93d5?, 0xc0003160d0?}, 0x1, 0x1, 0x0, 0x0, 0x0, ...)
        /home/nakata/dev/pola-verification/gobgp/cmd/gobgp/neighbor.go:663 +0xcc2
    main.showRoute({0xc0002f90e0, 0x12, 0x14af860?}, 0x1, 0x1, 0x0, 0x0, 0x0, 0x0)
        /home/nakata/dev/pola-verification/gobgp/cmd/gobgp/neighbor.go:673 +0xc16
    main.showNeighborRib({0xd593f0, 0x6}, {0x0, 0x0}, {0xc0002d0260, 0x0, 0x2})
        /home/nakata/dev/pola-verification/gobgp/cmd/gobgp/neighbor.go:1083 +0xc8b
    main.showGlobalRib(...)
        /home/nakata/dev/pola-verification/gobgp/cmd/gobgp/global.go:2167
    main.newGlobalCmd.func2(0xc0001a5b00?, {0xc0002d0260?, 0x4?, 0xd57d3e?})
        /home/nakata/dev/pola-verification/gobgp/cmd/gobgp/global.go:2469 +0x31
    github.com/spf13/cobra.(*Command).execute(0xc00018f808, {0xc0002d0240, 0x2, 0x2})
        /home/nakata/go/pkg/mod/github.com/spf13/cobra@v1.7.0/command.go:944 +0x843
    github.com/spf13/cobra.(*Command).ExecuteC(0xc00018f208)
        /home/nakata/go/pkg/mod/github.com/spf13/cobra@v1.7.0/command.go:1068 +0x3a5
    github.com/spf13/cobra.(*Command).Execute(...)
        /home/nakata/go/pkg/mod/github.com/spf13/cobra@v1.7.0/command.go:992
    main.main()
        /home/nakata/dev/pola-verification/gobgp/cmd/gobgp/main.go:32 +0xca
    ```

### Show Pola Information

    ```
    root@gobgp2:/# polad -f config/polad.yaml
    2025-03-29T10:12:43.818Z	info	Start listening on gRPC port	{"server": "grpc", "listenInfo": "127.0.0.1:50052"}
    2025-03-29T10:12:43.818Z	info	Start listening on PCEP port	{"address": "172.100.200.102:4189"}
    2025-03-29T10:12:43.822Z	info	Request TED update	{"source": "GoBGP", "session": "127.0.0.1:50051"}
    2025-03-29T10:12:43.822Z	error	Failed session with GoBGP	{"error": "proto: invalid empty type URL"}
    2025-03-29T10:13:15.636Z	info	Start PCEP session	{"server": "pcep", "session": "172.100.200.101"}
    ```