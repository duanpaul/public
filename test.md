```mermaid

graph TD
    subgraph Internet
        User[User]
    end

    subgraph "GSLB"
        HyperspaceWeb   
    end

    subgraph "Data Center 1"
        subgraph "GSLB 1"
            GSLB1[GSLB]
        end

        subgraph "Load Balancer 1"
            LB1[Load Balancer]
        end

        subgraph "Application Servers 1"
            AS1_1[App Server 1]
            AS1_2[App Server 2]
        end
    end

    subgraph "Data Center 2"
        subgraph "GSLB 2"
            GSLB2[GSLB]
        end

        subgraph "Load Balancer 2"
            LB2[Load Balancer]
        end

        subgraph "Application Servers 2"
            AS2_1[App Server 1]
            AS2_2[App Server 2]
        end
    end

    User --- HyperspaceWeb 
    HyperspaceWeb  --- GSLB1
    HyperspaceWeb  --- GSLB2

