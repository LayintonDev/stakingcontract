import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0x809c4E72ac8e66226Fe23c5c4a2810B3821E28b2";

const StakeLayiModule = buildModule("StakeLayiModule", (m) => {

    const save = m.contract("StakeLayi", [tokenAddress]);

    return { save };
});

export default StakeLayiModule;