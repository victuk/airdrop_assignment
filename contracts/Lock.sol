// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {

    event claimed(address indexed _user, uint256 indexed _amount);

    address owner;
    address tokenAddress;
    bytes32 merkleRoot;
    uint256 totalAmountSpent;

    mapping(address => bool) claimedAirdropMap;

    constructor(address _tokenAddress, bytes32 _merkleRoot) {
        tokenAddress = _tokenAddress;
        merkleRoot = _merkleRoot;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function alreadyClaimedAirdrop() onlyOwner private view returns (bool) {
        require(_user != address(0), "Zero Address detected");
        return claimedAirdropMap[msg.sender];
    }

    function getContractBalance() onlyOwner public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function claimAirdrop(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        require(_user != address(0), "Zero Address detected");
        if (alreadyClaimedAirdrop()) {
            revert("You have already claimed this airdrop");
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid claim");

        claimedAirdropMap[msg.sender] = true;
        totalAmountSpent += _amount;

        IERC20(tokenAddress).transfer(msg.sender, _amount);

        emit claimed(msg.sender, _amount);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) onlyOwner external {
        merkleRoot = _merkleRoot;
    }

    function getMerkleProof() onlyOwner external view returns (bytes32) {
        require(_user != address(0), "Zero Address detected");
        return merkleRoot;
    }


    function withdrawLeftOverToken() onlyOwner external {

        uint256 contractBalance = getContractBalance();
        require(contractBalance > 0, "Less than zero");

        require(totalAmountSpent > contractBalance, "You have a lot of unacclaimed token");

        IERC20(tokenAddress).transfer(owner, contractBalance);
    }
}
