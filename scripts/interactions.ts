import {ethers} from "hardhat";

async function main() {
    const LayiTokenAddress = "0x809c4E72ac8e66226Fe23c5c4a2810B3821E28b2";
    const StakeLayiAddress = "0xb31e5e93B03af0A7255623Af2Bfe957c6CbA817F";
    const StakeEtherAddress = "0x5b76ED5C3EdA579e0cBfcEe507bBf05459a089E1";
    
    const LayiToken = await ethers.getContractAt("LayintonToken", LayiTokenAddress);
    const StakeLayi = await ethers.getContractAt("StakeLayi", StakeLayiAddress);
    const StakeEther = await ethers.getContractAt("StakeEther", StakeEtherAddress);
    

}

main().then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })