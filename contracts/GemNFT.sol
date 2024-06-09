// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GemNFT is ERC721Enumerable, Ownable {
    uint256 private _tokenIdTracker;

    struct Gem {
        uint256 stakedTON;
        string color;
        string shape;
        string pattern;
        uint256 miningPower;
        uint256 forgingPower;
        uint256 rarity;
    }

    mapping(uint256 => Gem) public gems;
    mapping(uint256 => uint256) public gemCooldown;

    uint256 public miningCooldown = 1 days;
    uint256 public forgingCooldown = 3 days;

    bytes32 public merkleRoot;
    bool public airdropActive = false;

    event GemMined(address indexed user, uint256 indexed newGemId);
    event GemForged(address indexed user, uint256 indexed forgedGemId);

    constructor(bytes32 _merkleRoot) ERC721("GemNFT", "GEM") Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
    }

    // Internal function to mint new Gem NFTs
    function _mintGem(
        address to,
        uint256 stakedTON,
        string memory color,
        string memory shape,
        string memory pattern,
        uint256 miningPower,
        uint256 forgingPower,
        uint256 rarity
    ) internal {
        uint256 tokenId = _tokenIdTracker;
        _safeMint(to, tokenId);

        gems[tokenId] = Gem({
            stakedTON: stakedTON,
            color: color,
            shape: shape,
            pattern: pattern,
            miningPower: miningPower,
            forgingPower: forgingPower,
            rarity: rarity
        });

        _tokenIdTracker += 1;
    }

    // External function to mint new Gem NFTs
    function mintGem(
        address to,
        uint256 stakedTON,
        string memory color,
        string memory shape,
        string memory pattern,
        uint256 miningPower,
        uint256 forgingPower,
        uint256 rarity
    ) external onlyOwner {
        _mintGem(to, stakedTON, color, shape, pattern, miningPower, forgingPower, rarity);
    }

    // Function to mine new Gems
    function mineGem(uint256 gemId) external {
        require(ownerOf(gemId) == msg.sender, "Not the owner of the gem");
        require(block.timestamp >= gemCooldown[gemId], "Mining cooldown active");

        // Mining logic
        uint256 newGemId = _tokenIdTracker;
        _safeMint(msg.sender, newGemId);

        gems[newGemId] = _generateNewGem(gemId);
        gemCooldown[gemId] = block.timestamp + miningCooldown;

        emit GemMined(msg.sender, newGemId);

        _tokenIdTracker += 1;
    }

    // Function to forge new Gems by combining existing ones
    function forgeGems(uint256[] memory gemIds) external {
        require(gemIds.length >= 2 && gemIds.length <= 5, "Can only forge 2 to 5 gems");

        uint256 totalStakedTON = 0;
        uint256 combinedMiningPower = 0;
        uint256 combinedForgingPower = 0;
        uint256 maxRarity = 0;
        string memory combinedColor;
        string memory combinedShape;
        string memory combinedPattern;

        for (uint256 i = 0; i < gemIds.length; i++) {
            require(ownerOf(gemIds[i]) == msg.sender, "Not the owner of one of the gems");
            require(block.timestamp >= gemCooldown[gemIds[i]], "Forging cooldown active");

            totalStakedTON += gems[gemIds[i]].stakedTON;
            combinedMiningPower += gems[gemIds[i]].miningPower;
            combinedForgingPower += gems[gemIds[i]].forgingPower;
            maxRarity = gems[gemIds[i]].rarity > maxRarity ? gems[gemIds[i]].rarity : maxRarity;

            if (i == 0) {
                combinedColor = gems[gemIds[i]].color;
                combinedShape = gems[gemIds[i]].shape;
                combinedPattern = gems[gemIds[i]].pattern;
            } else {
                combinedColor = _combineColors(combinedColor, gems[gemIds[i]].color);
                combinedShape = _combineShapes(combinedShape, gems[gemIds[i]].shape);
                combinedPattern = _combinePatterns(combinedPattern, gems[gemIds[i]].pattern);
            }

            _burn(gemIds[i]);
            delete gems[gemIds[i]];
        }

        uint256 forgedGemId = _tokenIdTracker;
        _safeMint(msg.sender, forgedGemId);

        gems[forgedGemId] = Gem({
            stakedTON: totalStakedTON,
            color: combinedColor,
            shape: combinedShape,
            pattern: combinedPattern,
            miningPower: combinedMiningPower,
            forgingPower: combinedForgingPower,
            rarity: maxRarity
        });

        gemCooldown[forgedGemId] = block.timestamp + forgingCooldown;

        emit GemForged(msg.sender, forgedGemId);

        _tokenIdTracker += 1;
    }

    // Internal function to generate a new Gem based on an existing one
    function _generateNewGem(uint256 gemId) internal view returns (Gem memory) {
        Gem memory baseGem = gems[gemId];

        // Generate new gem logic based on the existing gem
        string memory newColor = _randomColor();
        string memory newShape = _randomShape();
        string memory newPattern = _randomPattern();
        uint256 newMiningPower = baseGem.miningPower / 2;
        uint256 newForgingPower = baseGem.forgingPower / 2;

        return Gem({
            stakedTON: baseGem.stakedTON / 2,
            color: newColor,
            shape: newShape,
            pattern: newPattern,
            miningPower: newMiningPower,
            forgingPower: newForgingPower,
            rarity: baseGem.rarity - 1
        });
    }

    //TO DO 
    function _combineColors(string memory color1, string memory color2) internal pure returns (string memory) {
        // Logic to combine colors (example: mixing two colors)
        return string(abi.encodePacked(color1, "-", color2));
    }
    
    //TO DO 
    function _combineShapes(string memory shape1, string memory shape2) internal pure returns (string memory) {
        // Logic to combine shapes (example: merging two shapes)
        return string(abi.encodePacked(shape1, "-", shape2));
    }
    
    //TO DO 
    function _combinePatterns(string memory pattern1, string memory pattern2) internal pure returns (string memory) {
        // Logic to combine patterns (example: blending two patterns)
        return string(abi.encodePacked(pattern1, "-", pattern2));
    }
  
    //TO DO 
    function _randomColor() internal view returns (string memory) {
        // Implement random color generation logic
        return "Blue";
    }
  
    //TO DO 
    function _randomShape() internal view returns (string memory) {
        // Implement random shape generation logic
        return "Round";
    }
  
    //TO DO 
    function _randomPattern() internal view returns (string memory) {
        // Implement random pattern generation logic
        return "Striped";
    }
  
    //TO DO 
    function airdropGems(address to, uint256 amount, bytes32[] calldata proof) external {
        require(airdropActive, "Airdrop is not active");
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Proof");

        for (uint256 i = 0; i < amount; i++) {
            _mintGem(to, 10, _randomColor(), _randomShape(), _randomPattern(), 5, 5, 1);
        }
    }
  
    //TO DO 
    function startAirdrop() external onlyOwner {
        airdropActive = true;
    }
  
    //TO DO 
    function stopAirdrop() external onlyOwner {
        airdropActive = false;
    }

    // Override required functions from parent contracts
//     function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
//         super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
//     }

//     function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
//         return super.supportsInterface(interfaceId);
//     }
 }