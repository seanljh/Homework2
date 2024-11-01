// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract HouseNFT is ERC721URIStorage {
    uint private _tokenIdCounter;

    string[12] private tokenURIs = [
        "http://localhost:5173/BlueCabin.json",
        "http://localhost:5173/BrownCabin.json",
        "http://localhost:5173/ForestCabin.json",
        "http://localhost:5173/GreenCabin.json",
        "http://localhost:5173/LakesideCabin.json",
        "http://localhost:5173/ModernCabin.json",
        "http://localhost:5173/ModernWhiteCabin.json",
        "http://localhost:5173/OrangeCabin.json",
        "http://localhost:5173/PinkCabin.json",
        "http://localhost:5173/RedCabin.json",
        "http://localhost:5173/ValleyCabin.json",
        "http://localhost:5173/WideMansion.json"
    ];

    address[3] private users = [
        0xfAfcB0Bf514A8E65F0f00dE9eee590B784C97faC,
        0x189b69349cF715f310D80909cc4554d94184c3A2,
        0xaAAb02539B2FD7aC1103720e14E0a32BcB41654b
    ];

    mapping(uint => uint) public marketListings;
    mapping(uint => uint) public listingTimings;
    mapping(address => uint[]) public ownership;

    constructor() ERC721("HouseNFT", "HOUSE") {
        for (uint i = 0; i < tokenURIs.length; i++) {
            mintNFT(users[i%3], tokenURIs[i]);
            ownership[users[i%3]].push(i);
        }
    }

    function mintNFT(address recipient, string memory tokenURI) internal {
        uint tokenId = _tokenIdCounter;
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _tokenIdCounter += 1;
    }

    function getTotalMinted() public view returns (uint) {
        return _tokenIdCounter;
    }

    function getTokenDetails(uint tokenId) public view returns (address owner, string memory uri) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return (ownerOf(tokenId), tokenURI(tokenId));
    }

    function getOwnedTokens(address owner) public view returns (uint[] memory) {
        return ownership[owner];
    }

    function listToken(uint tokenId, uint price, uint time) public {
        marketListings[tokenId] = price;
        listingTimings[tokenId] = time;
    }

    function updateTokenPrice(uint tokenId, uint newPrice) public {
        marketListings[tokenId] = newPrice;
    }

    function unlistToken(uint tokenId) public {
        delete marketListings[tokenId];
        delete listingTimings[tokenId];
    }

    function buyToken(uint tokenId, uint comission) public payable {
        address prevOwner = _ownerOf(tokenId);
        address newOwner = msg.sender;
        _transfer(prevOwner, newOwner, tokenId);
        payable(prevOwner).transfer(msg.value - comission);
        payable(0xfAfcB0Bf514A8E65F0f00dE9eee590B784C97faC).transfer(comission);
        delete marketListings[tokenId];
        ownership[newOwner].push(tokenId);
        
        uint index;
        for (uint i = 0; i < ownership[prevOwner].length; i++) {
            if (ownership[prevOwner][i] == tokenId) {
                index = i;
            }
        }
        ownership[prevOwner][index] = ownership[prevOwner][ownership[prevOwner].length - 1];
        ownership[prevOwner].pop();
    }
}

