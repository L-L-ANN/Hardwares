# BIOPAC Developer Suites 

Our lab also purchased the BIOPAC Devloper Suites license, which is installed on the BIOPAC laptop.

1. BIOPAC Basic Scripting and Workflow
2. Network Data Tranfer (NDT)
3. Hardware API
4. Software API 

# BIOPAC MP200 Netwrok Data Transfer (NDT) 

BIOPAC Network data transfer (NDT) allows for analog, digital,
and calculation channel data to be streamed using TCP or UDP protocols
during data acquisitions.  

This allows third-party applications to
analyze data as it is being acquired either on the same computer as
AcqKnowledge or a different computer on the network.

## Client Example 
BIOPAC does not provide an official NDT client; it only offers a Python example (biopacndt.py), requiring users to develop their own client program.

1)  Create an AcqNdtServer object either by manually entering the
address and port, by locating servers with FindAcqNdtServers(), or
just connecting to the first available AcqKnoweldge server with
AcqNdtQuickConnect().

2)  Load the hardware acquisition settings using the 
AcqNdtServer.LoadTemplate() function and an AcqKnowledge graph 
template file.

3)  Construct an AcqNdtDataServer object and register the callbacks
used to process data.

4)  Begin listening for data connections by using AcqNdtDataServer.Start()

5)  Begin data acquisition with AcqNdtServer.toggleAcquisition()

6)  Wait for the data acquisition to complete using 
AcqNdtServer.WaitForAcquisitionEnd().  During this time incoming data
will continue to be processed on threads.

7)  Release resources used and halt data processing with
AcqNdtDataServer.Stop().
<br>

# BIOPAC Hareware API (BHAPI)
The BIOPAC Hardware API allows software developers to control BIOPAC acquisition units *directly*, without using AcqKnowledge.
