// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Inscribe
/// @notice Inscribe text or image content on Robinhood Chain for a small ETH fee.
/// @dev Ownership is tracked on-chain. Supports transfers. Emits an ESIP-3-compatible
///      create event so the broader inscriptions ecosystem can observe creations.
contract Inscribe {
    error NotOwner();
    error InsufficientFee();
    error NotInscriptionOwner();
    error InvalidAddress();
    error ContentTooLong();
    error TransferToSelf();

    /// @notice ESIP-3 compatible creation event (ethscriptions protocol).
    event ethscriptions_protocol_CreateEthscription(address indexed creator, string contentURI);
    /// @notice Our own creation event (indexed).
    event InscriptionCreated(uint256 indexed id, address indexed creator, string contentURI);
    /// @notice Ownership transfer event.
    event InscriptionTransferred(uint256 indexed id, address indexed from, address indexed to);
    /// @notice Contract ownership handoff event.
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    address public owner;
    uint256 public fee;
    uint256 public totalInscriptions;
    uint256 public constant MAX_CONTENT_LENGTH = 65536; // 64 KB

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string) public contentOf;

    constructor(uint256 _fee) {
        owner = msg.sender;
        fee = _fee;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Set the inscription fee (owner only). Fee is in wei.
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /// @notice Hand contract ownership (fee setting, withdrawals) to a new address (owner only).
    function setOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        address previousOwner = owner;
        owner = newOwner;
        emit OwnerChanged(previousOwner, newOwner);
    }

    /// @notice Inscribe content. Pay at least the fee. The content URI is stored on-chain
    ///         and ownership is granted to the caller. The caller keeps the inscription.
    function inscribe(string calldata contentURI) external payable returns (uint256 id) {
        if (msg.value < fee) revert InsufficientFee();
        if (bytes(contentURI).length > MAX_CONTENT_LENGTH) revert ContentTooLong();
        id = totalInscriptions + 1;
        totalInscriptions = id;
        ownerOf[id] = msg.sender;
        balanceOf[msg.sender] += 1;
        contentOf[id] = contentURI;
        emit ethscriptions_protocol_CreateEthscription(msg.sender, contentURI);
        emit InscriptionCreated(id, msg.sender, contentURI);
    }

    /// @notice Transfer an inscription to another address. Only the current owner may call.
    function transfer(uint256 id, address to) external {
        if (to == address(0)) revert InvalidAddress();
        if (ownerOf[id] != msg.sender) revert NotInscriptionOwner();
        if (to == msg.sender) revert TransferToSelf();
        address from = msg.sender;
        ownerOf[id] = to;
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        emit InscriptionTransferred(id, from, to);
    }

    /// @notice Withdraw accumulated fees (owner only).
    function withdraw() external onlyOwner {
        (bool ok, ) = owner.call{value: address(this).balance}("");
        require(ok, "withdraw failed");
    }
}
