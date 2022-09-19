// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFTPresale is ERC721Enumerable, Ownable, Pausable {
  using Strings for uint256;

  uint256 private _normalCost = 0.5 ether;

  uint256 private _presaleCost = 0.25 ether;

  string public baseURI;

  string public baseExtension;

  uint256 public maximumNFTSupply = 100;

  uint256 public maximumNFTAllowedInPresale = 2;

  uint256 public presaleOpenTime;

  uint256 public presaleDuration;

  mapping(address => bool) public whitelistedAddresses;

  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _presaleDuration
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    presaleDuration = _presaleDuration;
  }

  // internal

  function setPresaleOpenTime(uint256 _presaleOpenTime) external onlyOwner {
    presaleOpenTime = _presaleOpenTime;
  }

  // public
  function mint(uint256 _mintAmount) external payable whenNotPaused {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maximumNFTSupply, "max NFT limit exceeded");
    require(block.timestamp >= presaleOpenTime, "too soon");
    if (block.timestamp <= presaleOpenTime + presaleDuration) {
      require(whitelistedAddresses[msg.sender], "user is not whitelisted");
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      require(
        ownerMintedCount + _mintAmount <= maximumNFTAllowedInPresale,
        "max NFT per address exceeded"
      );
      require(msg.value >= _presaleCost * _mintAmount, "insufficient funds");
    } else if (block.timestamp > presaleOpenTime + presaleDuration) {
      require(msg.value >= _normalCost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function setBaseExtension(string memory _newBaseExtension)
    external
    onlyOwner
  {
    baseExtension = _newBaseExtension;
  }

  function pause() external onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() external onlyOwner whenPaused {
    _unpause();
  }

  function getPrice() external view returns (uint256) {
    if (block.timestamp > presaleOpenTime + presaleDuration) {
      return _normalCost;
    } else {
      return _presaleCost;
    }
  }

  function whitelistUsers(address[] memory _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      if (_users[i] != address(0)) {
        whitelistedAddresses[_users[i]] = true;
      }
    }
  }

  function removeWhitelistUsers(address _users) external onlyOwner {
    whitelistedAddresses[_users] = false;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{ value: address(this).balance }(
      ""
    );
    require(success, "transfer not succesful");
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "nonExsitent token");
    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}
