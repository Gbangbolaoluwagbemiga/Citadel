// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract CitadelVault {
    struct Vault {
        address owner;
        address beneficiary;
        uint64 unlockAt;
        uint256 target;
        uint256 balance;
        uint8 threshold;
        bool earlyEnabled;
        address token;
    }

    uint256 public nextVaultId;
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => mapping(address => bool)) public isGuardian;
    mapping(uint256 => address[]) public guardianList;
    mapping(uint256 => uint256) public approvalCount;
    mapping(uint256 => mapping(address => bool)) public hasApproved;

    bool private _locked;

    event VaultCreated(uint256 indexed id, address indexed owner, uint64 unlockAt, uint256 target, uint8 threshold);
    event Deposited(uint256 indexed id, address indexed from, uint256 amount, uint256 newBalance);
    event EarlyApproval(uint256 indexed id, address indexed guardian, uint256 approvals, bool enabled);
    event Withdrawn(uint256 indexed id, address indexed to, uint256 amount, uint256 remaining);
    event BeneficiarySet(uint256 indexed id, address indexed beneficiary);
    event GuardiansAdded(uint256 indexed id, address[] guardians);
    event GuardiansRemoved(uint256 indexed id, address[] guardians);
    event ThresholdUpdated(uint256 indexed id, uint8 threshold);

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
        uint8 threshold,
        address token
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
        v.token = token;
        for (uint256 i = 0; i < guardians.length; i++) {
            address g = guardians[i];
            require(g != address(0), "ZERO_GUARDIAN");
            require(!isGuardian[id][g], "DUP_GUARDIAN");
            isGuardian[id][g] = true;
            guardianList[id].push(g);
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
        require(v.token == address(0), "TOKEN_VAULT");
        require(msg.value > 0, "NO_VALUE");
        v.balance += msg.value;
        emit Deposited(id, msg.sender, msg.value, v.balance);
    }

    function depositToken(uint256 id, uint256 amount) external {
        Vault storage v = vaults[id];
        require(v.owner != address(0), "NO_VAULT");
        require(v.token != address(0), "NATIVE_VAULT");
        require(amount > 0, "NO_VALUE");
        require(IERC20(v.token).transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAIL");
        v.balance += amount;
        emit Deposited(id, msg.sender, amount, v.balance);
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
        if (v.token == address(0)) {
            (bool ok, ) = v.owner.call{value: amount}("");
            require(ok, "TRANSFER_FAIL");
        } else {
            require(IERC20(v.token).transfer(v.owner, amount), "TRANSFER_FAIL");
        }
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
        if (v.token == address(0)) {
            (bool ok, ) = v.beneficiary.call{value: amount}("");
            require(ok, "TRANSFER_FAIL");
        } else {
            require(IERC20(v.token).transfer(v.beneficiary, amount), "TRANSFER_FAIL");
        }
        emit Withdrawn(id, v.beneficiary, amount, v.balance);
    }

    function addGuardians(uint256 id, address[] calldata guardians) external {
        Vault storage v = vaults[id];
        require(msg.sender == v.owner, "NOT_OWNER");
        require(!v.earlyEnabled, "EARLY_ENABLED");
        for (uint256 i = 0; i < guardians.length; i++) {
            address g = guardians[i];
            require(g != address(0), "ZERO_GUARDIAN");
            require(!isGuardian[id][g], "DUP_GUARDIAN");
            isGuardian[id][g] = true;
            guardianList[id].push(g);
        }
        require(v.threshold <= guardianList[id].length && v.threshold > 0, "BAD_THRESHOLD");
        _resetApprovals(id);
        emit GuardiansAdded(id, guardians);
    }

    function removeGuardians(uint256 id, address[] calldata guardians) external {
        Vault storage v = vaults[id];
        require(msg.sender == v.owner, "NOT_OWNER");
        require(!v.earlyEnabled, "EARLY_ENABLED");
        for (uint256 i = 0; i < guardians.length; i++) {
            address g = guardians[i];
            require(isGuardian[id][g], "NOT_GUARDIAN");
            isGuardian[id][g] = false;
            _removeFromGuardianList(id, g);
            if (hasApproved[id][g]) {
                hasApproved[id][g] = false;
            }
        }
        require(v.threshold <= guardianList[id].length && v.threshold > 0, "BAD_THRESHOLD");
        approvalCount[id] = 0;
        v.earlyEnabled = false;
        emit GuardiansRemoved(id, guardians);
    }

    function setThreshold(uint256 id, uint8 threshold) external {
        Vault storage v = vaults[id];
        require(msg.sender == v.owner, "NOT_OWNER");
        require(!v.earlyEnabled, "EARLY_ENABLED");
        require(threshold > 0 && threshold <= guardianList[id].length, "INVALID_THRESHOLD");
        v.threshold = threshold;
        _resetApprovals(id);
        emit ThresholdUpdated(id, threshold);
    }

    function getGuardians(uint256 id) external view returns (address[] memory list) {
        list = guardianList[id];
    }

    function getVault(uint256 id) external view returns (
        address owner,
        address beneficiary,
        uint64 unlockAt,
        uint256 target,
        uint256 balance,
        uint8 threshold,
        uint256 approvals,
        bool earlyEnabled,
        address token
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
        token = v.token;
    }

    function _resetApprovals(uint256 id) internal {
        approvalCount[id] = 0;
        vaults[id].earlyEnabled = false;
        address[] storage list = guardianList[id];
        for (uint256 i = 0; i < list.length; i++) {
            address g = list[i];
            if (hasApproved[id][g]) hasApproved[id][g] = false;
        }
    }

    function _removeFromGuardianList(uint256 id, address g) internal {
        address[] storage list = guardianList[id];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == g) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }
}
