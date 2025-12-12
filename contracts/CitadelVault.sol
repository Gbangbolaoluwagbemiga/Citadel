// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CitadelVault {
    struct Vault {
        address owner;
        address beneficiary;
        uint64 unlockAt;
        uint256 target;
        uint256 balance;
        uint8 threshold;
        bool earlyEnabled;
    }

    uint256 public nextVaultId;
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => mapping(address => bool)) public isGuardian;
    mapping(uint256 => uint256) public approvalCount;
    mapping(uint256 => mapping(address => bool)) public hasApproved;

    bool private _locked;

    event VaultCreated(uint256 indexed id, address indexed owner, uint64 unlockAt, uint256 target, uint8 threshold);
    event Deposited(uint256 indexed id, address indexed from, uint256 amount, uint256 newBalance);
    event EarlyApproval(uint256 indexed id, address indexed guardian, uint256 approvals, bool enabled);
    event Withdrawn(uint256 indexed id, address indexed to, uint256 amount, uint256 remaining);
    event BeneficiarySet(uint256 indexed id, address indexed beneficiary);

    modifier nonReentrant() {
        require(!_locked, "REENTRANCY");
        _locked = true;
        _;
        _locked = false;
    }

    function createVault(
        uint64 unlockAt,
        uint256 target,
        address beneficiary,
        address[] calldata guardians,
        uint8 threshold
    ) external returns (uint256 id) {
        require(unlockAt > block.timestamp, "INVALID_UNLOCK");
        require(threshold > 0 && threshold <= guardians.length, "INVALID_THRESHOLD");
        id = ++nextVaultId;
        Vault storage v = vaults[id];
        v.owner = msg.sender;
        v.beneficiary = beneficiary;
        v.unlockAt = unlockAt;
        v.target = target;
        v.threshold = threshold;
        for (uint256 i = 0; i < guardians.length; i++) {
            address g = guardians[i];
            require(g != address(0), "ZERO_GUARDIAN");
            require(!isGuardian[id][g], "DUP_GUARDIAN");
            isGuardian[id][g] = true;
        }
        emit VaultCreated(id, msg.sender, unlockAt, target, threshold);
    }

    function setBeneficiary(uint256 id, address beneficiary) external {
        Vault storage v = vaults[id];
        require(msg.sender == v.owner, "NOT_OWNER");
        v.beneficiary = beneficiary;
        emit BeneficiarySet(id, beneficiary);
    }

    function deposit(uint256 id) external payable {
        Vault storage v = vaults[id];
        require(v.owner != address(0), "NO_VAULT");
        require(msg.value > 0, "NO_VALUE");
        v.balance += msg.value;
        emit Deposited(id, msg.sender, msg.value, v.balance);
    }

    function approveEarly(uint256 id) external {
        Vault storage v = vaults[id];
        require(v.owner != address(0), "NO_VAULT");
        require(isGuardian[id][msg.sender], "NOT_GUARDIAN");
        require(!hasApproved[id][msg.sender], "ALREADY_APPROVED");
        require(!v.earlyEnabled, "ALREADY_ENABLED");
        hasApproved[id][msg.sender] = true;
        approvalCount[id] += 1;
        if (approvalCount[id] >= v.threshold) {
            v.earlyEnabled = true;
        }
        emit EarlyApproval(id, msg.sender, approvalCount[id], v.earlyEnabled);
    }

    function withdrawOwner(uint256 id, uint256 amount) external nonReentrant {
        Vault storage v = vaults[id];
        require(msg.sender == v.owner, "NOT_OWNER");
        require(v.owner != address(0), "NO_VAULT");
        require(amount > 0 && amount <= v.balance, "BAD_AMOUNT");
        require(block.timestamp >= v.unlockAt || v.earlyEnabled, "LOCKED");
        v.balance -= amount;
        (bool ok, ) = v.owner.call{value: amount}("");
        require(ok, "TRANSFER_FAIL");
        emit Withdrawn(id, v.owner, amount, v.balance);
    }

    function withdrawToBeneficiary(uint256 id, uint256 amount) external nonReentrant {
        Vault storage v = vaults[id];
        require(msg.sender == v.owner, "NOT_OWNER");
        require(v.owner != address(0), "NO_VAULT");
        require(v.beneficiary != address(0), "NO_BENEFICIARY");
        require(amount > 0 && amount <= v.balance, "BAD_AMOUNT");
        require(block.timestamp >= v.unlockAt, "LOCKED");
        v.balance -= amount;
        (bool ok, ) = v.beneficiary.call{value: amount}("");
        require(ok, "TRANSFER_FAIL");
        emit Withdrawn(id, v.beneficiary, amount, v.balance);
    }

    function getVault(uint256 id) external view returns (
        address owner,
        address beneficiary,
        uint64 unlockAt,
        uint256 target,
        uint256 balance,
        uint8 threshold,
        uint256 approvals,
        bool earlyEnabled
    ) {
        Vault storage v = vaults[id];
        owner = v.owner;
        beneficiary = v.beneficiary;
        unlockAt = v.unlockAt;
        balance = v.balance;
        target = v.target;
        threshold = v.threshold;
        approvals = approvalCount[id];
        earlyEnabled = v.earlyEnabled;
    }
}

