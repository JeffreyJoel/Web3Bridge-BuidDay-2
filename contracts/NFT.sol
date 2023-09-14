// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract JeffNFTContract is ERC721, Ownable, VRFConsumerBase {
    uint256 public mintPrice = 0.05 ether;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public isMintEnabled;

    mapping(address => uint256) public mintedWallets;

    struct Traits {
        uint8 energy; // 0 - 100
        uint8 speed; // 0 - 100
        uint8 strength; // 0 - 100
        uint8 intelligence; // 0 - 100
        uint8 charisma; // 0 - 100
        uint8 luck; // 0 - 100
    }
    mapping(uint256 => Traits) public tokenTraits;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    event Minted(uint256 tokenId, Traits traits);

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee)
        ERC721("JeffNFT", "JEFFNFT")
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        maxSupply = 3;
        isMintEnabled = true;
        keyHash = _keyHash;
        fee = _fee;
    }

    function toggleMintIsEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function requestRandomTraits() external returns (bytes32) {
        require(isMintEnabled, "Minting not enabled");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
        require(maxSupply > totalSupply, "Sold out");

        bytes32 requestId = requestRandomness(keyHash, fee);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        Traits memory traits;
        // Generate traits based on the received randomness
        traits.energy = uint8(randomness % 101);
        traits.speed = uint8((randomness >> 32) % 101);
        traits.strength = uint8((randomness >> 64) % 101);
        traits.intelligence = uint8((randomness >> 96) % 101);
        traits.charisma = uint8((randomness >> 128) % 101);
        traits.luck = uint8((randomness >> 160) % 101);

        uint256 tokenId = totalSupply + 1;
        mintedWallets[msg.sender]++;
        totalSupply++;

        _mint(msg.sender, tokenId);
        tokenTraits[tokenId] = traits;

        emit Minted(tokenId, traits);
    }

    function mint() external payable {
        require(msg.value == mintPrice, "Wrong value");
        require(mintedWallets[msg.sender] < 1, "Exceeded max per wallet");

        bytes32 requestId = requestRandomTraits();
    }

    function getTraits(uint256 tokenId) external view returns (Traits memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenTraits[tokenId];
    }
}
