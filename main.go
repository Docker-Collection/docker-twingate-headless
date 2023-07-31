package main

/// Write by ChatGPT

import (
	"fmt"
	"io"
	"net"
	"os"
	"strings"
	"sync"
)

var (
	shutdownChan chan struct{}
	wg           sync.WaitGroup
)

func handleTCPConnection(localConn net.Conn, remoteConn net.Conn) {
	defer wg.Done()

	wg.Add(1)

	// Use a wait group to keep track of the copy operations
	copyWg := sync.WaitGroup{}
	copyWg.Add(2)

	// Copy local-to-remote
	go func() {
		_, err := io.Copy(remoteConn, localConn)
		if err != nil {
			fmt.Println("Error copying data to remote TCP:", err)
		}
		copyWg.Done()
	}()

	// Copy remote-to-local
	go func() {
		_, err := io.Copy(localConn, remoteConn)
		if err != nil {
			fmt.Println("Error copying data to local TCP:", err)
		}
		copyWg.Done()
	}()

	// Wait for both copy operations to complete before closing the connections
	copyWg.Wait()

	// Close the connections after both copy operations are done
	localConn.Close()
	remoteConn.Close()

	wg.Done()
}

func handleUDPConnection(udpConn *net.UDPConn, remoteAddr *net.UDPAddr) {
	defer wg.Done()

	buf := make([]byte, 1024)
	for {
		n, _, err := udpConn.ReadFromUDP(buf)
		if err != nil {
			// Check if it's a graceful shutdown
			select {
			case <-shutdownChan:
				fmt.Println("Graceful shutdown completed.")
				return
			default:
				fmt.Println("Error reading UDP packet:", err)
				continue
			}
		}

		_, err = udpConn.WriteToUDP(buf[:n], remoteAddr)
		if err != nil {
			fmt.Println("Error writing to remote UDP:", err)
		}
	}
}

func main() {
	mappings := os.Getenv("PORT_MAPPINGS") // Set this environment variable to port mappings (e.g., "8080:example.com:6060,9090:example.com:7070")

	if mappings == "" {
		fmt.Println("Missing environment variable PORT_MAPPINGS. Please set it to a comma-separated list of localPort:remoteAddress:remotePort mappings.")
		return
	}

	mappingPairs := strings.Split(mappings, ",")
	for _, mapping := range mappingPairs {
		parts := strings.Split(mapping, ":")
		if len(parts) != 3 {
			fmt.Println("Invalid mapping format:", mapping)
			continue
		}

		localPort := parts[0]
		remoteAddress := parts[1]
		remotePort := parts[2]

		localTCPAddr := "0.0.0.0:" + localPort
		remoteTCPAddr := remoteAddress + ":" + remotePort

		// Create TCP listener
		tcpListener, err := net.Listen("tcp", localTCPAddr)
		if err != nil {
			fmt.Println("Error listening on TCP address:", localTCPAddr, err)
			continue
		}

		// Resolve remote TCP address
		remoteTCPConn, err := net.Dial("tcp", remoteTCPAddr)
		if err != nil {
			fmt.Println("Error connecting to remote TCP address:", remoteTCPAddr, err)
			tcpListener.Close()
			continue
		}

		fmt.Printf("Port forwarding started on %s to remote %s\n", localTCPAddr, remoteTCPAddr)

		wg.Add(1)
		go func(localTCPAddr string, remoteTCPAddr string, tcpListener net.Listener, remoteTCPConn net.Conn) {
			for {
				// Handle TCP connections
				tcpConn, err := tcpListener.Accept()
				if err != nil {
					// Check if it's a graceful shutdown
					select {
					case <-shutdownChan:
						fmt.Println("Graceful shutdown completed for address:", localTCPAddr)
						tcpListener.Close()
						remoteTCPConn.Close()
						wg.Done()
						return
					default:
						fmt.Println("Error accepting TCP connection for address:", localTCPAddr, err)
						continue
					}
				}

				remoteTCPConn, err := net.Dial("tcp", remoteTCPAddr)
				if err != nil {
					fmt.Println("Error connecting to remote TCP address:", remoteTCPAddr, err)
					tcpConn.Close()
					continue
				}

				wg.Add(1)
				go handleTCPConnection(tcpConn, remoteTCPConn)
			}
		}(localTCPAddr, remoteTCPAddr, tcpListener, remoteTCPConn)
	}

	// Wait for incoming signals (graceful shutdown)
	<-shutdownChan
	fmt.Println("\nGraceful shutdown initiated...")
	wg.Wait()
}