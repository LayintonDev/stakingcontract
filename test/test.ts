import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import { ethers } from "hardhat";

describe("StakContracts", function () {
    async function deployLayiToken() {
        const [owner, addr1] = await ethers.getSigners();
        const LayiToken = await ethers.getContractFactory("LayintonToken");
        const layiTokenAddres = await LayiToken.deploy();
        return {layiTokenAddres, owner, addr1};

    }
     async function deployLayiStake() {
        const [owner, addr1] = await ethers.getSigners();
        const {layiTokenAddres} = await loadFixture(deployLayiToken);
        const LayiStake = await ethers.getContractFactory("StakeLayi");
        const layiStake = await LayiStake.deploy(layiTokenAddres);
        return {layiStake, owner, addr1, layiTokenAddres};
    }
    describe("LayiTokenMint", function () {
        it("Should check if amount minted is correct", async function () {
            const {layiTokenAddres, owner} = await loadFixture(deployLayiToken);
            expect(await layiTokenAddres.totalSupply()).to.equal(ethers.parseUnits("500000", 18));
        });
        it("Should fail if not owner try to mint", async function () {
            const {layiTokenAddres, owner, addr1} = await loadFixture(deployLayiToken);
           await expect( layiTokenAddres.connect(addr1).mint(20000)).to.be.revertedWithCustomError(layiTokenAddres, "NotOwner");
        });
    })

    describe("LayiStake", function () {

        it("Should fail if not owner try to get contract balance", async function () {
            const {layiStake, owner, addr1} = await loadFixture(deployLayiStake);
            await expect( layiStake.connect(addr1).getContractBal()).to.be.revertedWithCustomError(layiStake, "NotOwner");
        });
         it("Should return zero if user check balance without staking", async function () {
            const {layiStake, owner, addr1} = await loadFixture(deployLayiStake);
             expect( await layiStake.getUserBal()).to.equal(0);
        });
          it("Should fail if user try to stake zero amount", async function () {
            const {layiStake, owner, addr1} = await loadFixture(deployLayiStake);
            await expect(  layiStake.stake(0)).to.be.revertedWithCustomError(layiStake, "ZeroValueNotAllowed");
        });
         it("Should fail if user try to stake with insufficeint token amount", async function () {
            const {layiStake, owner, addr1} = await loadFixture(deployLayiStake);
            await expect(layiStake.connect(addr1).stake(200)).to.be.revertedWithCustomError(layiStake, "InsufficientFunds");
        });
         it("Should stake successfully", async function () {
          
            const {layiStake, owner, addr1, layiTokenAddres} = await loadFixture(deployLayiStake);
         
            const approval = await layiTokenAddres.approve(layiStake, ethers.parseUnits("20000", 18));
            await approval.wait();
             await expect( layiStake.stake(ethers.parseUnits("2000", 18))).to.emit(layiStake, "StakeSuccessful").withArgs(owner, ethers.parseUnits("2000", 18));           
            expect( await layiStake.getUserBal()).to.equal(ethers.parseUnits("2000", 18));
            expect( await layiStake.getContractBal()).to.equal(ethers.parseUnits("2000", 18));
            
        });

        it("Should fail if user try to withdraw at time lesser than minimun staking duration ", async function () {
               const {layiStake, owner, addr1, layiTokenAddres} = await loadFixture(deployLayiStake);
         
            const approval = await layiTokenAddres.approve(layiStake, ethers.parseUnits("20000", 18));
            await approval.wait();
             await expect( layiStake.stake(ethers.parseUnits("2000", 18))).to.emit(layiStake, "StakeSuccessful").withArgs(owner, ethers.parseUnits("2000", 18));             
            await expect(layiStake.withdrawStake()).to.be.revertedWithCustomError(layiStake, "LIQUIDATIONTIMENOTREACHEDYET");
        });
    })
})