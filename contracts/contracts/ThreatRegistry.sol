// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";


contract ThreatRegistry is Ownable {
        
    struct ThreatReport {
        address reporter;
        uint256 timestamp;
        uint8 threatLevel; 
        string threatType; 
        string evidence; 
        bool verified; 
        uint256 upvotes;
    }
        
    event ThreatReported(
        address indexed contractAddress,
        address indexed reporter,
        uint8 threatLevel,
        string threatType
    );
    
    event ThreatVerified(address indexed contractAddress, uint256 reportIndex, bool verified);
    event ThreatUpdated(address indexed contractAddress, uint256 reportIndex, uint8 newThreatLevel);
    event ReportUpvoted(address indexed contractAddress, uint256 reportIndex, address indexed voter);
    event ThreatStatusChanged(address indexed contractAddress, bool isVerified);
    
    mapping(address => ThreatReport[]) public threats;
    mapping(address => bool) public isVerifiedThreat;
    mapping(address => mapping(uint256 => mapping(address => bool))) public hasUpvoted;
    mapping(address => mapping(address => bool)) public hasReported;
    
    address public verifier;
    
    uint8 public constant AUTO_VERIFY_THRESHOLD = 90;
    uint256 public constant MIN_UPVOTES_FOR_REVIEW = 5;
        
    modifier onlyVerifier() {
        require(msg.sender == verifier || msg.sender == owner(), "ThreatRegistry: Not authorized");
        _;
    }
    
    
    constructor(address _verifier) Ownable(msg.sender) {
        require(_verifier != address(0), "ThreatRegistry: Invalid verifier");
        verifier = _verifier;
    }
    

    function reportThreat(
        address contractAddress,
        uint8 threatLevel,
        string calldata threatType,
        string calldata evidence
    ) external {
        require(contractAddress != address(0), "ThreatRegistry: Invalid address");
        require(threatLevel <= 100, "ThreatRegistry: Invalid threat level");
        require(bytes(threatType).length > 0, "ThreatRegistry: Empty threat type");
        require(!hasReported[contractAddress][msg.sender], "ThreatRegistry: Already reported");
        
        hasReported[contractAddress][msg.sender] = true;
        
        bool isAutoVerified = threatLevel >= AUTO_VERIFY_THRESHOLD;
        
        ThreatReport memory report = ThreatReport({
            reporter: msg.sender,
            timestamp: block.timestamp,
            threatLevel: threatLevel,
            threatType: threatType,
            evidence: evidence,
            verified: isAutoVerified,
            upvotes: 0
        });
        
        threats[contractAddress].push(report);
        uint256 reportIndex = threats[contractAddress].length - 1;
        
        if (isAutoVerified && !isVerifiedThreat[contractAddress]) {
            isVerifiedThreat[contractAddress] = true;
            emit ThreatVerified(contractAddress, reportIndex, true);
            emit ThreatStatusChanged(contractAddress, true);
        }
        
        emit ThreatReported(contractAddress, msg.sender, threatLevel, threatType);
    }
    

    function upvoteReport(address contractAddress, uint256 reportIndex) external {
        require(reportIndex < threats[contractAddress].length, "ThreatRegistry: Invalid index");
        require(!hasUpvoted[contractAddress][reportIndex][msg.sender], "ThreatRegistry: Already voted");
        require(threats[contractAddress][reportIndex].reporter != msg.sender, "ThreatRegistry: Cannot upvote own report");
        
        hasUpvoted[contractAddress][reportIndex][msg.sender] = true;
        threats[contractAddress][reportIndex].upvotes++;
        
        emit ReportUpvoted(contractAddress, reportIndex, msg.sender);
    }
    

    function verifyThreat(address contractAddress, uint256 reportIndex) external onlyVerifier {
        require(reportIndex < threats[contractAddress].length, "ThreatRegistry: Invalid index");
        require(!threats[contractAddress][reportIndex].verified, "ThreatRegistry: Already verified");
        
        threats[contractAddress][reportIndex].verified = true;
        
        if (!isVerifiedThreat[contractAddress]) {
            isVerifiedThreat[contractAddress] = true;
            emit ThreatStatusChanged(contractAddress, true);
        }
        
        emit ThreatVerified(contractAddress, reportIndex, true);
    }
    

    function unverifyThreat(address contractAddress, uint256 reportIndex) external onlyVerifier {
        require(reportIndex < threats[contractAddress].length, "ThreatRegistry: Invalid index");
        require(threats[contractAddress][reportIndex].verified, "ThreatRegistry: Not verified");
        
        threats[contractAddress][reportIndex].verified = false;
        
        bool hasVerifiedReports = false;
        for (uint256 i = 0; i < threats[contractAddress].length; i++) {
            if (threats[contractAddress][i].verified) {
                hasVerifiedReports = true;
                break;
            }
        }
        
        if (!hasVerifiedReports && isVerifiedThreat[contractAddress]) {
            isVerifiedThreat[contractAddress] = false;
            emit ThreatStatusChanged(contractAddress, false);
        }
        
        emit ThreatVerified(contractAddress, reportIndex, false);
    }
    

    function batchVerifyThreats(
        address[] calldata contractAddresses,
        uint256[] calldata reportIndexes
    ) external onlyVerifier {
        require(contractAddresses.length == reportIndexes.length, "ThreatRegistry: Length mismatch");
        
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address addr = contractAddresses[i];
            uint256 idx = reportIndexes[i];
            
            if (idx < threats[addr].length && !threats[addr][idx].verified) {
                threats[addr][idx].verified = true;
                
                if (!isVerifiedThreat[addr]) {
                    isVerifiedThreat[addr] = true;
                    emit ThreatStatusChanged(addr, true);
                }
                
                emit ThreatVerified(addr, idx, true);
            }
        }
    }
    

    function updateThreatLevel(
        address contractAddress,
        uint256 reportIndex,
        uint8 newThreatLevel
    ) external onlyVerifier {
        require(reportIndex < threats[contractAddress].length, "ThreatRegistry: Invalid index");
        require(newThreatLevel <= 100, "ThreatRegistry: Invalid threat level");
        
        threats[contractAddress][reportIndex].threatLevel = newThreatLevel;
        
        emit ThreatUpdated(contractAddress, reportIndex, newThreatLevel);
    }
    

    function getReportCount(address contractAddress) external view returns (uint256) {
        return threats[contractAddress].length;
    }
    

    function getReport(
        address contractAddress,
        uint256 reportIndex
    ) external view returns (ThreatReport memory) {
        require(reportIndex < threats[contractAddress].length, "ThreatRegistry: Invalid index");
        return threats[contractAddress][reportIndex];
    }
    
    function getAllReports(address contractAddress) external view returns (ThreatReport[] memory) {
        return threats[contractAddress];
    }
    

    function getHighUpvoteReports(address contractAddress) external view returns (uint256[] memory indexes) {
        uint256 count = 0;
        uint256 totalReports = threats[contractAddress].length;
        
        for (uint256 i = 0; i < totalReports; i++) {
            if (threats[contractAddress][i].upvotes >= MIN_UPVOTES_FOR_REVIEW && 
                !threats[contractAddress][i].verified) {
                count++;
            }
        }
        
        indexes = new uint256[](count);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < totalReports; i++) {
            if (threats[contractAddress][i].upvotes >= MIN_UPVOTES_FOR_REVIEW && 
                !threats[contractAddress][i].verified) {
                indexes[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return indexes;
    }
    

    function getAggregateThreatScore(address contractAddress) external view returns (uint8) {
        uint256 reportCount = threats[contractAddress].length;
        if (reportCount == 0) return 0;
        
        uint256 totalScore = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < reportCount; i++) {
            ThreatReport memory report = threats[contractAddress][i];
            
            uint256 weight = report.verified ? 3 : 1;
            totalScore += report.threatLevel * weight;
            totalWeight += weight;
        }
        
        return uint8(totalScore / totalWeight);
    }
    

    function isThreat(address contractAddress) external view returns (bool) {
        return threats[contractAddress].length > 0;
    }
    

    function isVerified(address contractAddress) external view returns (bool) {
        return isVerifiedThreat[contractAddress];
    }
    

    function getThreatStats(address contractAddress) external view returns (
        uint256 totalReports,
        uint256 verifiedReports,
        uint8 avgThreatLevel,
        uint256 totalUpvotes
    ) {
        totalReports = threats[contractAddress].length;
        if (totalReports == 0) return (0, 0, 0, 0);
        
        uint256 sumThreatLevel = 0;
        
        for (uint256 i = 0; i < totalReports; i++) {
            ThreatReport memory report = threats[contractAddress][i];
            
            if (report.verified) {
                verifiedReports++;
            }
            
            sumThreatLevel += report.threatLevel;
            totalUpvotes += report.upvotes;
        }
        
        avgThreatLevel = uint8(sumThreatLevel / totalReports);
        
        return (totalReports, verifiedReports, avgThreatLevel, totalUpvotes);
    }
    

    function updateVerifier(address newVerifier) external onlyOwner {
        require(newVerifier != address(0), "ThreatRegistry: Invalid verifier");
        verifier = newVerifier;
    }
    

    function removeReport(address contractAddress, uint256 reportIndex) external onlyOwner {
        require(reportIndex < threats[contractAddress].length, "ThreatRegistry: Invalid index");
        
        address reporter = threats[contractAddress][reportIndex].reporter;
        hasReported[contractAddress][reporter] = false;
        
        uint256 lastIndex = threats[contractAddress].length - 1;
        if (reportIndex != lastIndex) {
            threats[contractAddress][reportIndex] = threats[contractAddress][lastIndex];
        }
        threats[contractAddress].pop();
        
        bool hasVerifiedReports = false;
        for (uint256 i = 0; i < threats[contractAddress].length; i++) {
            if (threats[contractAddress][i].verified) {
                hasVerifiedReports = true;
                break;
            }
        }
        
        if (!hasVerifiedReports && isVerifiedThreat[contractAddress]) {
            isVerifiedThreat[contractAddress] = false;
            emit ThreatStatusChanged(contractAddress, false);
        }
    }
}