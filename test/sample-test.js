const { expect } = require("chai");
const { ethers } = require("hardhat");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

let user1, user2, user3;

async function getSigners() {
  const accounts = await hre.ethers.getSigners();
  user1 = accounts[0];
  user2 = accounts[1];
  user3 = accounts[2];
}

async function Testing() {
  const NFT = await ethers.getContractFactory("NFTPresale");
  const nft = await NFT.deploy("NFTPresale", "NPS", "google.com", 8);
  await nft.deployed();

  describe("Testing NFT Presale Contract", function () {
    it("only owner should be able to set presale time", async function () {
      expect(await nft.owner()).to.equal(user1.address);

      await expect(
        nft.connect(user2).setPresaleOpenTime("10000")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("owner should be able to set presale time", async function () {
      expect(await nft.presaleOpenTime()).to.equal(0);

      let time = Math.floor(Date.now() / 1000);

      await nft.connect(user1).setPresaleOpenTime(time);

      expect(await nft.presaleOpenTime()).to.equal(time);
    });

    it("In presale time price should be less", async function () {
      expect(await nft.getPrice()).to.equal("250000000000000000");
    });

    it("Only whitelisted addresses can buy NFT", async function () {
      expect(await nft.whitelistedAddresses(user2.address)).to.equal(false);

      await expect(nft.connect(user2).mint(1)).to.be.revertedWith(
        "user is not whitelisted"
      );
    });

    it("whitelisted addresses can buy NFT", async function () {
      await nft.whitelistUsers([user2.address]);
      expect(await nft.whitelistedAddresses(user2.address)).to.equal(true);

      expect(await nft.balanceOf(user2.address)).to.equal(0);

      await nft.connect(user2).mint(1, { value: "250000000000000000" });

      expect(await nft.balanceOf(user2.address)).to.equal(1);
    });

    it("whitelisted addresses needs to provide sufficient ether", async function () {
      expect(await nft.balanceOf(user2.address)).to.equal(1);

      await expect(
        nft.connect(user2).mint(1, { value: "240000000000000000" })
      ).to.be.revertedWith("insufficient funds");
    });

    it("whitelisted addresses can not mint more than 2 nft in presale", async function () {
      expect(await nft.balanceOf(user2.address)).to.equal(1);

      await expect(
        nft.connect(user2).mint(2, { value: "500000000000000000" })
      ).to.be.revertedWith("max NFT per address exceeded");
    });

    it("user can not mint more than supply", async function () {
      expect(await nft.totalSupply()).to.equal(1);

      expect(await nft.maximumNFTSupply()).to.equal(100);

      await expect(
        nft.connect(user2).mint(100, { value: "25000000000000000000" })
      ).to.be.revertedWith("max NFT limit exceeded");

      await mine(10);
    });

    it("price should be different after preslae", async function () {
      expect(await nft.getPrice()).to.equal("500000000000000000");
    });

    it("after presale not whitelisted addresses can also buy", async function () {
      expect(await nft.whitelistedAddresses(user3.address)).to.equal(false);

      expect(await nft.balanceOf(user3.address)).to.equal("0");

      await nft.connect(user3).mint(3, { value: "1500000000000000000" });

      expect(await nft.balanceOf(user3.address)).to.equal("3");
    });
  });
}

describe("Setup & Test Contracts", async function () {
  it("Setting up the contracts & Testing", async function () {
    await getSigners();
    await Testing();
  }).timedOut("200000s");
});
