// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GuardianVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
        
    event ProtectionEnabled(address indexed wallet, uint256 timestamp);
    event ProtectionDisabled(address indexed wallet, uint256 timestamp);
    event TokensProtected(address indexed wallet, address indexed token, uint256 amount, uint8 threatLevel);
    event ThreatDetected(address indexed token, address indexed spender, uint8 threatLevel, string reason);
    event TokensWithdrawn(address indexed wallet, address indexed token, uint256 amount);
    event EmergencyWithdrawal(address indexed wallet, address indexed token, uint256 amount);
    event GuardianUpdated(address indexed oldGuardian, address indexed newGuardian);
    
    address public guardian;
    
    mapping(address => bool) public isProtected;
    mapping(address => uint256) public protectionStartTime;
    mapping(address => mapping(address => uint256)) public protectedBalances;
    mapping(address => uint256) public totalProtected;
    mapping(address => mapping(address => uint256)) public lastProtectionTime;
    
    uint256 public constant PROTECTION_COOLDOWN = 5 minutes;
    uint8 public constant THREAT_THRESHOLD = 75;
    uint256 public maxProtectionAmount;
    
    
    modifier onlyGuardian() {
        require(msg.sender == guardian, "GuardDog: Not authorized guardian");
        _;
    }
    
    modifier onlyProtected(address wallet) {
        require(isProtected[wallet], "GuardDog: Wallet not protected");
        _;
    }
    
    
    constructor(address _guardian) Ownable(msg.sender) {
        require(_guardian != address(0), "GuardDog: Invalid guardian");
        guardian = _guardian;
        maxProtectionAmount = type(uint256).max; 
    }
    

    function enableProtection() external {
        require(!isProtected[msg.sender], "GuardDog: Already protected");
        
        isProtected[msg.sender] = true;
        protectionStartTime[msg.sender] = block.timestamp;
        
        emit ProtectionEnabled(msg.sender, block.timestamp);
    }

    function disableProtection() external onlyProtected(msg.sender) {
        isProtected[msg.sender] = false;
        emit ProtectionDisabled(msg.sender, block.timestamp);
    }
    
    function protectTokens(
        address wallet,
        address token,
        uint256 amount,
        uint8 threatLevel,
        string calldata reason
    ) external onlyGuardian onlyProtected(wallet) nonReentrant {
        require(token != address(0), "GuardDog: Invalid token");
        require(amount > 0, "GuardDog: Zero amount");
        require(amount <= maxProtectionAmount, "GuardDog: Amount exceeds limit");
        require(threatLevel >= THREAT_THRESHOLD, "GuardDog: Threat level too low");
        
        require(
            block.timestamp >= lastProtectionTime[wallet][token] + PROTECTION_COOLDOWN,
            "GuardDog: Cooldown active"
        );
        
        lastProtectionTime[wallet][token] = block.timestamp;
        

        IERC20(token).safeTransferFrom(wallet, address(this), amount);
        
        protectedBalances[wallet][token] += amount;
        totalProtected[token] += amount;
        
        emit ThreatDetected(token, address(0), threatLevel, reason);
        emit TokensProtected(wallet, token, amount, threatLevel);
    }
    

    function batchProtectTokens(
        address wallet,
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint8[] calldata threatLevels,
        string[] calldata reasons
    ) external onlyGuardian onlyProtected(wallet) nonReentrant {
        require(
            tokens.length == amounts.length && 
            amounts.length == threatLevels.length &&
            threatLevels.length == reasons.length,
            "GuardDog: Array length mismatch"
        );
        
        for (uint256 i = 0; i < tokens.length; i++) {
            if (threatLevels[i] >= THREAT_THRESHOLD && amounts[i] > 0) {

                if (block.timestamp < lastProtectionTime[wallet][tokens[i]] + PROTECTION_COOLDOWN) {
                    continue;
                }
                
                lastProtectionTime[wallet][tokens[i]] = block.timestamp;
                
                IERC20(tokens[i]).safeTransferFrom(wallet, address(this), amounts[i]);
                
                protectedBalances[wallet][tokens[i]] += amounts[i];
                totalProtected[tokens[i]] += amounts[i];
                
                emit ThreatDetected(tokens[i], address(0), threatLevels[i], reasons[i]);
                emit TokensProtected(wallet, tokens[i], amounts[i], threatLevels[i]);
            }
        }
    }
    

    function withdraw(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "GuardDog: Zero amount");
        require(protectedBalances[msg.sender][token] >= amount, "GuardDog: Insufficient balance");
        
        protectedBalances[msg.sender][token] -= amount;
        totalProtected[token] -= amount;
        
        IERC20(token).safeTransfer(msg.sender, amount);
        
        emit TokensWithdrawn(msg.sender, token, amount);
    }
    

    function withdrawAll(address token) external nonReentrant {
        uint256 amount = protectedBalances[msg.sender][token];
        require(amount > 0, "GuardDog: No balance");
        
        protectedBalances[msg.sender][token] = 0;
        totalProtected[token] -= amount;
        
        IERC20(token).safeTransfer(msg.sender, amount);
        
        emit TokensWithdrawn(msg.sender, token, amount);
    }
    

    function emergencyWithdraw(address token) external nonReentrant {
        uint256 amount = protectedBalances[msg.sender][token];
        require(amount > 0, "GuardDog: No balance");
        
        protectedBalances[msg.sender][token] = 0;
        totalProtected[token] -= amount;
        
        IERC20(token).safeTransfer(msg.sender, amount);
        
        emit EmergencyWithdrawal(msg.sender, token, amount);
    }
    

    function isWalletProtected(address wallet) external view returns (bool) {
        return isProtected[wallet];
    }
    

    function getProtectionDuration(address wallet) external view returns (uint256) {
        if (!isProtected[wallet]) return 0;
        return block.timestamp - protectionStartTime[wallet];
    }
    

    function getProtectedBalance(address wallet, address token) external view returns (uint256) {
        return protectedBalances[wallet][token];
    }
    
    function getTotalProtected(address token) external view returns (uint256) {
        return totalProtected[token];
    }
    
    function getTimeUntilNextProtection(address wallet, address token) external view returns (uint256) {
        uint256 nextAllowed = lastProtectionTime[wallet][token] + PROTECTION_COOLDOWN;
        if (block.timestamp >= nextAllowed) return 0;
        return nextAllowed - block.timestamp;
    }
    
    function updateGuardian(address newGuardian) external onlyOwner {
        require(newGuardian != address(0), "GuardDog: Invalid guardian");
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit GuardianUpdated(oldGuardian, newGuardian);
    }
    
    function updateMaxProtectionAmount(uint256 newMax) external onlyOwner {
        maxProtectionAmount = newMax;
    }
    
    function pauseGuardian() external onlyOwner {
        guardian = address(0);
        emit GuardianUpdated(guardian, address(0));
    }
}
